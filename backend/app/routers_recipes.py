"""
Recipe suggestions router — Feature 1.3 (Expiration-Driven Recipe Engine).

Route:
    GET /api/v1/recipes/suggestions/{user_id}

Transaction sequence:
    1. Query expiring inventory_items LEFT JOIN barcode_master for user.
    2. Build Spoonacular ingredient string (urgency-sorted, 200-char cap).
    3. Early HTTP 200 if no expiring named items found (FR-3).
    4. Call Spoonacular findByIngredients (raises 502/503/504 on API failure).
    5. Early HTTP 200 if Spoonacular returns zero recipes.
    6. Stage Recipe upserts (spoonacular_id existence check — db.add + db.flush).
    7. Stage RecipeIngredient inserts with fuzzy inventory match resolution.
    8. Call Gemini ranker — graceful degradation; never blocks HTTP 200 (FR-9).
    9. Apply Gemini rankings to staged DBRecipe objects in memory.
   10. Single db.commit() — all Recipe + RecipeIngredient rows land atomically (FR-10).
   11. Return RecipeSuggestionResponse HTTP 200.

SKILL.md Guardrails enforced:
    §3.2  — status_code=HTTP_200_OK on the GET route.
    §3.3  — Both DB write blocks (staging and commit) wrapped in try/except/rollback.
    §4.1  — INFO/WARNING/ERROR log lines for every I/O event and state transition.
    FR-9  — Gemini failure never causes a non-200 response.
    FR-10 — Single db.commit() after Gemini ranking is applied.
"""

import logging
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import DBBarcodeMaster, DBInventoryItem, DBRecipe, DBRecipeIngredient
from app.schemas_recipes import (
    ExpiringItemSummary,
    RecipeIngredientSchema,
    RecipeSuggestionItem,
    RecipeSuggestionResponse,
)
from app.services_recipe_ranker import rank_recipes
from app.services_spoonacular import (
    build_expiring_summaries,
    build_ingredient_string,
    fetch_recipe_suggestions,
    get_expiring_items,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/recipes", tags=["Recipe Engine"])


def _resolve_ingredient_match(
    ing_name: str,
    user_id: int,
    db: Session,
) -> Optional[int]:
    """
    Return the item_id of the first active, unconsumed inventory row whose
    barcode_master product_name contains ing_name (case-insensitive), or None.
    Vision-scanned items (UPC=None, no barcode_master row) are never matched.
    """
    matched = (
        db.query(DBInventoryItem)
        .join(DBBarcodeMaster, DBInventoryItem.UPC == DBBarcodeMaster.UPC)
        .filter(
            DBInventoryItem.user_id == user_id,
            DBInventoryItem.is_consumed.isnot(True),
            DBBarcodeMaster.product_name.ilike(f"%{ing_name}%"),
        )
        .first()
    )
    return matched.item_id if matched else None


@router.get(
    "/suggestions/{user_id}",
    response_model=RecipeSuggestionResponse,
    status_code=status.HTTP_200_OK,
    summary=(
        "Return Gemini-ranked recipe suggestions for a user's "
        "expiring freezer inventory"
    ),
    responses={
        200: {"description": "Recipe suggestions — Gemini ranking applied when available"},
        502: {"description": "Spoonacular API returned a non-2xx status"},
        503: {"description": "SPOONACULAR_API_KEY is not configured"},
        504: {"description": "Spoonacular API request timed out"},
        500: {"description": "Database write failed — transaction rolled back"},
    },
)
async def get_recipe_suggestions(
    user_id: int,
    days_window: int = Query(
        default=3,
        ge=1,
        le=14,
        description="Expiration lookahead window in days (1–14). Default: 3.",
    ),
    db: Session = Depends(get_db),
) -> RecipeSuggestionResponse:
    logger.info(
        "Recipe suggestions request — user_id=%s days_window=%s",
        user_id,
        days_window,
    )

    # ------------------------------------------------------------------
    # Step 1: Query expiring inventory items
    # ------------------------------------------------------------------
    rows = get_expiring_items(user_id, days_window, db)
    expiring_summaries: list[ExpiringItemSummary] = build_expiring_summaries(rows)
    ingredient_string: str = build_ingredient_string(expiring_summaries)

    # ------------------------------------------------------------------
    # Step 2: Early exit — no expiring items with resolvable names (FR-3)
    # ------------------------------------------------------------------
    if not expiring_summaries or not ingredient_string:
        logger.info(
            "No expiring items with product names — user_id=%s days_window=%s "
            "— returning early with empty recipe list",
            user_id,
            days_window,
        )
        return RecipeSuggestionResponse(
            user_id=user_id,
            days_window=days_window,
            items_expiring=[],
            recipes=[],
            gemini_ranking_applied=False,
            message="No items expiring within the selected window.",
        )

    # ------------------------------------------------------------------
    # Step 3: Call Spoonacular (raises 502 / 503 / 504 on failure)
    # ------------------------------------------------------------------
    spoonacular_recipes = await fetch_recipe_suggestions(ingredient_string)

    if not spoonacular_recipes:
        logger.info(
            "Spoonacular returned zero recipes — user_id=%s ingredient_string=%r",
            user_id,
            ingredient_string[:80],
        )
        return RecipeSuggestionResponse(
            user_id=user_id,
            days_window=days_window,
            items_expiring=expiring_summaries,
            recipes=[],
            gemini_ranking_applied=False,
            message="No recipes found for the current expiring ingredients.",
        )

    # ------------------------------------------------------------------
    # Step 4 + 5: Stage Recipe upserts and RecipeIngredient inserts.
    # Build ingredient response data during staging to avoid re-querying
    # after commit. staged keyed by spoonacular_id for O(1) rank lookup.
    # ------------------------------------------------------------------
    staged: dict[int, DBRecipe] = {}
    staged_ingredient_responses: dict[int, list[RecipeIngredientSchema]] = {}

    try:
        for raw_recipe in spoonacular_recipes:
            spoonacular_id: int = raw_recipe.get("id") or 0
            if not spoonacular_id:
                continue

            existing: Optional[DBRecipe] = (
                db.query(DBRecipe)
                .filter(DBRecipe.spoonacular_id == spoonacular_id)
                .first()
            )

            if existing:
                db_recipe = existing
                logger.info(
                    "Recipe cache HIT — spoonacular_id=%s title=%r",
                    spoonacular_id,
                    db_recipe.title,
                )
            else:
                db_recipe = DBRecipe(
                    spoonacular_id=spoonacular_id,
                    title=(raw_recipe.get("title") or "Unknown Recipe")[:500],
                    image_url=raw_recipe.get("image") or None,
                    source_url=raw_recipe.get("sourceUrl") or None,
                    ready_in_minutes=raw_recipe.get("readyInMinutes") or None,
                    servings=raw_recipe.get("servings") or None,
                    gemini_safety_approved=False,
                    gemini_rank=None,
                    cached_at=datetime.now(tz=timezone.utc),
                )
                db.add(db_recipe)
                db.flush()
                logger.info(
                    "Recipe cache MISS — staged INSERT spoonacular_id=%s recipe_id=%s",
                    spoonacular_id,
                    db_recipe.recipe_id,
                )

            staged[spoonacular_id] = db_recipe

            used_ings = raw_recipe.get("usedIngredients") or []
            missed_ings = raw_recipe.get("missedIngredients") or []
            ingredient_responses: list[RecipeIngredientSchema] = []

            for ing in used_ings:
                ing_name: str = (ing.get("name") or "")[:255].strip()
                if not ing_name:
                    continue
                matched_item_id = _resolve_ingredient_match(ing_name, user_id, db)
                ingredient_responses.append(RecipeIngredientSchema(
                    ingredient_name=ing_name,
                    matched_item_id=matched_item_id,
                    is_matched_to_inventory=(matched_item_id is not None),
                ))
                db.add(DBRecipeIngredient(
                    recipe_id=db_recipe.recipe_id,
                    item_id=matched_item_id,
                    ingredient_name=ing_name,
                    spoonacular_ingredient_id=ing.get("id") or None,
                    is_matched_to_inventory=(matched_item_id is not None),
                ))

            for ing in missed_ings:
                ing_name = (ing.get("name") or "")[:255].strip()
                if not ing_name:
                    continue
                ingredient_responses.append(RecipeIngredientSchema(
                    ingredient_name=ing_name,
                    matched_item_id=None,
                    is_matched_to_inventory=False,
                ))
                db.add(DBRecipeIngredient(
                    recipe_id=db_recipe.recipe_id,
                    item_id=None,
                    ingredient_name=ing_name,
                    spoonacular_ingredient_id=ing.get("id") or None,
                    is_matched_to_inventory=False,
                ))

            staged_ingredient_responses[spoonacular_id] = ingredient_responses

    except Exception as exc:
        db.rollback()
        logger.error(
            "DB staging failed during recipe upsert — user_id=%s raw error: %s",
            user_id,
            str(exc),
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database write failed during recipe caching. Please retry.",
        )

    # ------------------------------------------------------------------
    # Step 6: Gemini ranking — graceful degradation (FR-9)
    # Any exception inside rank_recipes is caught internally; this call
    # always returns (list, bool) and never raises.
    # ------------------------------------------------------------------
    gemini_ranked, gemini_ranking_applied = await rank_recipes(
        spoonacular_recipes, ingredient_string
    )

    rank_lookup: dict[int, tuple[int, bool]] = {
        r.spoonacular_id: (r.gemini_rank, r.gemini_safety_approved)
        for r in gemini_ranked
    }

    for sid, db_recipe in staged.items():
        rank_info = rank_lookup.get(sid)
        if rank_info:
            db_recipe.gemini_rank, db_recipe.gemini_safety_approved = rank_info

    # ------------------------------------------------------------------
    # Step 7: Single atomic commit — all Recipe + RecipeIngredient rows (FR-10)
    # ------------------------------------------------------------------
    try:
        db.commit()
        for db_recipe in staged.values():
            db.refresh(db_recipe)
        logger.info(
            "Recipe engine commit complete — user_id=%s recipes=%s "
            "gemini_ranking_applied=%s",
            user_id,
            len(staged),
            gemini_ranking_applied,
        )
    except Exception as exc:
        db.rollback()
        logger.error(
            "DB commit failed during recipe engine — user_id=%s raw error: %s",
            user_id,
            str(exc),
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database write failed during recipe caching. Please retry.",
        )

    # ------------------------------------------------------------------
    # Step 8: Build response — sort by Gemini rank (unranked last)
    # ------------------------------------------------------------------
    recipe_responses: list[RecipeSuggestionItem] = [
        RecipeSuggestionItem(
            recipe_id=staged[raw.get("id")].recipe_id,
            spoonacular_id=raw.get("id"),
            title=staged[raw.get("id")].title,
            image_url=staged[raw.get("id")].image_url,
            ready_in_minutes=staged[raw.get("id")].ready_in_minutes,
            servings=staged[raw.get("id")].servings,
            gemini_rank=staged[raw.get("id")].gemini_rank,
            gemini_safety_approved=staged[raw.get("id")].gemini_safety_approved,
            matched_ingredients=staged_ingredient_responses.get(raw.get("id"), []),
        )
        for raw in spoonacular_recipes
        if (raw.get("id") or 0) in staged
    ]

    # Ranked items first (gemini_rank=1 at top), unranked items appended last
    recipe_responses.sort(
        key=lambda r: (r.gemini_rank is None, r.gemini_rank or 0)
    )

    return RecipeSuggestionResponse(
        user_id=user_id,
        days_window=days_window,
        items_expiring=expiring_summaries,
        recipes=recipe_responses,
        gemini_ranking_applied=gemini_ranking_applied,
        message=None,
    )
