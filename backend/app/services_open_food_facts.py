"""
Open Food Facts async HTTP service — Feature 1.1 (Barcode Ingestion).

Responsibilities:
  - Accept a UPC string and query the public Open Food Facts REST API.
  - Parse the response, extracting product_name, brand, and default_shelf_life.
  - Raise structured HTTPExceptions for all known failure modes so the router
    can return deterministic HTTP status codes to the Flutter client.

SKILL.md Guardrails enforced:
  - ASYNC httpx.AsyncClient with timeout=10.0 (no blocking requests library).
  - All OFF response fields accessed via .get() with None defaults (never direct
    key access) — the OFF schema is sparse and field presence is not guaranteed.
  - User-Agent: FreezerPenguin/1.0 header sent per OFF API etiquette.
  - Module-level logger mandatory per SKILL.md §4.1.
"""

import logging
from dataclasses import dataclass
from typing import Optional

import httpx
from fastapi import HTTPException, status

logger = logging.getLogger(__name__)

_OFF_URL = "https://world.openfoodfacts.org/api/v0/product/{upc}.json"
_OFF_HEADERS = {"User-Agent": "FreezerPenguin/1.0"}
_OFF_TIMEOUT = 10.0


@dataclass
class OFFProduct:
    """
    Parsed product payload from a successful Open Food Facts API response.
    All fields except upc and product_name are Optional to reflect the reality
    that the OFF catalog is community-sourced and frequently incomplete.
    """
    upc: str
    product_name: str
    brand: Optional[str]
    default_shelf_life: Optional[int]


async def fetch_product_from_off(upc: str) -> OFFProduct:
    """
    Query Open Food Facts for a single product by UPC barcode string.

    Returns:
        OFFProduct — parsed product data on a confirmed match (status == 1).

    Raises:
        HTTPException 404 — product not found in the OFF catalog.
        HTTPException 503 — OFF API unreachable, timed out, or returned non-2xx.

    Observability contract (SKILL.md §4.1):
        INFO  — request dispatched, successful response with product data.
        WARNING — product_found=0 (404 path) or API error/timeout (503 path).
    """
    url = _OFF_URL.format(upc=upc)
    logger.info("Dispatching Open Food Facts request — UPC=%s", upc)

    try:
        async with httpx.AsyncClient(timeout=_OFF_TIMEOUT, headers=_OFF_HEADERS) as client:
            response = await client.get(url)
            response.raise_for_status()

    except httpx.TimeoutException:
        logger.warning(
            "OFF API request timed out after %.1fs — UPC=%s", _OFF_TIMEOUT, upc
        )
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Open Food Facts API unavailable. Please try again later.",
        )

    except httpx.HTTPStatusError as exc:
        logger.warning(
            "OFF API returned non-2xx HTTP status=%s — UPC=%s",
            exc.response.status_code,
            upc,
        )
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Open Food Facts API unavailable. Please try again later.",
        )

    except httpx.RequestError as exc:
        logger.warning(
            "OFF API network error — UPC=%s — %s: %s",
            upc,
            type(exc).__name__,
            exc,
        )
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Open Food Facts API unavailable. Please try again later.",
        )

    payload = response.json()
    off_status = payload.get("status", 0)

    if off_status != 1:
        logger.warning(
            "OFF API product_found=0 for UPC=%s — no DB write will occur", upc
        )
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Product not found in Open Food Facts for UPC: {upc}",
        )

    product = payload.get("product") or {}

    product_name: str = (
        product.get("product_name")
        or product.get("product_name_en")
        or product.get("abbreviated_product_name")
        or "Unknown Product"
    )

    brand: Optional[str] = product.get("brands") or None

    logger.info(
        "OFF API: product resolved — UPC=%s product_name=%r brand=%r",
        upc,
        product_name,
        brand,
    )

    return OFFProduct(
        upc=upc,
        product_name=product_name,
        brand=brand,
        default_shelf_life=None,
    )
