from pydantic import BaseModel, Field
from typing import Optional
from datetime import date, datetime

class FoodItemBase(BaseModel):
    """
    Core data contract fields shared between inbound creation entries
    and outbound database queries.
    """
    name: str = Field(
        ..., 
        description="The name of the food item being put into storage",
        json_schema_extra={"example": "Wild Caught Salmon"}
    )
    quantity: int = Field(
        default=1, 
        ge=1, 
        description="The total item count (must be 1 or greater)",
        json_schema_extra={"example": 2}
    )
    storage_zone: str = Field(
        ..., 
        description="The location within the freezer unit where the item is kept",
        json_schema_extra={"example": "Deep Freeze (Bottom)"}
    )
    notes: Optional[str] = Field(
        None, 
        description="Optional descriptive parameters or details about the entry",
        json_schema_extra={"example": "Vacuum sealed pack"}
    )
    upc: Optional[str] = Field(
        None,
        description="The optional 12-digit Universal Product Code barcode string",
        json_schema_extra={"example": "012345678912"}
    )

class FoodItemCreate(FoodItemBase):
    """
    Explicit schema model used to validate raw inbound payloads coming 
    straight from the Flutter frontend application.
    """
    pass  # Inherits all fields from FoodItemBase

class FoodItemResponse(FoodItemBase):
    """
    Outbound data contract schema model used to serialize database records 
    back to the client app. Adds server-generated metadata fields.
    """
    id: int = Field(..., description="The unique auto-incrementing database primary key")
    timestamp: datetime = Field(..., description="The date and time the item was logged")

    class Config:
        from_attributes = True


# ---------------------------------------------------------------------------
# Feature 1.1 — Barcode Ingestion schemas
# ---------------------------------------------------------------------------

class BarcodeIngestionResponse(BaseModel):
    """
    Outbound contract returned by POST /api/v1/inventory/barcode/{upc}.

    Combines server-generated inventory_items fields with product metadata
    resolved from barcode_master (which was seeded from Open Food Facts on a
    cache-miss). The `upc` field is Optional per SKILL.md GR-1.
    """

    item_id: int = Field(
        ...,
        description="Auto-increment primary key of the inventory_items row",
        json_schema_extra={"example": 42},
    )
    upc: Optional[str] = Field(
        None,
        description="UPC barcode string stored in inventory_items (nullable per GR-1)",
        json_schema_extra={"example": "012345678912"},
    )
    product_name: str = Field(
        ...,
        description="Product name resolved from barcode_master or Open Food Facts",
        json_schema_extra={"example": "Organic Whole Milk"},
    )
    brand: Optional[str] = Field(
        None,
        description="Brand name from the Open Food Facts product catalog",
        json_schema_extra={"example": "Horizon Organic"},
    )
    quantity: int = Field(
        ...,
        description="Current item count at this location (incremented on upsert)",
        json_schema_extra={"example": 1},
    )
    location_id: int = Field(
        ...,
        description="FK reference to storage_locations.location_id",
        json_schema_extra={"example": 1},
    )
    unit_id: int = Field(
        ...,
        description="FK reference to Units.unit_id",
        json_schema_extra={"example": 1},
    )
    user_id: int = Field(
        ...,
        description="FK reference to Users.user_id",
        json_schema_extra={"example": 1},
    )
    expiration_date: date = Field(
        ...,
        description="Item expiration date (ISO-8601). Computed from default_shelf_life if not supplied.",
        json_schema_extra={"example": "2027-01-01"},
    )
    upserted: bool = Field(
        ...,
        description="True if an existing inventory row was quantity-incremented; False if a new row was inserted",
        json_schema_extra={"example": False},
    )

    class Config:
        from_attributes = True


# ---------------------------------------------------------------------------
# Feature 1.2 — Gemini Vision Leftover Ingestion schemas
# ---------------------------------------------------------------------------

class GeminiVisionResult(BaseModel):
    """
    Internal validation schema for raw Gemini JSON output.

    This model is NEVER returned directly to the HTTP client — it is an
    intermediate contract that validates the model's response before any
    database interaction occurs. Pydantic ValidationError at this layer
    surfaces as HTTP 422 with zero DB writes.

    strict=True ensures Gemini integer fields are not silently coerced from
    strings, which would mask a response format regression.
    """
    model_config = {"strict": True}

    item_name: str = Field(
        ...,
        min_length=1,
        max_length=255,
        strip_whitespace=True,
        description="Most specific food name Gemini can identify",
        json_schema_extra={"example": "Chicken Tikka Masala"},
    )
    estimated_shelf_life_days: int = Field(
        ...,
        ge=1,
        le=3650,
        description="Safe freezer storage duration in days from today",
        json_schema_extra={"example": 90},
    )
    quantity_description: Optional[str] = Field(
        None,
        max_length=100,
        description="Estimated volume or weight, e.g. '2 cups', '500g'",
        json_schema_extra={"example": "2 cups"},
    )
    confidence_score: Optional[float] = Field(
        None,
        ge=0.0,
        le=1.0,
        description="Gemini self-reported identification confidence (0.00–1.00)",
        json_schema_extra={"example": 0.87},
    )
    notes: Optional[str] = Field(
        None,
        max_length=500,
        description="Observations about the container or food state",
        json_schema_extra={"example": "Stored in a glass container with a blue lid"},
    )


class LeftoverScanResponse(BaseModel):
    """
    HTTP 201 response returned by POST /api/v1/inventory/scan-leftover.

    Combines server-generated inventory_items fields (item_id, expiration_date)
    with Gemini-derived fields (product_name, shelf_life, confidence, notes) and
    the audit trail reference (audit_log_id). The upc field is ALWAYS None for
    image_scan items — GR-1 compliance enforced at the route layer.
    """
    item_id: int = Field(
        ...,
        description="Auto-increment PK of the newly created inventory_items row",
        json_schema_extra={"example": 87},
    )
    product_name: str = Field(
        ...,
        description="Food name resolved by Gemini (overridden to 'Unknown Food Item' if confidence < 0.40)",
        json_schema_extra={"example": "Chicken Tikka Masala"},
    )
    upc: Optional[str] = Field(
        None,
        description="Always null for image_scan items — GR-1 architectural guardrail",
        json_schema_extra={"example": None},
    )
    estimated_shelf_life_days: int = Field(
        ...,
        description="Gemini-estimated safe freezer storage duration in days",
        json_schema_extra={"example": 90},
    )
    expiration_date: date = Field(
        ...,
        description="Computed expiration date: date.today() + timedelta(days=estimated_shelf_life_days)",
        json_schema_extra={"example": "2026-09-23"},
    )
    source_type: str = Field(
        default="image_scan",
        description="Hardcoded ingestion source identifier for this endpoint",
        json_schema_extra={"example": "image_scan"},
    )
    confidence_score: Optional[float] = Field(
        None,
        description="Gemini's self-reported identification confidence score",
        json_schema_extra={"example": 0.87},
    )
    notes: Optional[str] = Field(
        None,
        description="Gemini observations about the container or food state",
        json_schema_extra={"example": "Stored in a glass container with a blue lid"},
    )
    audit_log_id: int = Field(
        ...,
        description="FK reference to ai_audit_logs.log_id for this inference event",
        json_schema_extra={"example": 34},
    )
    scanned_at: datetime = Field(
        ...,
        description="Application-side UTC timestamp of the ingestion event",
        json_schema_extra={"example": "2026-06-27T18:00:00"},
    )