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

import httpx  # Put this at the very top of your main.py file

@app.post("/inventory/add", status_code=201)
async def add_inventory_item(item: InventoryItemCreate):
    """
    Checks for the UPC parent row locally. 
    On a cache miss, it fetches real food properties from Open Food Facts,
    maps the category dynamically, and logs it cleanly into MySQL.
    """
    try:
        with engine.connect() as connection:
            # 1. Check if the barcode already exists in your MySQL barcode_master
            check_upc = connection.execute(
                text("SELECT UPC FROM barcode_master WHERE UPC = :upc"), 
                {"upc": item.upc}
            ).fetchone()
            
            # 2. CACHE MISS: Hit Open Food Facts to dynamically learn about the item
            if not check_upc:
                api_url = f"https://world.openfoodfacts.org/api/v2/product/{item.upc}.json"
                
                async with httpx.AsyncClient() as client:
                    response = await client.get(api_url, timeout=5.0)
                
                product_name = 'Unknown Food Item'
                brand_name = 'Generic'
                category_name = 'General'
                
                if response.status_code == 200:
                    api_data = response.json()
                    if api_data.get("status") == 1:
                        product_data = api_data.get("product", {})
                        product_name = product_data.get("product_name", product_name)
                        brand_name = product_data.get("brands", brand_name)
                        
                        # Grab the human-readable English category tag if available
                        tags = product_data.get("categories_tags", [])
                        if tags:
                            category_name = tags[0].replace("en:", "").replace("-", " ").title()

                # 3. Handle Category Alignment
                # Check if the category text exists in your categories table
                cat_check = connection.execute(
                    text("SELECT category_id FROM categories WHERE category_name = :name"),
                    {"name": category_name}
                ).fetchone()
                
                if cat_check:
                    category_id = cat_check[0]
                else:
                    # Seed the new category automatically to satisfy Foreign Key constraints
                    new_cat = connection.execute(
                        text("INSERT INTO categories (category_name) VALUES (:name)"),
                        {"name": category_name}
                    )
                    # For SQLAlchemy/MySQL execution contexts, grab the auto-increment ID
                    category_id = new_cat.lastrowid

                # 4. Save to master database cache so future scans are local and instant
                connection.execute(
                    text("""
                        INSERT INTO barcode_master (UPC, product_name, brand, default_shelf_life, category_id)
                        VALUES (:upc, :name, :brand, :shelf_life, :cat_id)
                    """),
                    {
                        "upc": item.upc,
                        "name": product_name,
                        "brand": brand_name,
                        "shelf_life": 14,  # Standard fallback default days
                        "cat_id": category_id
                    }
                )
            
            # 5. Insert directly into inventory_items safely
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
            return {"status": "success", "message": f"Product synchronized and item logged successfully!"}
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database write failure: {str(e)}")