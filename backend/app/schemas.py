from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

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
        # Tells Pydantic to read database ORM objects (like SQLAlchemy) gracefully later
        from_attributes = True