"""
Pantry Insights analytics service — Phase 6 SQL assignment.

Each function maps to exactly one weekly SQL grading checkpoint (Weeks 6–12).
Raw SQL lives inside sqlalchemy.text() blocks; routers inject user_id.

Execution pattern (mandated by SKILL.md):
    from sqlalchemy import text
    result = db.execute(text("SELECT ..."), {"user_id": user_id})
    rows = result.mappings().all()

The db session is injected by the router via Depends(get_db). Never instantiate
SessionLocal() inside these functions (SKILL.md GR-3.3).

DO NOT remove the # TODO: Insert Raw SQL here comment — it is a graded marker.
"""

import logging
from datetime import date, datetime
from decimal import Decimal
from typing import Any

from sqlalchemy import text
from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)

_DEFAULT_THRESHOLD_DAYS = 7


def _mapping_rows(rows: list[Any]) -> list[dict[str, Any]]:
    """Convert SQLAlchemy RowMapping objects to plain dicts."""
    return [dict(row) for row in rows]


def _coerce_int(value: Any, default: int = 0) -> int:
    if value is None:
        return default
    if isinstance(value, Decimal):
        return int(value)
    return int(value)


def _format_expiration(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, (date, datetime)):
        return value.isoformat()
    return str(value)


# ---------------------------------------------------------------------------
# WEEK 6 — QUERY WITH A FUNCTION
# Goal: Calculate days until expiration using a date function (DATEDIFF).
# Target: get_days_until_expiry(db: Session, user_id: int)
# ---------------------------------------------------------------------------

async def get_days_until_expiry(db: Session, user_id: int) -> list[dict[str, Any]]:
    """
    WEEK 6 — FUNCTION
    Compute days_until_expiry per inventory row using a MySQL date function.

    # TODO: Insert Raw SQL here
    """
    logger.info(
        "services_analytics.get_days_until_expiry: query invoked user_id=%s",
        user_id,
    )

    try:
        _sql = text(
            """
            SELECT ii.item_id,
                   COALESCE(bm.product_name, CONCAT('Item #', ii.item_id)) AS product_name,
                   DATEDIFF(ii.expiration_date, CURDATE()) AS days_until_expiry
            FROM   inventory_items ii
            LEFT JOIN barcode_master bm ON ii.UPC = bm.UPC
            WHERE  ii.user_id = :user_id
            ORDER  BY days_until_expiry ASC
            """
        )
        rows = db.execute(_sql, {"user_id": user_id}).mappings().all()
        payload = _mapping_rows(rows)
        logger.info(
            "services_analytics.get_days_until_expiry: returned %s rows user_id=%s",
            len(payload),
            user_id,
        )
        return payload
    except Exception as exc:
        logger.error(
            "services_analytics.get_days_until_expiry: query failed user_id=%s — %s",
            user_id,
            exc,
        )
        raise


# ---------------------------------------------------------------------------
# WEEK 7 — QUERY WITH AN INNER JOIN
# Goal: Match inventory items to recipes where ingredients are available.
# Target: get_ready_to_cook_recipes(db: Session, user_id: int)
# ---------------------------------------------------------------------------

async def get_ready_to_cook_recipes(db: Session, user_id: int) -> list[dict[str, Any]]:
    """
    WEEK 7 — INNER JOIN
    Join inventory_items to recipe_ingredients and recipes for cook-now matches.

    # TODO: Insert Raw SQL here
    """
    logger.info(
        "services_analytics.get_ready_to_cook_recipes: query invoked user_id=%s",
        user_id,
    )

    try:
        _sql = text(
            """
            SELECT DISTINCT
                   r.title AS recipe_title,
                   DATEDIFF(ii.expiration_date, CURDATE()) AS days_left_for_key_ingredient,
                   COALESCE(bm.product_name, ri.ingredient_name) AS key_ingredient
            FROM   inventory_items ii
            INNER JOIN barcode_master bm ON ii.UPC = bm.UPC
            INNER JOIN recipe_ingredients ri
                    ON ri.recipe_id IS NOT NULL
                   AND (
                        ri.item_id = ii.item_id
                        OR LOWER(bm.product_name) LIKE CONCAT('%', LOWER(ri.ingredient_name), '%')
                        OR LOWER(ri.ingredient_name) LIKE CONCAT('%', LOWER(bm.product_name), '%')
                   )
            INNER JOIN recipes r ON r.recipe_id = ri.recipe_id
            WHERE  ii.user_id = :user_id
              AND  (ii.is_consumed IS NULL OR ii.is_consumed = 0)
            ORDER  BY days_left_for_key_ingredient ASC
            LIMIT  20
            """
        )
        rows = db.execute(_sql, {"user_id": user_id}).mappings().all()
        payload = _mapping_rows(rows)
        logger.info(
            "services_analytics.get_ready_to_cook_recipes: returned %s rows user_id=%s",
            len(payload),
            user_id,
        )
        return payload
    except Exception as exc:
        logger.error(
            "services_analytics.get_ready_to_cook_recipes: query failed user_id=%s — %s",
            user_id,
            exc,
        )
        raise


# ---------------------------------------------------------------------------
# WEEK 8 — QUERY WITH CONDITIONAL LOGIC
# Goal: Categorize pantry health using CASE WHEN (Safe / Use Soon / Expired).
# Target: get_pantry_health_breakdown(db: Session, user_id: int)
# ---------------------------------------------------------------------------

async def get_pantry_health_breakdown(db: Session, user_id: int) -> dict[str, Any]:
    """
    WEEK 8 — CONDITIONAL (CASE WHEN)
    Bucket inventory rows into safe / use_soon / expired counts.

    # TODO: Insert Raw SQL here
    """
    logger.info(
        "services_analytics.get_pantry_health_breakdown: query invoked user_id=%s",
        user_id,
    )

    try:
        _sql = text(
            """
            SELECT
                SUM(CASE WHEN DATEDIFF(expiration_date, CURDATE()) >= 7 THEN 1 ELSE 0 END) AS safe,
                SUM(CASE WHEN DATEDIFF(expiration_date, CURDATE()) BETWEEN 1 AND 6 THEN 1 ELSE 0 END) AS use_soon,
                SUM(CASE WHEN DATEDIFF(expiration_date, CURDATE()) < 1 THEN 1 ELSE 0 END) AS expired,
                COUNT(*) AS total
            FROM inventory_items
            WHERE user_id = :user_id
              AND (is_consumed IS NULL OR is_consumed = 0)
            """
        )
        row = db.execute(_sql, {"user_id": user_id}).mappings().first()
        if not row:
            return {"safe": 0, "use_soon": 0, "expired": 0, "total": 0}

        payload = {
            "safe": _coerce_int(row["safe"]),
            "use_soon": _coerce_int(row["use_soon"]),
            "expired": _coerce_int(row["expired"]),
            "total": _coerce_int(row["total"]),
        }
        logger.info(
            "services_analytics.get_pantry_health_breakdown: total=%s user_id=%s",
            payload["total"],
            user_id,
        )
        return payload
    except Exception as exc:
        logger.error(
            "services_analytics.get_pantry_health_breakdown: query failed user_id=%s — %s",
            user_id,
            exc,
        )
        raise


# ---------------------------------------------------------------------------
# WEEK 9 — QUERY WITH AN OUTER JOIN
# Goal: LEFT/RIGHT JOIN to isolate missing ingredients for close recipes.
# Target: get_missing_ingredients_planner(db: Session, user_id: int)
# ---------------------------------------------------------------------------

async def get_missing_ingredients_planner(db: Session, user_id: int) -> list[dict[str, Any]]:
    """
    WEEK 9 — OUTER JOIN (LEFT JOIN)
    Surface recipe ingredients absent from the user's inventory.

    # TODO: Insert Raw SQL here
    """
    logger.info(
        "services_analytics.get_missing_ingredients_planner: query invoked user_id=%s",
        user_id,
    )

    try:
        _sql = text(
            """
            SELECT DISTINCT
                   ri.ingredient_name,
                   r.title AS needed_for_recipe
            FROM   recipes r
            INNER JOIN recipe_ingredients ri ON ri.recipe_id = r.recipe_id
            LEFT JOIN inventory_items ii
                   ON ii.user_id = :user_id
                  AND (ii.is_consumed IS NULL OR ii.is_consumed = 0)
                  AND (
                        ri.item_id = ii.item_id
                        OR EXISTS (
                            SELECT 1
                            FROM   barcode_master bm
                            WHERE  bm.UPC = ii.UPC
                              AND  (
                                    LOWER(bm.product_name) LIKE CONCAT('%', LOWER(ri.ingredient_name), '%')
                                 OR LOWER(ri.ingredient_name) LIKE CONCAT('%', LOWER(bm.product_name), '%')
                              )
                        )
                  )
            WHERE  ii.item_id IS NULL
            ORDER  BY needed_for_recipe, ri.ingredient_name
            LIMIT  25
            """
        )
        rows = db.execute(_sql, {"user_id": user_id}).mappings().all()
        payload = _mapping_rows(rows)
        logger.info(
            "services_analytics.get_missing_ingredients_planner: returned %s rows user_id=%s",
            len(payload),
            user_id,
        )
        return payload
    except Exception as exc:
        logger.error(
            "services_analytics.get_missing_ingredients_planner: query failed user_id=%s — %s",
            user_id,
            exc,
        )
        raise


# ---------------------------------------------------------------------------
# WEEK 10 — QUERY WITH AGGREGATE FUNCTION AND GROUP BY
# Goal: COUNT active items grouped by storage location IDs.
# Target: get_storage_zone_counts(db: Session, user_id: int)
# ---------------------------------------------------------------------------

async def get_storage_zone_counts(db: Session, user_id: int) -> list[dict[str, Any]]:
    """
    WEEK 10 — AGGREGATE (GROUP BY + COUNT)
    Count active inventory items per storage location.

    # TODO: Insert Raw SQL here
    """
    logger.info(
        "services_analytics.get_storage_zone_counts: query invoked user_id=%s",
        user_id,
    )

    try:
        _sql = text(
            """
            SELECT sl.location_name AS zone_name,
                   COUNT(ii.item_id) AS item_count
            FROM   inventory_items ii
            INNER JOIN storage_locations sl
                    ON ii.location_id = sl.location_id
                   AND sl.user_id = ii.user_id
            WHERE  ii.user_id = :user_id
              AND  (ii.is_consumed IS NULL OR ii.is_consumed = 0)
            GROUP  BY ii.location_id, sl.location_name
            ORDER  BY item_count DESC
            """
        )
        rows = db.execute(_sql, {"user_id": user_id}).mappings().all()
        payload = [
            {
                "zone_name": row["zone_name"],
                "item_count": _coerce_int(row["item_count"]),
            }
            for row in rows
        ]
        logger.info(
            "services_analytics.get_storage_zone_counts: returned %s rows user_id=%s",
            len(payload),
            user_id,
        )
        return payload
    except Exception as exc:
        logger.error(
            "services_analytics.get_storage_zone_counts: query failed user_id=%s — %s",
            user_id,
            exc,
        )
        raise


# ---------------------------------------------------------------------------
# WEEK 11 — QUERY USING A SUBQUERY
# Goal: Isolate highest-priority expiring item and find recipes for it.
# Target: get_high_priority_subquery_alert(db: Session, user_id: int)
# ---------------------------------------------------------------------------

async def get_high_priority_subquery_alert(db: Session, user_id: int) -> dict[str, Any]:
    """
    WEEK 11 — SUBQUERY
    Use a subquery to find the most urgent expiring item(s) within threshold_days.

    # TODO: Insert Raw SQL here
    """
    logger.info(
        "services_analytics.get_high_priority_subquery_alert: query invoked user_id=%s",
        user_id,
    )

    threshold_days = _DEFAULT_THRESHOLD_DAYS

    try:
        _sql = text(
            """
            SELECT COALESCE(bm.product_name, CONCAT('Item #', ii.item_id)) AS product_name,
                   DATE_FORMAT(ii.expiration_date, '%Y-%m-%d') AS expiration_date,
                   DATEDIFF(ii.expiration_date, CURDATE()) AS days_remaining
            FROM   inventory_items ii
            LEFT JOIN barcode_master bm ON ii.UPC = bm.UPC
            WHERE  ii.user_id = :user_id
              AND  (ii.is_consumed IS NULL OR ii.is_consumed = 0)
              AND  DATEDIFF(ii.expiration_date, CURDATE()) <= :threshold_days
              AND  ii.expiration_date = (
                       SELECT MIN(i2.expiration_date)
                       FROM   inventory_items i2
                       WHERE  i2.user_id = :user_id
                         AND  (i2.is_consumed IS NULL OR i2.is_consumed = 0)
                         AND  DATEDIFF(i2.expiration_date, CURDATE()) <= :threshold_days
                   )
            ORDER  BY days_remaining ASC
            """
        )
        rows = db.execute(
            _sql,
            {"user_id": user_id, "threshold_days": threshold_days},
        ).mappings().all()

        expiring_items = [
            {
                "product_name": row["product_name"],
                "expiration_date": _format_expiration(row["expiration_date"]),
                "days_remaining": _coerce_int(row["days_remaining"]),
            }
            for row in rows
        ]

        payload = {
            "alert_count": len(expiring_items),
            "threshold_days": threshold_days,
            "expiring_items": expiring_items,
        }
        logger.info(
            "services_analytics.get_high_priority_subquery_alert: alert_count=%s user_id=%s",
            payload["alert_count"],
            user_id,
        )
        return payload
    except Exception as exc:
        logger.error(
            "services_analytics.get_high_priority_subquery_alert: query failed user_id=%s — %s",
            user_id,
            exc,
        )
        raise


# ---------------------------------------------------------------------------
# WEEK 12 — QUERY WITH A WINDOW FUNCTION
# Goal: Rank most frequently cooked/logged items using RANK() OVER.
# Target: get_culinary_greatest_hits(db: Session, user_id: int)
# ---------------------------------------------------------------------------

async def get_culinary_greatest_hits(db: Session, user_id: int) -> list[dict[str, Any]]:
    """
    WEEK 12 — WINDOW FUNCTION (RANK / ROW_NUMBER)
    Rank items by consumption frequency with RANK() OVER.

    # TODO: Insert Raw SQL here
    """
    logger.info(
        "services_analytics.get_culinary_greatest_hits: query invoked user_id=%s",
        user_id,
    )

    try:
        _sql = text(
            """
            SELECT product_name,
                   times_consumed,
                   item_rank AS `rank`
            FROM (
                SELECT COALESCE(bm.product_name, CONCAT('Item #', ii.item_id)) AS product_name,
                       COUNT(*) AS times_consumed,
                       RANK() OVER (ORDER BY COUNT(*) DESC) AS item_rank
                FROM   waste_logs wl
                INNER JOIN inventory_items ii ON wl.item_id = ii.item_id
                LEFT JOIN barcode_master bm ON ii.UPC = bm.UPC
                WHERE  ii.user_id = :user_id
                GROUP BY ii.item_id, COALESCE(bm.product_name, CONCAT('Item #', ii.item_id))
            ) ranked_hits
            ORDER BY item_rank ASC, times_consumed DESC
            LIMIT 10
            """
        )
        rows = db.execute(_sql, {"user_id": user_id}).mappings().all()
        payload = [
            {
                "rank": _coerce_int(row["rank"]),
                "product_name": row["product_name"],
                "times_consumed": _coerce_int(row["times_consumed"]),
            }
            for row in rows
        ]
        logger.info(
            "services_analytics.get_culinary_greatest_hits: returned %s rows user_id=%s",
            len(payload),
            user_id,
        )
        return payload
    except Exception as exc:
        logger.error(
            "services_analytics.get_culinary_greatest_hits: query failed user_id=%s — %s",
            user_id,
            exc,
        )
        raise
