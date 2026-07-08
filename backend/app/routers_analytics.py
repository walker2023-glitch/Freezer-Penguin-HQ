"""
Analytics router — Phase 6 SQL assignment scaffold.

Individual endpoints (Weeks 6–12):
    GET /api/v1/analytics/days-until-expiry          — Week 6  FUNCTION
    GET /api/v1/analytics/ready-to-cook-recipes      — Week 7  INNER JOIN
    GET /api/v1/analytics/pantry-health              — Week 8  CONDITIONAL
    GET /api/v1/analytics/missing-ingredients        — Week 9  OUTER JOIN
    GET /api/v1/analytics/storage-zone-counts        — Week 10 AGGREGATE
    GET /api/v1/analytics/high-priority-alert        — Week 11 SUBQUERY
    GET /api/v1/analytics/culinary-greatest-hits     — Week 12 WINDOW

Aggregate endpoint (Flutter dashboard):
    GET /api/v1/analytics/pantry-insights

Each route forwards the injected db session to its service stub. Replace the
mock bodies inside services_analytics.py with real SQL when your assignment
queries are complete.
"""

import logging

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas_analytics import (
    ExpiryFunctionItem,
    HighPriorityAlertResponse,
    LeaderboardEntry,
    MissingIngredient,
    PantryHealthResponse,
    PantryInsightsResponse,
    ReadyToCookCard,
    StorageZoneCount,
)
import app.services_analytics as svc

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/analytics",
    tags=["Analytics — Pantry Insights"],
)


# ---------------------------------------------------------------------------
# WEEK 6 — FUNCTION
# ---------------------------------------------------------------------------

@router.get(
    "/days-until-expiry",
    response_model=list[ExpiryFunctionItem],
    status_code=status.HTTP_200_OK,
    summary="Week 6 — Days until expiration using a SQL date function",
)
async def get_days_until_expiry_endpoint(
    user_id: int = Query(
        default=1,
        ge=1,
        description="Target user ID — bind as :user_id inside your Week 6 SQL",
    ),
    db: Session = Depends(get_db),
) -> list[ExpiryFunctionItem]:
    logger.info(
        "routers_analytics.get_days_until_expiry_endpoint: user_id=%s",
        user_id,
    )
    try:
        rows = await svc.get_days_until_expiry(db)
        logger.info(
            "routers_analytics.get_days_until_expiry_endpoint: "
            "returned %s rows for user_id=%s",
            len(rows),
            user_id,
        )
        return rows
    except Exception as exc:
        logger.error(
            "routers_analytics.get_days_until_expiry_endpoint: failed — %s",
            exc,
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Analytics query failed for days-until-expiry.",
        ) from exc


# ---------------------------------------------------------------------------
# WEEK 7 — INNER JOIN
# ---------------------------------------------------------------------------

@router.get(
    "/ready-to-cook-recipes",
    response_model=list[ReadyToCookCard],
    status_code=status.HTTP_200_OK,
    summary="Week 7 — Match inventory items to available recipes via INNER JOIN",
)
async def get_ready_to_cook_recipes_endpoint(
    user_id: int = Query(
        default=1,
        ge=1,
        description="Target user ID — bind as :user_id inside your Week 7 SQL",
    ),
    db: Session = Depends(get_db),
) -> list[ReadyToCookCard]:
    logger.info(
        "routers_analytics.get_ready_to_cook_recipes_endpoint: user_id=%s",
        user_id,
    )
    try:
        rows = await svc.get_ready_to_cook_recipes(db)
        logger.info(
            "routers_analytics.get_ready_to_cook_recipes_endpoint: "
            "returned %s rows for user_id=%s",
            len(rows),
            user_id,
        )
        return rows
    except Exception as exc:
        logger.error(
            "routers_analytics.get_ready_to_cook_recipes_endpoint: failed — %s",
            exc,
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Analytics query failed for ready-to-cook-recipes.",
        ) from exc


# ---------------------------------------------------------------------------
# WEEK 8 — CONDITIONAL
# ---------------------------------------------------------------------------

@router.get(
    "/pantry-health",
    response_model=PantryHealthResponse,
    status_code=status.HTTP_200_OK,
    summary="Week 8 — Pantry health breakdown using CASE WHEN conditional logic",
)
async def get_pantry_health_breakdown_endpoint(
    user_id: int = Query(
        default=1,
        ge=1,
        description="Target user ID — bind as :user_id inside your Week 8 SQL",
    ),
    db: Session = Depends(get_db),
) -> PantryHealthResponse:
    logger.info(
        "routers_analytics.get_pantry_health_breakdown_endpoint: user_id=%s",
        user_id,
    )
    try:
        payload = await svc.get_pantry_health_breakdown(db)
        logger.info(
            "routers_analytics.get_pantry_health_breakdown_endpoint: "
            "total=%s for user_id=%s",
            payload["total"],
            user_id,
        )
        return payload
    except Exception as exc:
        logger.error(
            "routers_analytics.get_pantry_health_breakdown_endpoint: failed — %s",
            exc,
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Analytics query failed for pantry-health.",
        ) from exc


# ---------------------------------------------------------------------------
# WEEK 9 — OUTER JOIN
# ---------------------------------------------------------------------------

@router.get(
    "/missing-ingredients",
    response_model=list[MissingIngredient],
    status_code=status.HTTP_200_OK,
    summary="Week 9 — Missing ingredients planner using LEFT/RIGHT OUTER JOIN",
)
async def get_missing_ingredients_planner_endpoint(
    user_id: int = Query(
        default=1,
        ge=1,
        description="Target user ID — bind as :user_id inside your Week 9 SQL",
    ),
    db: Session = Depends(get_db),
) -> list[MissingIngredient]:
    logger.info(
        "routers_analytics.get_missing_ingredients_planner_endpoint: user_id=%s",
        user_id,
    )
    try:
        rows = await svc.get_missing_ingredients_planner(db)
        logger.info(
            "routers_analytics.get_missing_ingredients_planner_endpoint: "
            "returned %s rows for user_id=%s",
            len(rows),
            user_id,
        )
        return rows
    except Exception as exc:
        logger.error(
            "routers_analytics.get_missing_ingredients_planner_endpoint: failed — %s",
            exc,
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Analytics query failed for missing-ingredients.",
        ) from exc


# ---------------------------------------------------------------------------
# WEEK 10 — AGGREGATE
# ---------------------------------------------------------------------------

@router.get(
    "/storage-zone-counts",
    response_model=list[StorageZoneCount],
    status_code=status.HTTP_200_OK,
    summary="Week 10 — Storage zone item counts using GROUP BY aggregate",
)
async def get_storage_zone_counts_endpoint(
    user_id: int = Query(
        default=1,
        ge=1,
        description="Target user ID — bind as :user_id inside your Week 10 SQL",
    ),
    db: Session = Depends(get_db),
) -> list[StorageZoneCount]:
    logger.info(
        "routers_analytics.get_storage_zone_counts_endpoint: user_id=%s",
        user_id,
    )
    try:
        rows = await svc.get_storage_zone_counts(db)
        logger.info(
            "routers_analytics.get_storage_zone_counts_endpoint: "
            "returned %s rows for user_id=%s",
            len(rows),
            user_id,
        )
        return rows
    except Exception as exc:
        logger.error(
            "routers_analytics.get_storage_zone_counts_endpoint: failed — %s",
            exc,
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Analytics query failed for storage-zone-counts.",
        ) from exc


# ---------------------------------------------------------------------------
# WEEK 11 — SUBQUERY
# ---------------------------------------------------------------------------

@router.get(
    "/high-priority-alert",
    response_model=HighPriorityAlertResponse,
    status_code=status.HTTP_200_OK,
    summary="Week 11 — Highest-priority expiring item alert using a SUBQUERY",
)
async def get_high_priority_subquery_alert_endpoint(
    user_id: int = Query(
        default=1,
        ge=1,
        description="Target user ID — bind as :user_id inside your Week 11 SQL",
    ),
    db: Session = Depends(get_db),
) -> HighPriorityAlertResponse:
    logger.info(
        "routers_analytics.get_high_priority_subquery_alert_endpoint: user_id=%s",
        user_id,
    )
    try:
        payload = await svc.get_high_priority_subquery_alert(db)
        logger.info(
            "routers_analytics.get_high_priority_subquery_alert_endpoint: "
            "alert_count=%s for user_id=%s",
            payload["alert_count"],
            user_id,
        )
        return payload
    except Exception as exc:
        logger.error(
            "routers_analytics.get_high_priority_subquery_alert_endpoint: failed — %s",
            exc,
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Analytics query failed for high-priority-alert.",
        ) from exc


# ---------------------------------------------------------------------------
# WEEK 12 — WINDOW FUNCTION
# ---------------------------------------------------------------------------

@router.get(
    "/culinary-greatest-hits",
    response_model=list[LeaderboardEntry],
    status_code=status.HTTP_200_OK,
    summary="Week 12 — Culinary greatest hits ranked with a WINDOW function",
)
async def get_culinary_greatest_hits_endpoint(
    user_id: int = Query(
        default=1,
        ge=1,
        description="Target user ID — bind as :user_id inside your Week 12 SQL",
    ),
    db: Session = Depends(get_db),
) -> list[LeaderboardEntry]:
    logger.info(
        "routers_analytics.get_culinary_greatest_hits_endpoint: user_id=%s",
        user_id,
    )
    try:
        rows = await svc.get_culinary_greatest_hits(db)
        logger.info(
            "routers_analytics.get_culinary_greatest_hits_endpoint: "
            "returned %s rows for user_id=%s",
            len(rows),
            user_id,
        )
        return rows
    except Exception as exc:
        logger.error(
            "routers_analytics.get_culinary_greatest_hits_endpoint: failed — %s",
            exc,
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Analytics query failed for culinary-greatest-hits.",
        ) from exc


# ---------------------------------------------------------------------------
# AGGREGATE — Flutter Pantry Insights dashboard
# ---------------------------------------------------------------------------

@router.get(
    "/pantry-insights",
    response_model=PantryInsightsResponse,
    status_code=status.HTTP_200_OK,
    summary=(
        "Aggregated pantry analytics dashboard — composes all 7 weekly SQL "
        "technique stubs into a single response for the Flutter client."
    ),
)
async def get_pantry_insights(
    user_id: int = Query(
        default=1,
        ge=1,
        description="Target user ID (must exist in Users table)",
    ),
    db: Session = Depends(get_db),
) -> PantryInsightsResponse:
    logger.info(
        "routers_analytics.get_pantry_insights: "
        "Received pantry-insights request for user_id=%s",
        user_id,
    )

    try:
        alert = await svc.get_high_priority_subquery_alert(db)
        health = await svc.get_pantry_health_breakdown(db)
        expiry_fn = await svc.get_days_until_expiry(db)
        ready = await svc.get_ready_to_cook_recipes(db)
        zones = await svc.get_storage_zone_counts(db)
        leaderboard = await svc.get_culinary_greatest_hits(db)
        shopping = await svc.get_missing_ingredients_planner(db)
    except Exception as exc:
        logger.error(
            "routers_analytics.get_pantry_insights: assembly failed — %s",
            exc,
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Analytics query failed while assembling pantry insights.",
        ) from exc

    logger.info(
        "routers_analytics.get_pantry_insights: "
        "Assembled for user_id=%s — alert=%s health_total=%s "
        "ready=%s zones=%s leaders=%s shopping=%s",
        user_id,
        alert["alert_count"],
        health["total"],
        len(ready),
        len(zones),
        len(leaderboard),
        len(shopping),
    )

    return PantryInsightsResponse(
        high_priority_alert=alert,
        pantry_health=health,
        expiry_function_results=expiry_fn,
        ready_to_cook=ready,
        storage_zones=zones,
        leaderboard=leaderboard,
        shopping_list=shopping,
    )
