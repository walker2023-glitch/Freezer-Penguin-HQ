"""
Pydantic v2 serialisation contracts — Feature 1.3 (Recipe Suggestions Engine).

Schema hierarchy
----------------
RecipeSuggestionRequest   — documents the validated query parameters.
ExpiringItemSummary       — one expiring inventory row included in the response.
RecipeIngredientSchema    — per-ingredient match detail for a single recipe.
RecipeSuggestionItem      — one Spoonacular recipe enriched with Gemini ranking.
RecipeSuggestionResponse  — full HTTP 200 response body for the suggestions route.
GeminiRankedItem          — internal contract for validating Gemini JSON output.
"""

from typing import Optional
from datetime import date, datetime

from pydantic import BaseModel, Field


class RecipeSuggestionRequest(BaseModel):
    """
    Documents the accepted query parameters for
    GET /api/v1/recipes/suggestions/{user_id}.

    FastAPI reads these directly from the path/query; this schema is
    provided for documentation, testing, and client SDK generation.
    """
    user_id: int = Field(..., ge=1, description="Target user ID (path parameter).")
    days_window: int = Field(
        default=3,
        ge=1,
        le=14,
        description="Expiration lookahead window in days. Default: 3.",
    )


class ExpiringItemSummary(BaseModel):
    """
    One expiring inventory item included in the response summary.

    Items are sourced from an inventory_items LEFT JOIN barcode_master query
    filtered by user_id, expiration_date window, and is_consumed=False/NULL.
    Items with no resolvable product_name (vision-scanned leftovers) are
    excluded from the Spoonacular ingredient string but may still appear here.
    """
    model_config = {"from_attributes": True}

    item_id: int = Field(..., description="Auto-increment PK of the inventory_items row.")
    product_name: Optional[str] = Field(
        None,
        description="Product name from barcode_master JOIN. None for vision-scanned items.",
    )
    expiration_date: date = Field(..., description="Item expiration date (ISO-8601).")
    days_until_expiry: int = Field(
        ...,
        ge=0,
        description="Calendar days between today and expiration_date. 0 = expires today.",
    )


class RecipeIngredientSchema(BaseModel):
    """
    Per-ingredient match detail for a given recipe.

    is_matched_to_inventory=True when ingredient_name fuzzy-matches a
    barcode_master.product_name for an active, unconsumed inventory row
    belonging to the requesting user.
    """
    model_config = {"from_attributes": True}

    ingredient_name: str = Field(..., description="Ingredient name from Spoonacular response.")
    matched_item_id: Optional[int] = Field(
        None,
        description="FK to inventory_items.item_id. None when no inventory match is found.",
    )
    is_matched_to_inventory: bool = Field(
        ...,
        description="True when this ingredient maps to an active inventory row for this user.",
    )


class RecipeSuggestionItem(BaseModel):
    """
    One Spoonacular recipe enriched with Gemini ranking data and per-ingredient
    inventory match details.

    gemini_rank is None when Gemini ranking was unavailable (network timeout,
    auth failure, etc.) — the route always returns HTTP 200 regardless (FR-9).
    """
    model_config = {"from_attributes": True}

    recipe_id: int = Field(..., description="Local recipes.recipe_id (auto-assigned on cache-miss).")
    spoonacular_id: int = Field(..., description="Spoonacular recipe ID.")
    title: str = Field(..., description="Recipe title from Spoonacular.")
    image_url: Optional[str] = Field(None, description="Spoonacular recipe image URL.")
    ready_in_minutes: Optional[int] = Field(None, description="Estimated preparation time.")
    servings: Optional[int] = Field(None, description="Recipe serving count.")
    gemini_rank: Optional[int] = Field(
        None,
        description="Gemini-assigned rank (1 = most suitable). None if ranking was unavailable.",
    )
    gemini_safety_approved: bool = Field(
        default=False,
        description=(
            "False only when Gemini flags the recipe as requiring "
            "raw/undercooked thawed proteins."
        ),
    )
    matched_ingredients: list[RecipeIngredientSchema] = Field(
        default_factory=list,
        description="All ingredients from usedIngredients + missedIngredients with match data.",
    )


class RecipeSuggestionResponse(BaseModel):
    """
    HTTP 200 response body for GET /api/v1/recipes/suggestions/{user_id}.

    Always returns HTTP 200 regardless of Gemini availability (FR-9).
    When no items are expiring or no recipes are found, items_expiring and
    recipes will be empty lists and message will be set accordingly.
    """
    user_id: int
    days_window: int
    items_expiring: list[ExpiringItemSummary]
    recipes: list[RecipeSuggestionItem]
    gemini_ranking_applied: bool = Field(
        ...,
        description="True when Gemini successfully ranked the Spoonacular results.",
    )
    message: Optional[str] = Field(
        None,
        description="Populated only when items_expiring or recipes is empty.",
    )


class GeminiRankedItem(BaseModel):
    """
    Internal Pydantic v2 schema for validating a single element of Gemini's
    JSON ranking array. strict=True prevents silent type coercion from masking
    model response format regressions.
    """
    model_config = {"strict": True}

    spoonacular_id: int
    title: str
    gemini_rank: int = Field(..., ge=1, description="1 = most suitable; no ties.")
    gemini_safety_approved: bool
    ranking_rationale: Optional[str] = Field(
        None,
        max_length=200,
        description="One-sentence rationale from Gemini.",
    )
