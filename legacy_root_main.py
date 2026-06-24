import os
import httpx
from fastapi import FastAPI, HTTPException
from sqlalchemy import create_engine, text
from dotenv import load_dotenv
from pydantic import BaseModel, Field, field_validator
from datetime import date, datetime

from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware

# Load the connection string from your local .env file
load_dotenv()

# Initialize the database engine pointing over the Tailscale tunnel
DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL not found in environment variables")

engine = create_engine(DATABASE_URL)

# Single FastAPI instance initialization
app = FastAPI(title="Freezer Penguin API")

# Mount CORS middleware so your frontend can talk across open network ports safely
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows standard browser connections from any testing host origin
    allow_credentials=True,
    allow_methods=["*"],  # Permits GET, POST, OPTIONS operations
    allow_headers=["*"],
)

def calculate_default_shelf_life(category_name: str) -> int:
    """
    Analyzes the Open Food Facts category name string and dynamically
    returns a realistic shelf life in days based on food safety guidelines.
    """
    cat = category_name.lower()
    
    if any(keyword in cat for keyword in ["canned", "can", "dried", "dry", "rice", "pasta", "beans", "honey", "spices"]):
        return 365
    elif any(keyword in cat for keyword in ["frozen", "ice cream", "pizza", "sorbet", "freezer"]):
        return 120
    elif any(keyword in cat for keyword in ["cheese", "butter", "sauce", "condiment", "jam", "pickled"]):
        return 45
    elif any(keyword in cat for keyword in ["meat", "poultry", "chicken", "beef", "pork", "fish", "seafood", "milk", "yogurt", "eggs"]):
        return 14
    elif any(keyword in cat for keyword in ["fresh", "vegetable", "fruit", "salad", "berry", "berries", "bread", "bakery"]):
        return 7
    return 30


# Advanced Pydantic Validations Model
class InventoryItemCreate(BaseModel):
    user_id: int = Field(..., gt=0, description="The parent identifier of the user asset tracking this item", json_schema_extra={"example": 1})
    quantity: int = Field(..., gt=0, description="In-stock quantity pool must be a non-zero positive integer", json_schema_extra={"example": 1})
    expiration_date: date = Field(..., description="Target expiration date metric window", json_schema_extra={"example": "2026-06-15"})
    upc: str = Field(..., min_length=8, max_length=14, pattern=r"^\d+$", description="Global standard barcode payload format", json_schema_extra={"example": "012345678910"})
    location_id: int = Field(..., gt=0, description="Structural key pointer indicating storage compartment placement", json_schema_extra={"example": 1})
    unit_id: int = Field(..., gt=0, description="Structural key mapping index to item package type", json_schema_extra={"example": 1})

    @field_validator("expiration_date")
    @classmethod
    def validate_realistic_expiration_year(cls, value: date) -> date:
        """
        Enforces that the expiration timeline stays realistic. Keeps users from 
        accidentally tracking items with a year like 1026 or 9026.
        """
        current_year = datetime.now().year
        max_valid_year = current_year + 50  # Enforces a realistic 50-year maximum ceiling
        min_valid_year = current_year - 5   # Allows registering up to 5-year past-due items
        
        if value.year > max_valid_year or value.year < min_valid_year:
            raise ValueError(f"Expiration date year ({value.year}) falls outside realistic cold-storage limits ({min_valid_year}-{max_valid_year}).")
        return value


@app.get("/categories")
def get_categories():
    """Queries your remote Proxmox MySQL database and pulls your seeded categories"""
    try:
        with engine.connect() as connection:
            result = connection.execute(text("SELECT * FROM categories"))
            categories = [{"category_id": row[0], "category_name": row[1]} for row in result]
            return {"categories": categories}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database connection failed: {str(e)}")


@app.post("/inventory/add", status_code=201)
async def add_inventory_item(item: InventoryItemCreate):
    """
    Checks for the UPC parent row locally. On a cache miss, it fetches real 
    food properties from Open Food Facts, maps the category dynamically, 
    and logs it cleanly into MySQL.
    """
    try:
        with engine.connect() as connection:
            check_upc = connection.execute(
                text("SELECT UPC FROM barcode_master WHERE UPC = :upc"), 
                {"upc": item.upc}
            ).fetchone()
            
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
                        
                        tags = product_data.get("categories_tags", [])
                        if tags:
                            category_name = tags[0].replace("en:", "").replace("-", " ").title()

                cat_check = connection.execute(
                    text("SELECT category_id FROM categories WHERE category_name = :name"),
                    {"name": category_name}
                ).fetchone()
                
                if cat_check:
                    category_id = cat_check[0]
                else:
                    new_cat = connection.execute(
                        text("INSERT INTO categories (category_name) VALUES (:name)"),
                        {"name": category_name}
                    )
                    category_id = new_cat.lastrowid

                smart_shelf_life = calculate_default_shelf_life(category_name)

                connection.execute(
                    text("""
                        INSERT INTO barcode_master (UPC, product_name, brand, default_shelf_life, category_id)
                        VALUES (:upc, :name, :brand, :shelf_life, :cat_id)
                    """),
                    {
                        "upc": item.upc,
                        "name": product_name,
                        "brand": brand_name,
                        "shelf_life": smart_shelf_life,
                        "cat_id": category_id
                    }
                )
            
            query = text("""
                INSERT INTO inventory_items (user_id, quantity, expiration_date, UPC, location_id, unit_id)
                VALUES (:user_id, :quantity, :expiration_date, :upc, :location_id, :unit_id)
                ON DUPLICATE KEY UPDATE quantity = quantity + VALUES(quantity)
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


@app.get("/inventory/expiring/{user_id}")
def get_expiring_items(user_id: int, limit: int = 5):
    """
    Queries the inventory for a specific user and returns items 
    sorted by the closest expiration date.
    """
    try:
        with engine.connect() as connection:
            query = text("""
                SELECT 
                    us.user_id, us.email, i.item_id, b.product_name, b.brand, 
                    c.category_name, i.quantity, un.unit_name, sl.location_name, 
                    i.expiration_date, DATEDIFF(i.expiration_date, CURDATE()) AS days_remaining,
                    CASE
                        WHEN (DATEDIFF(i.expiration_date, CURDATE()) < 0) THEN 'Expired'
                        WHEN (DATEDIFF(i.expiration_date, CURDATE()) < 3) THEN 'Critical'
                        WHEN (DATEDIFF(i.expiration_date, CURDATE()) < 7) THEN 'Soon'
                        WHEN (DATEDIFF(i.expiration_date, CURDATE()) < 30) THEN 'Good'
                        ELSE 'SAFE'
                    END AS status_urgency
                FROM inventory_items AS i
                JOIN storage_locations AS sl ON sl.location_id = i.location_id
                JOIN barcode_master AS b ON i.UPC = b.UPC
                JOIN categories AS c ON c.category_id = b.category_id
                JOIN Units AS un ON un.unit_id = i.unit_id
                JOIN Users as us ON i.user_id = us.user_id
                WHERE us.user_id = :user_id AND i.quantity > 0
                ORDER BY days_remaining
                
            """)
            
            result = connection.execute(query, {"user_id": user_id, "limit": limit})
            expiring_items = []
            user_email = "Unknown"
            
            for row in result:
                user_email = row.email
                expiring_items.append({
                    "item_id": row.item_id,
                    "product_name": row.product_name,
                    "brand": row.brand,
                    "category_name": row.category_name,
                    "quantity": row.quantity,
                    "unit_name": row.unit_name,
                    "location_name": row.location_name,
                    "expiration_date": str(row.expiration_date),
                    "days_remaining": row.days_remaining,
                    "status_urgency": row.status_urgency  
                })
                
            return {
                "user_id": user_id,
                "email": user_email,                     
                "total_alerts": len(expiring_items),
                "items": expiring_items
            }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch expiring inventory: {str(e)}")

# Mount the static site handler at the absolute bottom
app.mount("/", StaticFiles(directory=".", html=True), name="static")