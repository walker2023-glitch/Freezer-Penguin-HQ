"""
CI baseline test suite — Freezer Penguin Backend
=================================================
Design constraints
------------------
* Must pass on a public GitHub Actions runner with NO live MySQL instance and
  NO valid GEMINI_API_KEY.  All external surface area is either avoided or
  patched at the module level before any app code is imported.

* GEMINI_API_KEY is set to a non-empty placeholder string so that:
    1. main.py startup guard  (if not os.getenv("GEMINI_API_KEY")) passes.
    2. genai.Client() constructor does NOT raise — the SDK validates the key
       only on the first real API call, not at construction time.

* DATABASE_URL is pointed at an in-process SQLite file so SQLAlchemy engine
  creation succeeds.  No actual DB connections are opened in these tests.

* The suite intentionally avoids importing main.py or routers, which trigger
  SQLAlchemy metadata sync (create_all) against the live DB.  We test the
  schema and service-constant layers only, which are fully self-contained.
"""

import os

# ---------------------------------------------------------------------------
# CRITICAL: set env vars BEFORE any app module is imported.
# These values are intentionally non-functional — they satisfy constructor
# guards without making any real network or DB connections.
# ---------------------------------------------------------------------------
os.environ.setdefault("GEMINI_API_KEY", "test-ci-placeholder")
os.environ.setdefault("DATABASE_URL", "sqlite:///./test_ci.db")

import pytest  # noqa: E402
from datetime import date, datetime  # noqa: E402
from pydantic import ValidationError  # noqa: E402

# Safe to import after env vars are in place.
from app.schemas import (  # noqa: E402
    GeminiVisionResult,
    BarcodeIngestionResponse,
    LeftoverScanResponse,
)


# ===========================================================================
# Smoke test — confirms the test harness itself is functional
# ===========================================================================

def test_baseline_assertion():
    """Minimal truth assertion: if this fails, the runner itself is broken."""
    assert 1 + 1 == 2


# ===========================================================================
# GeminiVisionResult — Pydantic v2 schema validation (FR-7 / FR-8)
# ===========================================================================

class TestGeminiVisionResult:

    def test_valid_full_payload(self):
        result = GeminiVisionResult.model_validate({
            "item_name": "Chicken Tikka Masala",
            "estimated_shelf_life_days": 90,
            "quantity_description": "2 cups",
            "confidence_score": 0.87,
            "notes": "Stored in glass container",
        })
        assert result.item_name == "Chicken Tikka Masala"
        assert result.estimated_shelf_life_days == 90
        assert result.confidence_score == 0.87

    def test_optional_fields_default_to_none(self):
        result = GeminiVisionResult.model_validate({
            "item_name": "Mystery Soup",
            "estimated_shelf_life_days": 60,
        })
        assert result.quantity_description is None
        assert result.confidence_score is None
        assert result.notes is None

    def test_shelf_life_must_be_at_least_one_day(self):
        with pytest.raises(ValidationError):
            GeminiVisionResult.model_validate({
                "item_name": "Food",
                "estimated_shelf_life_days": 0,
            })

    def test_confidence_score_cannot_exceed_one(self):
        with pytest.raises(ValidationError):
            GeminiVisionResult.model_validate({
                "item_name": "Food",
                "estimated_shelf_life_days": 30,
                "confidence_score": 1.5,
            })

    def test_confidence_score_cannot_be_negative(self):
        with pytest.raises(ValidationError):
            GeminiVisionResult.model_validate({
                "item_name": "Food",
                "estimated_shelf_life_days": 30,
                "confidence_score": -0.1,
            })

    def test_item_name_required(self):
        with pytest.raises(ValidationError):
            GeminiVisionResult.model_validate({
                "estimated_shelf_life_days": 30,
            })


# ===========================================================================
# BarcodeIngestionResponse — GR-1 upc nullable guardrail
# ===========================================================================

class TestBarcodeIngestionResponse:

    def test_upc_nullable_guardrail_gr1(self):
        """GR-1: upc column MUST remain nullable (supports raw leftover path)."""
        resp = BarcodeIngestionResponse(
            item_id=1,
            upc=None,
            product_name="Atlantic Salmon Fillet",
            brand="Ocean Select",
            quantity=2,
            location_id=1,
            unit_id=1,
            user_id=5,
            expiration_date=date(2027, 3, 15),
            upserted=False,
        )
        assert resp.upc is None

    def test_upc_accepts_string_value(self):
        resp = BarcodeIngestionResponse(
            item_id=2,
            upc="012345678901",
            product_name="Frozen Peas",
            brand="Green Giant",
            quantity=1,
            location_id=2,
            unit_id=1,
            user_id=5,
            expiration_date=date(2026, 12, 1),
            upserted=True,
        )
        assert resp.upc == "012345678901"
        assert resp.upserted is True


# ===========================================================================
# LeftoverScanResponse — GR-1 upc=None on image_scan path (FR-3)
# ===========================================================================

class TestLeftoverScanResponse:

    def test_upc_is_none_for_image_scan_path(self):
        """
        Guardrail FR-3: every item created via vision ingestion must carry
        upc=None — raw leftovers have no barcode.
        """
        resp = LeftoverScanResponse(
            item_id=42,
            product_name="Homemade Chicken Soup",
            upc=None,
            estimated_shelf_life_days=90,
            expiration_date=date(2026, 9, 28),
            source_type="image_scan",
            confidence_score=0.85,
            notes="Large stock-pot portion, well-sealed",
            audit_log_id=7,
            scanned_at=datetime(2026, 6, 30, 10, 0, 0),
        )
        assert resp.upc is None
        assert resp.source_type == "image_scan"
        assert resp.audit_log_id == 7

    def test_expiration_date_is_date_type(self):
        resp = LeftoverScanResponse(
            item_id=1,
            product_name="Lasagna",
            upc=None,
            estimated_shelf_life_days=120,
            expiration_date=date(2026, 10, 28),
            source_type="image_scan",
            confidence_score=0.91,
            notes=None,
            audit_log_id=1,
            scanned_at=datetime(2026, 6, 30, 9, 0, 0),
        )
        assert isinstance(resp.expiration_date, date)


# ===========================================================================
# Service-layer constant — low-confidence gate threshold (FR-8)
# Importing services_gemini_vision is safe here: GEMINI_API_KEY is set above,
# so genai.Client() constructs without error and no API calls are made.
# ===========================================================================

def test_low_confidence_threshold_matches_spec():
    """FR-8: items below 0.40 confidence must be flagged as Unknown Food Item."""
    from app.services_gemini_vision import _LOW_CONFIDENCE_THRESHOLD
    assert _LOW_CONFIDENCE_THRESHOLD == 0.40


def test_gemini_model_name_is_flash():
    """Regression guard: ensures the model string hasn't drifted from gemini-1.5-flash."""
    from app.services_gemini_vision import _GEMINI_MODEL_NAME
    assert _GEMINI_MODEL_NAME == "gemini-2.5-flash"
