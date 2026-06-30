"""
Vision Ingestion router — Feature 1.2 (Gemini Leftover Ingestion).

Route:
    POST /api/v1/inventory/scan-leftover

Transaction sequence:
    1. MIME type validation — reject non-image uploads with HTTP 415 before
       reading any bytes (no external calls, no DB interaction).
    2. Payload size gate — reject files exceeding 10 MB with HTTP 413 before
       forwarding to Gemini.
    3. Gemini Vision call — analyze_leftover_image() handles the full pipeline:
       API dispatch → timeout guard → JSON parse → Pydantic validation.
       Raises HTTP 503 or 422 on failure; no DB state touched.
    4. Confidence gate — if confidence_score < 0.40, override product_name to
       "Unknown Food Item" (FR-8). The raw Gemini item_name is preserved in the
       audit log for accuracy analysis.
    5. Expiration date computation — date.today() + timedelta(days=estimated_shelf_life_days).
    6. Atomic dual-write — db.add(inventory_item) → db.flush() → db.add(audit_log)
       → db.commit(). A single commit guarantees atomicity: if either INSERT fails,
       db.rollback() reverses both. Zero partial state is ever committed.
    7. HTTP 201 Created — LeftoverScanResponse returned with item_id, audit_log_id,
       and all Gemini-derived fields.

SKILL.md Guardrails enforced:
    GR-1  — UPC explicitly set to None on the inventory_items row. This endpoint
             MUST NEVER populate the upc column. Raw leftovers have no barcode.
    GR-2  — item_id is the sole application-level PK. No composite key logic.
    §3.2  — status_code=HTTP_201_CREATED on the POST route.
    §3.3  — DB write block wrapped in try/except with db.rollback() on exception path.
    §4.1  — INFO/WARNING/ERROR log lines for every I/O event.
    §4.4  — ai_audit_logs row written in the same transaction as inventory_items INSERT.
"""

import logging
from datetime import date, datetime, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import DBAIAuditLog, DBInventoryItem
from app.schemas import LeftoverScanResponse
from app.services_gemini_vision import (
    GEMINI_SYSTEM_PROMPT,
    analyze_leftover_image,
    _LOW_CONFIDENCE_THRESHOLD,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/inventory", tags=["Inventory — Ingestion"])

_ACCEPTED_MIME_TYPES: frozenset[str] = frozenset({
    "image/jpeg",
    "image/png",
    "image/webp",
    "image/heic",
})
_MAX_PAYLOAD_BYTES: int = 10_485_760  # 10 MB hard ceiling (FR-3)
_UNKNOWN_PRODUCT_NAME: str = "Unknown Food Item"


@router.post(
    "/scan-leftover",
    response_model=LeftoverScanResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Scan a food container image via Gemini Vision and log to freezer inventory",
    responses={
        201: {"description": "Leftover item logged successfully — inventory row and audit record created"},
        413: {"description": "Image payload exceeds the 10 MB limit"},
        415: {"description": "Unsupported image MIME type"},
        422: {"description": "Gemini returned malformed JSON or a response that failed schema validation"},
        503: {"description": "Gemini Vision API timed out or is unavailable"},
        500: {"description": "Database write failed — both inventory and audit inserts rolled back"},
    },
)
async def scan_leftover(
    image: UploadFile = File(
        ...,
        description=(
            "Food container photograph. "
            "Accepted MIME types: image/jpeg, image/png, image/webp, image/heic. "
            "Maximum size: 10 MB."
        ),
    ),
    user_id: int = Query(..., description="FK to Users.user_id — the owning account"),
    location_id: int = Query(..., description="FK to storage_locations.location_id"),
    unit_id: int = Query(..., description="FK to Units.unit_id"),
    db: Session = Depends(get_db),
) -> LeftoverScanResponse:
    # ------------------------------------------------------------------
    # Step 1: MIME type validation (FR-2)
    # Executed before reading any file bytes — zero I/O cost on rejection.
    # ------------------------------------------------------------------
    content_type: Optional[str] = image.content_type
    if not content_type or content_type not in _ACCEPTED_MIME_TYPES:
        logger.warning(
            "Vision ingestion rejected — unsupported MIME type=%r user_id=%s",
            content_type,
            user_id,
        )
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail=(
                "Unsupported image type. "
                "Accepted: image/jpeg, image/png, image/webp, image/heic."
            ),
        )

    # ------------------------------------------------------------------
    # Step 2: Read image bytes and enforce 10 MB ceiling (FR-3)
    # ------------------------------------------------------------------
    image_bytes: bytes = await image.read()
    payload_size: int = len(image_bytes)

    logger.info(
        "Vision ingestion request received — user_id=%s location_id=%s unit_id=%s "
        "mime_type=%s payload_bytes=%s",
        user_id,
        location_id,
        unit_id,
        content_type,
        payload_size,
    )

    if payload_size > _MAX_PAYLOAD_BYTES:
        logger.warning(
            "Vision ingestion rejected — payload_bytes=%s exceeds 10 MB ceiling user_id=%s",
            payload_size,
            user_id,
        )
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=(
                "Image payload exceeds the 10 MB limit. "
                "Please resize the image client-side before submitting."
            ),
        )

    # ------------------------------------------------------------------
    # Step 3: Gemini Vision API call (FR-4, FR-5, FR-6, FR-7)
    # analyze_leftover_image raises HTTPException 503/422 on all failure
    # modes — no database state is touched before this point.
    # ------------------------------------------------------------------
    scan_result = await analyze_leftover_image(
        image_bytes=image_bytes,
        content_type=content_type,
    )
    gemini_result = scan_result.vision_result
    raw_response_text: str = scan_result.raw_response_text

    # ------------------------------------------------------------------
    # Step 4: Confidence gate — override product_name if below threshold (FR-8)
    # ------------------------------------------------------------------
    if (
        gemini_result.confidence_score is not None
        and gemini_result.confidence_score < _LOW_CONFIDENCE_THRESHOLD
    ):
        logger.warning(
            "Low Gemini confidence (%.2f) for image scan. "
            "Defaulting product_name to '%s'.",
            gemini_result.confidence_score,
            _UNKNOWN_PRODUCT_NAME,
        )
        final_product_name: str = _UNKNOWN_PRODUCT_NAME
    else:
        final_product_name = gemini_result.item_name

    # ------------------------------------------------------------------
    # Step 5: Compute expiration_date application-side (FR-9)
    # ------------------------------------------------------------------
    expiration_date: date = date.today() + timedelta(
        days=gemini_result.estimated_shelf_life_days
    )
    scanned_at: datetime = datetime.now(tz=timezone.utc)

    logger.info(
        "Computed expiration_date=%s from estimated_shelf_life_days=%s",
        expiration_date,
        gemini_result.estimated_shelf_life_days,
    )

    # ------------------------------------------------------------------
    # Step 6: Atomic dual-write — inventory_items + ai_audit_logs (FR-9, FR-10)
    #
    # Transaction sequence:
    #   a) db.add(new_item)           — stage the inventory row
    #   b) db.flush()                 — flush to DB to obtain item_id PK
    #                                   (no commit yet; still within transaction)
    #   c) db.add(new_audit_log)      — stage the audit row
    #   d) db.commit()                — single commit — both rows land atomically
    #
    # GR-1: UPC is explicitly set to None. This is not an omission — it is a
    # deliberate architectural guarantee that leftover image-scanned items
    # NEVER carry a barcode reference.
    # ------------------------------------------------------------------
    new_item = DBInventoryItem(
        user_id=user_id,
        quantity=1,
        expiration_date=expiration_date,
        UPC=None,           # GR-1: hardcoded NULL — image_scan items have no barcode
        location_id=location_id,
        unit_id=unit_id,
    )

    try:
        db.add(new_item)
        db.flush()  # Assigns item_id without committing; keeps both rows in same transaction

        logger.info(
            "inventory_items row staged (pending commit) — item_id=%s UPC=None user_id=%s",
            new_item.item_id,
            user_id,
        )

        new_audit_log = DBAIAuditLog(
            input_prompt=GEMINI_SYSTEM_PROMPT,
            raw_output=raw_response_text,
            accuracy_coefficient=gemini_result.confidence_score,
        )

        db.add(new_audit_log)
        db.commit()
        db.refresh(new_item)
        db.refresh(new_audit_log)

        logger.info(
            "inventory_items INSERT committed — item_id=%s source_type='image_scan' "
            "product_name=%r expiration_date=%s",
            new_item.item_id,
            final_product_name,
            expiration_date,
        )
        logger.info(
            "ai_audit_logs INSERT committed — log_id=%s item_id=%s confidence=%s",
            new_audit_log.log_id,
            new_item.item_id,
            gemini_result.confidence_score,
        )

    except Exception as exc:
        db.rollback()
        logger.error(
            "Atomic DB write failed during vision ingestion for user_id=%s — "
            "both inventory_items and ai_audit_logs rolled back. raw error: %s",
            user_id,
            str(exc),
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=(
                "Database write failed during vision ingestion. "
                "Both inventory and audit inserts were rolled back."
            ),
        )

    # ------------------------------------------------------------------
    # Step 7: Return HTTP 201 with full LeftoverScanResponse
    # ------------------------------------------------------------------
    return LeftoverScanResponse(
        item_id=new_item.item_id,
        product_name=final_product_name,
        upc=None,                                          # GR-1: always null
        estimated_shelf_life_days=gemini_result.estimated_shelf_life_days,
        expiration_date=expiration_date,
        source_type="image_scan",
        confidence_score=gemini_result.confidence_score,
        notes=gemini_result.notes,
        audit_log_id=new_audit_log.log_id,
        scanned_at=scanned_at,
    )
