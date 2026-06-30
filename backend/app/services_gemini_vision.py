"""
Gemini Vision service — Feature 1.2 (Leftover Ingestion).

SDK: google-genai (modern unified Google Gen AI Python SDK).
     Replaces deprecated google-generativeai package that caused v1beta
     404 model routing errors.

Responsibilities:
  - Hold the GEMINI_SYSTEM_PROMPT string constant that is sent with every
    vision inference call. This constant is also written verbatim to
    ai_audit_logs.input_prompt for every request so prompt version history
    is implicitly tracked.
  - Expose the module-level _client (genai.Client) and _GENERATION_CONFIG.
    The client reads GEMINI_API_KEY from the environment automatically.
    No external configure() call is required — key injection is self-contained.
  - Expose analyze_leftover_image() — the single async entry point for all
    Gemini image inference. It handles the full pipeline: image part
    construction → asyncio.wait_for timeout guard → JSON parsing → Pydantic
    v2 validation → confidence logging → structured result return.

SKILL.md Guardrails enforced:
  §3.4  — All outbound API calls use async client (client.aio.models.generate_content).
           No blocking SDK calls inside async route handlers.
  §4.1  — INFO/WARNING/ERROR log lines emitted for every I/O outcome.
  FR-5  — asyncio.wait_for timeout=15.0s; TimeoutError → HTTP 503.
  FR-6  — json.JSONDecodeError → HTTP 422 with truncated raw response.
  FR-7  — Pydantic ValidationError → HTTP 422.
  FR-8  — confidence_score < 0.40 → WARNING log; product_name override
           applied in the router after this function returns.
"""

import asyncio
import json
import logging
from dataclasses import dataclass
from typing import Optional

from google import genai
from google.genai import types
from fastapi import HTTPException, status
from pydantic import ValidationError

from app.schemas import GeminiVisionResult

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Gemini model configuration constants
# ---------------------------------------------------------------------------

_GEMINI_MODEL_NAME = "gemini-1.5-flash"
_GEMINI_TIMEOUT_SECONDS = 15.0
_LOW_CONFIDENCE_THRESHOLD = 0.40

# System prompt sent with every inference call and stored verbatim in
# ai_audit_logs.input_prompt. Modifying this string constitutes a prompt
# version change and should be documented in the commit message.
GEMINI_SYSTEM_PROMPT: str = (
    "You are a food identification assistant integrated into a home freezer inventory "
    "management system called Freezer Penguin. Analyze the provided image of a food "
    "storage container and identify the food contents with as much specificity as possible.\n\n"
    "You MUST return ONLY a valid JSON object — no markdown code fences, no preamble text, "
    "no trailing explanations. The response must be parseable by json.loads() with no preprocessing.\n\n"
    "The JSON MUST conform to this exact schema:\n"
    "{\n"
    '  "item_name": "<string: most specific food name, e.g. \'Chicken Tikka Masala\', max 255 chars>",\n'
    '  "estimated_shelf_life_days": <integer: safe freezer storage in days from today, range 1-3650>,\n'
    '  "quantity_description": "<string or null: volume/weight estimate, e.g. \'2 cups\', \'500g\', \'1 portion\'>",\n'
    '  "confidence_score": <float: your identification confidence, range 0.00-1.00>,\n'
    '  "notes": "<string or null: observations about container or food state, max 500 chars>"\n'
    "}\n\n"
    "Safety rule: If confidence_score < 0.40, still return the full valid JSON object "
    "but set item_name to \"Unknown Food Item\"."
)

# Module-level client and generation config — created once at import time.
# genai.Client() reads GEMINI_API_KEY from the environment automatically and
# targets the v1beta gateway, which fully supports response_mime_type in
# GenerateContentConfig. No http_options override is required.
_client: genai.Client = genai.Client()

_GENERATION_CONFIG = types.GenerateContentConfig(
    temperature=0.1,                       # Deterministic structured output
    max_output_tokens=512,                 # Sufficient for the JSON schema; prevents runaway responses
    response_mime_type="application/json", # JSON mode: bypasses markdown fence stripping
)


# ---------------------------------------------------------------------------
# Service return type — carries both the validated result and raw response
# text so the router can write the audit log without re-parsing
# ---------------------------------------------------------------------------

@dataclass
class GeminiScanResult:
    """
    Internal return type from analyze_leftover_image().

    vision_result    — Pydantic-validated GeminiVisionResult; safe for DB write.
    raw_response_text — Verbatim model output, truncated to 2000 chars, written
                        to ai_audit_logs.raw_output for audit traceability.
    """
    vision_result: GeminiVisionResult
    raw_response_text: str


# ---------------------------------------------------------------------------
# Core async inference function
# ---------------------------------------------------------------------------

async def analyze_leftover_image(
    image_bytes: bytes,
    content_type: str,
) -> GeminiScanResult:
    """
    Submit a food container image to Gemini Vision and return a validated result.

    Args:
        image_bytes:  Raw image bytes read from the UploadFile.
        content_type: MIME type string, e.g. "image/jpeg". Passed as-is to the
                      inline image data part — must be validated by the caller
                      before this function is invoked.

    Returns:
        GeminiScanResult containing the validated GeminiVisionResult and the
        raw response text for audit logging.

    Raises:
        HTTPException 503 — Gemini API timed out (asyncio.TimeoutError) or
                            raised a GoogleAPIError / any SDK-level exception.
        HTTPException 422 — Gemini returned unparseable JSON (JSONDecodeError).
        HTTPException 422 — Gemini JSON failed GeminiVisionResult Pydantic
                            validation (ValidationError).

    Observability (SKILL.md §4.1):
        INFO    — model dispatched with payload_bytes count.
        INFO    — scan success with item name, confidence, and payload size.
        WARNING — confidence below threshold (logged here; override applied by router).
        WARNING — JSON parsing failure with truncated raw response.
        ERROR   — API timeout or SDK exception with exception class name.
    """
    # Construct inline image part using the modern SDK factory method.
    # types.Part.from_bytes() replaces the legacy dict {"mime_type": ..., "data": ...}
    # format used by google-generativeai.
    image_part: types.Part = types.Part.from_bytes(
        data=image_bytes,
        mime_type=content_type,
    )

    logger.info(
        "Dispatching Gemini Vision request — model=%s payload_bytes=%s mime_type=%s",
        _GEMINI_MODEL_NAME,
        len(image_bytes),
        content_type,
    )

    # ------------------------------------------------------------------
    # Step 1: Async Gemini API call with hard timeout guard (FR-5)
    # ------------------------------------------------------------------
    try:
        response = await asyncio.wait_for(
            _client.aio.models.generate_content(
                model=_GEMINI_MODEL_NAME,
                contents=[GEMINI_SYSTEM_PROMPT, image_part],
                config=_GENERATION_CONFIG,
            ),
            timeout=_GEMINI_TIMEOUT_SECONDS,
        )
    except asyncio.TimeoutError:
        logger.error(
            "Gemini Vision API timed out after %.1fs — payload_bytes=%s",
            _GEMINI_TIMEOUT_SECONDS,
            len(image_bytes),
        )
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Gemini Vision API timed out. Please retry.",
        )
    except Exception as exc:
        # Catches google.genai errors (APIError, PermissionDeniedError, etc.)
        # and any other SDK-level failure (auth errors, quota exceeded, network errors).
        logger.error(
            "Gemini Vision API error — %s: %s",
            type(exc).__name__,
            str(exc)[:300],
        )
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Gemini Vision API unavailable. Please retry.",
        )

    raw_text: str = response.text
    logger.info(
        "Gemini API response received — model=%s response_length=%s",
        _GEMINI_MODEL_NAME,
        len(raw_text),
    )

    # ------------------------------------------------------------------
    # Step 2: JSON parsing (FR-6)
    # ------------------------------------------------------------------
    try:
        parsed_dict = json.loads(raw_text)
    except json.JSONDecodeError:
        logger.warning(
            "Gemini returned malformed JSON — raw_response (truncated): %r",
            raw_text[:300],
        )
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=(
                f"Gemini returned malformed JSON. "
                f"Raw response (truncated): {raw_text[:300]}"
            ),
        )

    # ------------------------------------------------------------------
    # Step 3: Pydantic v2 schema validation (FR-7)
    # ------------------------------------------------------------------
    try:
        gemini_result = GeminiVisionResult.model_validate(parsed_dict)
    except ValidationError as exc:
        logger.warning(
            "Gemini response failed Pydantic validation — errors=%s parsed_dict=%s",
            exc.error_count(),
            str(parsed_dict)[:300],
        )
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=(
                "Gemini response did not conform to the required schema. "
                "Check ai_audit_logs for the raw response."
            ),
        )

    # ------------------------------------------------------------------
    # Step 4: Confidence score observation log (FR-8)
    # The product_name override to "Unknown Food Item" is applied by the
    # router after this function returns, so it appears in the DB write
    # and in the LeftoverScanResponse. The raw gemini_result.item_name
    # is preserved here for accurate audit logging.
    # ------------------------------------------------------------------
    logger.info(
        "Gemini scan success: item='%s', confidence=%s, payload_bytes=%s",
        gemini_result.item_name,
        gemini_result.confidence_score,
        len(image_bytes),
    )

    if (
        gemini_result.confidence_score is not None
        and gemini_result.confidence_score < _LOW_CONFIDENCE_THRESHOLD
    ):
        logger.warning(
            "Low Gemini confidence (%.2f) for image scan. "
            "Router will default product_name to 'Unknown Food Item'.",
            gemini_result.confidence_score,
        )

    return GeminiScanResult(
        vision_result=gemini_result,
        raw_response_text=raw_text[:2000],  # Truncate for ai_audit_logs.raw_output column
    )
