"""
Pydantic v2 schemas for the Pantry Insights analytics endpoint.

Each response class maps to one SQL technique in the Phase 6 assignment:
    HighPriorityAlertResponse   ← SUBQUERY
    PantryHealthResponse        ← CONDITIONAL (CASE WHEN)
    ExpiryFunctionItem          ← FUNCTION (DATEDIFF / DATE_SUB)
    ReadyToCookCard             ← INNER JOIN
    StorageZoneCount            ← AGGREGATE (GROUP BY + COUNT)
    LeaderboardEntry            ← WINDOW FUNCTION (RANK)
    MissingIngredient           ← OUTER JOIN (LEFT JOIN)

All models use Pydantic v2 ConfigDict(from_attributes=True) as mandated by
SKILL.md §3.1.3 for SQLAlchemy ORM → Pydantic serialization compatibility.
"""

from pydantic import BaseModel, ConfigDict, Field


# ---------------------------------------------------------------------------
# SUBQUERY — high-priority expiry alert
# ---------------------------------------------------------------------------

class HighPriorityItem(BaseModel):
    product_name: str = Field(
        ...,
        description="Name of the food item approaching expiry",
        json_schema_extra={"example": "Salmon Fillet"},
    )
    expiration_date: str = Field(
        ...,
        description="ISO-8601 date string of the expiry date",
        json_schema_extra={"example": "2026-07-09"},
    )
    days_remaining: int = Field(
        ...,
        description="Calendar days remaining until expiry (may be negative if expired)",
        json_schema_extra={"example": 2},
    )

    model_config = ConfigDict(from_attributes=True)


class HighPriorityAlertResponse(BaseModel):
    """SQL Technique: SUBQUERY — items inside the alert threshold window."""

    alert_count: int = Field(
        ...,
        description="Number of items expiring within the threshold window",
        json_schema_extra={"example": 3},
    )
    threshold_days: int = Field(
        default=7,
        description="Day window used in the subquery filter (e.g., DATEDIFF < 7)",
        json_schema_extra={"example": 7},
    )
    expiring_items: list[HighPriorityItem] = Field(
        ...,
        description="Items ordered by expiration_date ASC",
    )

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# CONDITIONAL (CASE WHEN) — pantry health buckets
# ---------------------------------------------------------------------------

class PantryHealthResponse(BaseModel):
    """SQL Technique: CONDITIONAL — CASE WHEN on DATEDIFF(expiration_date, CURDATE())."""

    safe: int = Field(
        ...,
        description="Items with ≥ 7 days remaining",
        json_schema_extra={"example": 14},
    )
    use_soon: int = Field(
        ...,
        description="Items with 1–6 days remaining",
        json_schema_extra={"example": 5},
    )
    expired: int = Field(
        ...,
        description="Items past their expiration date",
        json_schema_extra={"example": 2},
    )
    total: int = Field(
        ...,
        description="Total item count (safe + use_soon + expired)",
        json_schema_extra={"example": 21},
    )

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# FUNCTION (DATE / DATEDIFF) — computed expiry days per item
# ---------------------------------------------------------------------------

class ExpiryFunctionItem(BaseModel):
    """SQL Technique: FUNCTION — apply DATEDIFF/DATE_SUB across inventory rows."""

    item_id: int = Field(
        ...,
        description="inventory_items primary key",
        json_schema_extra={"example": 101},
    )
    product_name: str = Field(
        ...,
        description="Food item name",
        json_schema_extra={"example": "Salmon Fillet"},
    )
    days_until_expiry: int = Field(
        ...,
        description="Output of the SQL date-difference function",
        json_schema_extra={"example": 2},
    )

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# INNER JOIN — ready-to-cook recipe cards
# ---------------------------------------------------------------------------

class ReadyToCookCard(BaseModel):
    """SQL Technique: INNER JOIN — inventory_items ⋈ recipe_ingredients ⋈ recipes."""

    recipe_title: str = Field(
        ...,
        description="Name of the matched recipe",
        json_schema_extra={"example": "Grilled Salmon Bowl"},
    )
    days_left_for_key_ingredient: int = Field(
        ...,
        description="Days remaining for the soonest-expiring matched ingredient",
        json_schema_extra={"example": 2},
    )
    key_ingredient: str = Field(
        ...,
        description="The ingredient driving this recipe match",
        json_schema_extra={"example": "Salmon Fillet"},
    )

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# AGGREGATE (GROUP BY + COUNT) — items per storage zone
# ---------------------------------------------------------------------------

class StorageZoneCount(BaseModel):
    """SQL Technique: AGGREGATE — GROUP BY location_name, COUNT(item_id)."""

    zone_name: str = Field(
        ...,
        description="Storage zone label (storage_locations.location_name)",
        json_schema_extra={"example": "Kitchen Freezer"},
    )
    item_count: int = Field(
        ...,
        description="Number of active items in this zone",
        json_schema_extra={"example": 8},
    )

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# WINDOW FUNCTION (RANK) — greatest-hits leaderboard
# ---------------------------------------------------------------------------

class LeaderboardEntry(BaseModel):
    """SQL Technique: WINDOW FUNCTION — RANK() OVER (ORDER BY consumed_count DESC)."""

    rank: int = Field(
        ...,
        description="Window rank position (1 = most consumed)",
        json_schema_extra={"example": 1},
    )
    product_name: str = Field(
        ...,
        description="Food item name",
        json_schema_extra={"example": "Chicken Breast"},
    )
    times_consumed: int = Field(
        ...,
        description="Number of consumption / waste_log events",
        json_schema_extra={"example": 14},
    )

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# OUTER JOIN (LEFT JOIN) — missing ingredients shopping list
# ---------------------------------------------------------------------------

class MissingIngredient(BaseModel):
    """SQL Technique: OUTER JOIN — recipe_ingredients LEFT JOIN inventory_items WHERE NULL."""

    ingredient_name: str = Field(
        ...,
        description="Ingredient not found in the user's current inventory",
        json_schema_extra={"example": "Heavy Cream"},
    )
    needed_for_recipe: str = Field(
        ...,
        description="Recipe that requires this missing ingredient",
        json_schema_extra={"example": "Pasta Carbonara"},
    )

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# UMBRELLA RESPONSE
# ---------------------------------------------------------------------------

class PantryInsightsResponse(BaseModel):
    """
    Full payload for GET /api/v1/analytics/pantry-insights.
    Aggregates all 7 SQL-technique results into a single JSON response.
    """

    high_priority_alert: HighPriorityAlertResponse = Field(
        ...,
        description="SUBQUERY: items expiring within threshold_days",
    )
    pantry_health: PantryHealthResponse = Field(
        ...,
        description="CONDITIONAL: safe / use_soon / expired bucket counts",
    )
    expiry_function_results: list[ExpiryFunctionItem] = Field(
        ...,
        description="FUNCTION: per-item DATEDIFF computed column",
    )
    ready_to_cook: list[ReadyToCookCard] = Field(
        ...,
        description="INNER JOIN: recipes matchable from current inventory",
    )
    storage_zones: list[StorageZoneCount] = Field(
        ...,
        description="AGGREGATE: item count grouped by storage zone",
    )
    leaderboard: list[LeaderboardEntry] = Field(
        ...,
        description="WINDOW: consumption frequency ranking",
    )
    shopping_list: list[MissingIngredient] = Field(
        ...,
        description="OUTER JOIN: ingredients absent from inventory",
    )

    model_config = ConfigDict(from_attributes=True)
