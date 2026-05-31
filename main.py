import os
from fastapi import FastAPI, HTTPException
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

# Load the connection string from your local .env file
load_dotenv()

app = FastAPI(title="Freezer Penguin API")

# Initialize the database engine pointing over the Tailscale tunnel
DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL not found in environment variables")

engine = create_engine(DATABASE_URL)

@app.get("/")
def read_root():
    return {"status": "Freezer Penguin API is online and healthy"}

@app.get("/categories")
def get_categories():
    """Queries your remote Proxmox MySQL database and pulls your seeded categories"""
    try:
        with engine.connect() as connection:
            # Execute a clean SQL statement against your server
            result = connection.execute(text("SELECT * FROM categories"))
            
            # Map the database rows into a clean array format
            categories = [{"category_id": row[0], "category_name": row[1]} for row in result]
            return {"categories": categories}
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database connection failed: {str(e)}")
    
from pydantic import BaseModel, Field
from datetime import date

# 1. Update the schema model to reflect your exact database structure
class InventoryItemCreate(BaseModel):
    user_id: int = Field(..., example=1)
    quantity: int = Field(..., example=1)
    expiration_date: date = Field(..., example="2026-06-15")
    upc: str = Field(..., example="012345678910")  # Maps to your UPC column
    location_id: int = Field(..., example=1)
    unit_id: int = Field(..., example=1)

# 2. Update the query syntax to match your columns exactly
@app.post("/inventory/add", status_code=201)
def add_inventory_item(item: InventoryItemCreate):
    """Checks for the UPC parent row, handles missing barcodes, and adds the item safely."""
    try:
        with engine.connect() as connection:
            # 1. Check if the barcode already exists in barcode_master
            check_upc = connection.execute(
                text("SELECT UPC FROM barcode_master WHERE UPC = :upc"), 
                {"upc": item.upc}
            ).fetchone()
            
            # 2. If it's a completely new barcode, seed it dynamically into the parent table first
            if not check_upc:
                connection.execute(
                    text("""
                        INSERT INTO barcode_master (UPC, product_name, brand, default_shelf_life, category_id)
                        VALUES (:upc, 'Unknown Presentation Item', 'Test Brand', 7, 1)
                    """),
                    {"upc": item.upc}
                )
            
            # 3. Now insert safely into inventory_items without breaking the foreign key constraint
            query = text("""
                INSERT INTO inventory_items (user_id, quantity, expiration_date, UPC, location_id, unit_id)
                VALUES (:user_id, :quantity, :expiration_date, :upc, :location_id, :unit_id)
            """)
            
            connection.execute(query, {
                "user_id": item.user_id,
                "quantity": item.quantity,
                "expiration_date": item.expiration_date,
                "upc": item.upc,
                "location_id": item.location_id,
                "unit_id": item.unit_id
            })
            
            connection.commit()
            return {"status": "success", "message": f"Barcode {item.upc} verified and item logged successfully!"}
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database write failure: {str(e)}")
            