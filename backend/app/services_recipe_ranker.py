"""
Gemini Recipe Ranking service — Feature 1.3 (Recipe Suggestions Engine).

Uses the modern google-genai unified SDK (NOT the deprecated google-generativeai).
The genai.Client() is instantiated once at module level and reads GEMINI_API_KEY
from the environment automatically. No external configure() call is needed.

FR-9 contract: every failure mode in this module MUST log at WARNING level and
return ([], False) — it MUST NOT raise an exception that would cause the router
to return a non-200 HTTP status. The caller always gets a usable response.
"""

import asyncio
import json
import logging
import traceback
from typing import Optional

from google import genai
from google.genai import types
from pydantic import BaseModel, Field, ValidationError

from app.schemas_recipes import GeminiRankedItem

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Model configuration
# ---------------------------------------------------------------------------
_RANKING_MODEL_NAME = "gemini-2.5-flash"
_RANKING_TIMEOUT_SECONDS = 20.0

# ---------------------------------------------------------------------------
# Gemini client — instantiated once at module import time.
# genai.Client() reads GEMINI_API_KEY from the environment and targets the
# v1beta gateway by default, which fully supports response_mime_type in
# GenerateContentConfig. No http_options override is required.
# ---------------------------------------------------------------------------
_client: genai.Client = genai.Client()

_RANKING_GENERATION_CONFIG = types.GenerateContentConfig(
    temperature=0.2,
    max_output_tokens=4096,
    response_mime_type="application/json",
)

# ---------------------------------------------------------------------------
# Ranking prompt template.
# {ingredient_list} and {recipe_json} are substituted at call time.
# Curly braces in the JSON schema example are doubled to escape .format().
# ---------------------------------------------------------------------------
_GEMINI_RANKING_PROMPT_TEMPLATE = (
    "You are a dietary safety filter and meal planning assistant for a home "
    "freezer inventory app called Freezer Penguin.\n"
    "Your task is to rank the following candidate recipes by their suitability "
    "for the provided expiring ingredients.\n\n"
    "Expiring ingredients (sorted by urgency): {ingredient_list}\n\n"
    "Candidate recipes from Spoonacular:\n{recipe_json}\n\n"
    "Return ONLY a valid JSON array — no markdown fences, no preamble, "
    "no explanations. "
    "Each element MUST conform to this exact schema:\n"
    "[\n"
    "  {{\n"
    '    "spoonacular_id": <int>,\n'
    '    "title": "<string>",\n'
    '    "gemini_rank": <int: 1 = most suitable, ascending, no ties>,\n'
    '    "gemini_safety_approved": <bool: false ONLY if recipe requires '
    'raw/undercooked thawed proteins>,\n'
    '    "ranking_rationale": "<string: one-sentence rationale, max 200 chars>"\n'
    "  }}\n"
    "]\n\n"
    "Ranking priority rules (applied in order):\n"
    "1. Recipes using the highest count of the provided expiring ingredients "
    "rank highest.\n"
    "2. Shorter ready_in_minutes breaks ties.\n"
    "3. Set gemini_safety_approved=false for any recipe requiring raw or "
    "undercooked seafood, eggs, or poultry.\n\n"
    "CRITICAL OUTPUT RULES — you MUST follow these exactly:\n"
    "- Return your response strictly as a compact, minified JSON array of objects.\n"
    "- Do NOT wrap your response in markdown code fences (no ```json, no ```).\n"
    "- Do NOT include any preamble, explanation, or trailing text outside the array.\n"
    "- The entire response must be valid JSON that can be parsed by json.loads() "
    "with no pre-processing."
)


async def rank_recipes(
    recipes: list[dict],
    ingredient_string: str,
) -> tuple[list[GeminiRankedItem], bool]:
    """
    Submit up to 5 Spoonacular recipe candidates to Gemini for safety filtering
    and ranked ordering using model gemini-2.5-flash.

    Args:
        recipes:           Raw Spoonacular recipe dicts. Top 5 are forwarded.
        ingredient_string: Comma-separated expiring ingredient names used to
                           retrieve these recipes (included in the prompt for
                           context).

    Returns:
        tuple[list[GeminiRankedItem], bool]:
            - Validated ranked recipe objects (empty list on any failure).
            - gemini_ranking_applied flag (always False on any failure — FR-9).

    This function NEVER raises. All exceptions are caught, logged at WARNING
    level, and cause graceful degradation to unranked Spoonacular results.
    """
    top_candidates = recipes[:5]
    if not top_candidates:
        logger.warning("Gemini ranking skipped — no recipe candidates provided.")
        return [], False

    recipe_payload = [
        {
            "id": r.get("id"),
            "title": r.get("title"),
            "readyInMinutes": r.get("readyInMinutes"),
            "usedIngredients": [
                i.get("name") for i in r.get("usedIngredients", []) if i.get("name")
            ],
            "missedIngredients": [
                i.get("name") for i in r.get("missedIngredients", []) if i.get("name")
            ],
        }
        for r in top_candidates
    ]

    prompt = _GEMINI_RANKING_PROMPT_TEMPLATE.format(
        ingredient_list=ingredient_string,
        recipe_json=json.dumps(recipe_payload, ensure_ascii=False),
    )

    logger.info(
        "Dispatching Gemini ranking request — model=%s candidates=%s",
        _RANKING_MODEL_NAME,
        len(top_candidates),
    )

    try:
        response = await asyncio.wait_for(
            _client.aio.models.generate_content(
                model=_RANKING_MODEL_NAME,
                contents=[prompt],
                config=_RANKING_GENERATION_CONFIG,
            ),
            timeout=_RANKING_TIMEOUT_SECONDS,
        )
    except asyncio.TimeoutError:
        logger.warning(
            "Gemini ranking unavailable: TimeoutError after %.1fs. "
            "Returning unranked Spoonacular results.",
            _RANKING_TIMEOUT_SECONDS,
        )
        return [], False
    except Exception as exc:
        logger.warning(
            "Gemini ranking unavailable: %s. "
            "Returning unranked Spoonacular results.\n%s",
            type(exc).__name__,
            traceback.format_exc(),
        )
        return [], False

    raw_text: str = response.text
    logger.info(
        "Gemini ranking response received — model=%s response_length=%s",
        _RANKING_MODEL_NAME,
        len(raw_text),
    )

    try:
        parsed = json.loads(raw_text)
    except json.JSONDecodeError:
        logger.warning(
            "Gemini ranking: JSON parse failed — raw (truncated): %r",
            raw_text[:300],
        )
        return [], False

    if not isinstance(parsed, list):
        logger.warning(
            "Gemini ranking: expected JSON array, got %s — raw: %r",
            type(parsed).__name__,
            raw_text[:300],
        )
        return [], False

    ranked: list[GeminiRankedItem] = []
    for entry in parsed:
        try:
            ranked.append(GeminiRankedItem.model_validate(entry))
        except ValidationError as exc:
            logger.warning(
                "Gemini ranking: skipping invalid entry — errors=%s entry=%s",
                exc.error_count(),
                str(entry)[:200],
            )

    if not ranked:
        logger.warning(
            "Gemini ranking: zero valid entries in response — "
            "falling back to unranked Spoonacular results."
        )
        return [], False

    logger.info(
        "Gemini ranking complete — model=%s valid_ranked_count=%s",
        _RANKING_MODEL_NAME,
        len(ranked),
    )
    return ranked, True
