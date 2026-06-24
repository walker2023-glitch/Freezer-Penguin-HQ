from fastapi import FastAPI, status, Depends, HTTPException
from sqlalchemy.orm import Session
from app.schemas import FoodItemCreate, FoodItemResponse
from app.database import engine, get_db  # <--- Added get_db here
from app import models  
from datetime import datetime

# Command SQLAlchemy to physically build the database tables if they don't exist yet
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Freezer Penguin Intelligent Stewardship API",
    description="REST API platform handling intelligent freezer inventory tracking and telemetry routing.",
    version="1.0.0"
)

@app.get("/")
def read_root():
    return {
        "status": "online", 
        "system": "Freezer Penguin Backend Platform",
        "environment": "Development"
    }

# Updated mock endpoint supporting the UPC string vector
@app.post(
    "/api/v1/items", 
    response_model=FoodItemResponse, 
    status_code=status.HTTP_201_CREATED,
    summary="Validate inbound mobile payload configurations",
    tags=["Inventory Triage"]
)
def test_validate_item(payload: FoodItemCreate):
    """
    Temporary mock endpoint to prove our Pydantic data contract can successfully
    intercept, validate, and serialize incoming data vectors (including barcode keys).
    """
    # Simulates what our database insert sequence will output live
    mock_response = {
        "id": 101,
        "name": payload.name,
        "quantity": payload.quantity,
        "storage_zone": payload.storage_zone,
        "upc": payload.upc,  # Handled cleanly as a nullable string
        "notes": payload.notes,
        "timestamp": datetime.utcnow()
    }
    return mock_response