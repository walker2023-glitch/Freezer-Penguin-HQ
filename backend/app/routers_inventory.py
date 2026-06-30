"""
Inventory router — Feature 1.1 (Barcode Ingestion).

Route:
    POST /api/v1/inventory/barcode/{upc}

Transaction sequence:
    1. Cache check — query barcode_master for the UPC.
    2. Cache miss — call Open Food Facts via the async httpx service; on success,
       INSERT the product record into barcode_master.
    3. Upsert — check inventory_items for an existing row with the same
       (user_id, UPC, location_id). If found, INCREMENT quantity. If not found,
       INSERT a new inventory row.
    4. Return HTTP 201 with a BarcodeIngestionResponse.

SKILL.md Guardrails enforced:
    GR-1  — UPC stays Optional/nullable throughout.
    GR-2  — item_id is the sole application-level PK; no composite key logic.
    §3.2  — Explicit status_code=HTTP_201_CREATED on the POST route.
    §3.3  — Every DB write block wrapped in try/except with db.rollback() on
             the exception path before re-raising as HTTPException.
    §4.1  — INFO/WARNING/ERROR log lines emitted for every I/O event.
"""

import logging
from datetime import date, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import DBBarcodeMaster, DBCategory, DBInventoryItem
from app.schemas import BarcodeIngestionResponse
from app.services_open_food_facts import fetch_product_from_off

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/inventory", tags=["Inventory"])

_DEFAULT_SHELF_LIFE_DAYS = 365
_DEFAULT_CATEGORY_ID = 8  # "General" — catch-all per seeded categories table


@router.post(
    "/barcode/{upc}",
    response_model=BarcodeIngestionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Scan a UPC barcode, resolve product via Open Food Facts, and log to inventory",
    responses={
        201: {"description": "Item created or quantity incremented successfully"},
        404: {"description": "UPC not found in Open Food Facts catalog"},
        503: {"description": "Open Food Facts API is unreachable or returned a non-2xx response"},
        500: {"description": "Database write failed — transaction rolled back"},
    },
)
async def ingest_barcode_item(
    upc: str,
    user_id: int = Query(..., description="FK to Users.user_id — the owning account"),
    location_id: int = Query(..., description="FK to storage_locations.location_id"),
    unit_id: int = Query(..., description="FK to Units.unit_id"),
    expiration_date: Optional[date] = Query(
        None,
        description=(
            "Optional expiration date (ISO-8601). If omitted, computed from "
            "barcode_master.default_shelf_life or defaulted to 365 days from today."
        ),
    ),
    db: Session = Depends(get_db),
) -> BarcodeIngestionResponse:
    logger.info(
        "Barcode ingestion request received — UPC=%s user_id=%s location_id=%s unit_id=%s",
        upc,
        user_id,
        location_id,
        unit_id,
    )

    # ------------------------------------------------------------------
    # Step 1: Cache check — query barcode_master for the UPC
    # ------------------------------------------------------------------
    cached_product = (
        db.query(DBBarcodeMaster).filter(DBBarcodeMaster.UPC == upc).first()
    )

    if cached_product:
        logger.info(
            "Cache HIT on barcode_master — UPC=%s product_name=%r — skipping OFF API call",
            upc,
            cached_product.product_name,
        )
        product_name: str = cached_product.product_name
        brand: Optional[str] = cached_product.brand
        shelf_life: Optional[int] = cached_product.default_shelf_life

    else:
        # ------------------------------------------------------------------
        # Step 2: Cache miss — query Open Food Facts
        # Raises HTTPException 404 or 503 on failure; no DB state is written.
        # ------------------------------------------------------------------
        logger.info(
            "Cache MISS on barcode_master — UPC=%s — querying Open Food Facts", upc
        )
        off_product = await fetch_product_from_off(upc)

        # ------------------------------------------------------------------
        # Step 3: Persist the new product record to barcode_master
        #
        # Patch A — String truncation:
        #   barcode_master.product_name is VARCHAR(100) and brand is VARCHAR(100)
        #   in the live DDL. OFF payloads are community-sourced and routinely
        #   exceed these limits. Hard-truncate before the INSERT to prevent
        #   "Data too long for column" OperationalError rejections.
        #
        # Patch B — Category FK fallback:
        #   OFF API categories are free-text strings that do not map to our
        #   taxonomy. Always target _DEFAULT_CATEGORY_ID (8 / "General"), but
        #   verify it exists in the categories table first. If it is somehow
        #   absent (e.g. a truncated seed), fall back to the lowest available
        #   category_id to guarantee the FK constraint is satisfied.
        # ------------------------------------------------------------------

        # Patch A — truncate to column width limits before any assignment
        safe_product_name: str = (off_product.product_name or "Unknown Product")[:100]
        safe_brand: Optional[str] = off_product.brand[:100] if off_product.brand else None

        # Patch B — live FK validation against the categories table
        resolved_category_id: int = _DEFAULT_CATEGORY_ID
        category_row = (
            db.query(DBCategory)
            .filter(DBCategory.category_id == _DEFAULT_CATEGORY_ID)
            .first()
        )
        if category_row:
            logger.info(
                "Category FK confirmed — category_id=%s (%r) is valid for UPC=%s",
                resolved_category_id,
                category_row.category_name,
                upc,
            )
        else:
            logger.warning(
                "Category FK fallback: category_id=%s not found in categories table — "
                "querying for first available category for UPC=%s",
                resolved_category_id,
                upc,
            )
            first_available = (
                db.query(DBCategory).order_by(DBCategory.category_id).first()
            )
            if first_available:
                resolved_category_id = first_available.category_id
                logger.warning(
                    "Category FK resolved to category_id=%s (%r) for UPC=%s",
                    resolved_category_id,
                    first_available.category_name,
                    upc,
                )
            else:
                logger.error(
                    "Categories table is empty — cannot satisfy FK constraint for UPC=%s",
                    upc,
                )
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Categories reference table is empty. Cannot insert barcode_master row.",
                )

        new_catalog_entry = DBBarcodeMaster(
            UPC=upc,
            product_name=safe_product_name,
            brand=safe_brand,
            default_shelf_life=off_product.default_shelf_life,
            category_id=resolved_category_id,
        )
        try:
            db.add(new_catalog_entry)
            db.commit()
            db.refresh(new_catalog_entry)
            logger.info(
                "barcode_master INSERT committed — UPC=%s product_name=%r category_id=%s",
                upc,
                new_catalog_entry.product_name,
                resolved_category_id,
            )
        except Exception as exc:
            db.rollback()
            # Patch C — emit the raw DB error string to Uvicorn stdout before
            # raising so the exact constraint violation is traceable in logs.
            logger.error(
                "DB write failed during barcode_master INSERT for UPC=%s — "
                "raw error: %s",
                upc,
                str(exc),
            )
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to persist product catalog entry. Transaction rolled back.",
            )

        product_name = safe_product_name
        brand = safe_brand
        shelf_life = new_catalog_entry.default_shelf_life

    # ------------------------------------------------------------------
    # Resolve expiration_date if caller did not supply one
    # ------------------------------------------------------------------
    if expiration_date is None:
        shelf_days = shelf_life if shelf_life else _DEFAULT_SHELF_LIFE_DAYS
        expiration_date = date.today() + timedelta(days=shelf_days)
        logger.info(
            "expiration_date not supplied — computed %s using shelf_life=%s days",
            expiration_date,
            shelf_days,
        )

    # ------------------------------------------------------------------
    # Step 4: Upsert inventory_items
    # Match key: (user_id, UPC, location_id) — captures the same item at
    # the same location for the same user; increment quantity instead of
    # creating a duplicate row.
    # ------------------------------------------------------------------
    existing_item: Optional[DBInventoryItem] = (
        db.query(DBInventoryItem)
        .filter(
            DBInventoryItem.user_id == user_id,
            DBInventoryItem.UPC == upc,
            DBInventoryItem.location_id == location_id,
        )
        .first()
    )

    if existing_item:
        logger.info(
            "Existing inventory row found — item_id=%s current_quantity=%s — incrementing",
            existing_item.item_id,
            existing_item.quantity,
        )
        try:
            existing_item.quantity = (existing_item.quantity or 0) + 1
            db.commit()
            db.refresh(existing_item)
            logger.info(
                "inventory_items UPSERT (quantity increment) committed — "
                "item_id=%s new_quantity=%s",
                existing_item.item_id,
                existing_item.quantity,
            )
        except Exception as exc:
            db.rollback()
            logger.error(
                "DB write failed during inventory quantity upsert — item_id=%s: %s",
                existing_item.item_id,
                exc,
            )
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update inventory item quantity. Transaction rolled back.",
            )

        return BarcodeIngestionResponse(
            item_id=existing_item.item_id,
            upc=existing_item.UPC,
            product_name=product_name,
            brand=brand,
            quantity=existing_item.quantity,
            location_id=existing_item.location_id,
            unit_id=existing_item.unit_id,
            user_id=existing_item.user_id,
            expiration_date=existing_item.expiration_date,
            upserted=True,
        )

    # ------------------------------------------------------------------
    # New item path — first scan of this UPC at this location for this user
    # ------------------------------------------------------------------
    new_item = DBInventoryItem(
        user_id=user_id,
        quantity=1,
        expiration_date=expiration_date,
        UPC=upc,
        location_id=location_id,
        unit_id=unit_id,
    )
    try:
        db.add(new_item)
        db.commit()
        db.refresh(new_item)
        logger.info(
            "inventory_items INSERT committed — item_id=%s UPC=%s user_id=%s location_id=%s",
            new_item.item_id,
            upc,
            user_id,
            location_id,
        )
    except Exception as exc:
        db.rollback()
        logger.error(
            "DB write failed during inventory_items INSERT for UPC=%s: %s", upc, exc
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create inventory item. Transaction rolled back.",
        )

    return BarcodeIngestionResponse(
        item_id=new_item.item_id,
        upc=new_item.UPC,
        product_name=product_name,
        brand=brand,
        quantity=new_item.quantity,
        location_id=new_item.location_id,
        unit_id=new_item.unit_id,
        user_id=new_item.user_id,
        expiration_date=new_item.expiration_date,
        upserted=False,
    )
