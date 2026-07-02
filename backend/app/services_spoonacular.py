"""
Spoonacular Recipe API service — Feature 1.3 (Recipe Suggestions Engine).

Responsibilities:
  - Query inventory_items (LEFT JOIN barcode_master) for a user's expiring,
    unconsumed items within a configurable day window.
  - Build a Spoonacular-compatible ingredient string (200-char cap, urgency-sorted,
    no trailing comma, no partial ingredient names).
  - Execute async GET /recipes/findByIngredients via httpx with an 8.0s timeout.
  - Raise structured HTTPExceptions for all known failure modes.

SKILL.md Guardrails enforced:
  - ASYNC httpx.AsyncClient with timeout=8.0 (no blocking I/O).
  - SPOONACULAR_API_KEY read at call time from os.getenv() — never hardcoded.
  - All DB queries use .get() / .isnot() patterns; nullable columns handled safely.
  - Module-level logger mandatory per SKILL.md §4.1.
"""

import logging
import os
from datetime import date, timedelta
from typing import Optional

import httpx
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models import DBBarcodeMaster, DBInventoryItem
from app.schemas_recipes import ExpiringItemSummary

logger = logging.getLogger(__name__)

_SPOONACULAR_BASE_URL = "https://api.spoonacular.com/recipes/findByIngredients"
_SPOONACULAR_TIMEOUT = 8.0
_INGREDIENT_STRING_MAX_CHARS = 200


def get_expiring_items(
    user_id: int,
    days_window: int,
    db: Session,
) -> list[tuple]:
    """
    Query inventory_items LEFT JOINed with barcode_master for items belonging
    to user_id that expire within days_window days and are not consumed.

    is_consumed.isnot(True) matches both explicit False rows and NULL rows
    (items created before the is_consumed column was added). This is the
    conservative safe default — never exclude an item due to a NULL flag.

    Returns:
        list[tuple[DBInventoryItem, DBBarcodeMaster | None]] — sorted by
        expiration_date ASC so ingredient string preserves urgency order.
    """
    cutoff: date = date.today() + timedelta(days=days_window)
    return (
        db.query(DBInventoryItem, DBBarcodeMaster)
        .outerjoin(DBBarcodeMaster, DBInventoryItem.UPC == DBBarcodeMaster.UPC)
        .filter(
            DBInventoryItem.user_id == user_id,
            DBInventoryItem.expiration_date <= cutoff,
            DBInventoryItem.expiration_date >= date.today(),
            DBInventoryItem.is_consumed.isnot(True),
        )
        .order_by(DBInventoryItem.expiration_date.asc())
        .all()
    )


def build_expiring_summaries(rows: list[tuple]) -> list[ExpiringItemSummary]:
    """
    Convert raw ORM row tuples into ExpiringItemSummary objects.

    Rows where the barcode_master JOIN returned None (vision-scanned leftovers
    with UPC=None) still produce a summary with product_name=None so the
    caller can include them in items_expiring even if they are excluded from
    the Spoonacular ingredient string.
    """
    today: date = date.today()
    summaries: list[ExpiringItemSummary] = []
    for item, catalog in rows:
        summaries.append(
            ExpiringItemSummary(
                item_id=item.item_id,
                product_name=catalog.product_name if catalog else None,
                expiration_date=item.expiration_date,
                days_until_expiry=max(0, (item.expiration_date - today).days),
            )
        )
    return summaries


def build_ingredient_string(summaries: list[ExpiringItemSummary]) -> str:
    """
    Build a comma-separated ingredient string from expiring item summaries.

    Resolution rules:
      - Items with no product_name (vision-scanned leftovers) are skipped.
      - Items are included in the urgency order supplied by the caller.
      - String is capped at _INGREDIENT_STRING_MAX_CHARS (200) characters.
      - The string never ends with a trailing comma or a partial ingredient name.

    Returns:
        str — ready-to-send Spoonacular ingredients parameter value,
              or "" if no named items are available.
    """
    segments: list[str] = []
    total: int = 0
    for summary in summaries:
        if not summary.product_name:
            continue
        name: str = summary.product_name.strip()
        # Length includes the ", " separator that precedes all but the first item
        needed: int = len(name) + (2 if segments else 0)
        if total + needed > _INGREDIENT_STRING_MAX_CHARS:
            break
        segments.append(name)
        total += needed

    result = ", ".join(segments)
    logger.debug(
        "Ingredient string built — items=%s chars=%s string=%r",
        len(segments),
        len(result),
        result[:80],
    )
    return result


async def fetch_recipe_suggestions(
    ingredient_string: str,
    num_results: int = 10,
) -> list[dict]:
    """
    Call Spoonacular GET /recipes/findByIngredients and return raw recipe dicts.

    Args:
        ingredient_string: Comma-separated ingredient names (≤200 chars).
        num_results:       Maximum recipes to request from Spoonacular.

    Returns:
        list[dict] — raw Spoonacular recipe objects (may be empty).

    Raises:
        HTTPException 503 — SPOONACULAR_API_KEY is absent from the environment.
        HTTPException 504 — Spoonacular request timed out.
        HTTPException 502 — Spoonacular returned a non-200 HTTP status.
    """
    api_key: Optional[str] = os.getenv("SPOONACULAR_API_KEY")
    if not api_key:
        logger.error(
            "SPOONACULAR_API_KEY is not set — Spoonacular API call aborted"
        )
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=(
                "Recipe service is not configured. "
                "Set SPOONACULAR_API_KEY in backend/app/.env and restart."
            ),
        )

    params = {
        "ingredients": ingredient_string,
        "number": num_results,
        "ranking": 1,       # maximise used-ingredient count per recipe
        "apiKey": api_key,
    }

    logger.info(
        "Dispatching Spoonacular request — ingredients=%r num_results=%s",
        ingredient_string[:80],
        num_results,
    )

    try:
        async with httpx.AsyncClient(timeout=_SPOONACULAR_TIMEOUT) as client:
            response = await client.get(_SPOONACULAR_BASE_URL, params=params)
    except httpx.TimeoutException:
        logger.warning(
            "Spoonacular API request timed out after %.1fs", _SPOONACULAR_TIMEOUT
        )
        raise HTTPException(
            status_code=status.HTTP_504_GATEWAY_TIMEOUT,
            detail="Spoonacular API request timed out.",
        )
    except httpx.RequestError as exc:
        logger.warning(
            "Spoonacular network error — %s: %s", type(exc).__name__, exc
        )
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Spoonacular API is unreachable. Please retry.",
        )

    if response.status_code != 200:
        logger.warning(
            "Spoonacular returned non-200 status=%s", response.status_code
        )
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Spoonacular API returned an unexpected status: {response.status_code}.",
        )

    recipes: list[dict] = response.json()
    logger.info(
        "Spoonacular response received — %s candidate recipes for ingredient_string=%r",
        len(recipes),
        ingredient_string[:80],
    )
    return recipes
