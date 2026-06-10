import os
import httpx  # Placed perfectly at the top
from fastapi import FastAPI, HTTPException
from sqlalchemy import create_engine, text
from dotenv import load_dotenv
from pydantic import BaseModel, Field
from datetime import date

from fastapi.staticfiles import StaticFiles

from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Freezer Penguin API")

# Mount CORS middleware so your frontend can talk across open network ports safely
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows standard browser connections from any testing host origin
    allow_credentials=True,
    allow_methods=["*"],  # Permits GET, POST, OPTIONS operations
    allow_headers=["*"],
)

# Load the connection string from your local .env file
load_dotenv()

app = FastAPI(title="Freezer Penguin API")

def calculate_default_shelf_life(category_name: str) -> int:
    """
    Analyzes the Open Food Facts category name string and dynamically
    returns a realistic shelf life in days based on standard food safety guidelines.
    """
    # Convert to lowercase so matching isn't broken by capitalization variations
    cat = category_name.lower()
    
    # 1. Ultra long-term stable items (1-2+ years)
    if any(keyword in cat for keyword in ["canned", "can", "dried", "dry", "rice", "pasta", "beans", "honey", "spices"]):
        return 365
        
    # 2. Standard Frozen Items (3 to 6 months)
    elif any(keyword in cat for keyword in ["frozen", "ice cream", "pizza", "sorbet", "freezer"]):
        return 120
        
    # 3. Hardy Dairy & Condiments (1 to 2 months)
    elif any(keyword in cat for keyword in ["cheese", "butter", "sauce", "condiment", "jam", "pickled"]):
        return 45
        
    # 4. Standard Refrigerator Staples / Fresh Meat (1 to 2 weeks)
    elif any(keyword in cat for keyword in ["meat", "poultry", "chicken", "beef", "pork", "fish", "seafood", "milk", "yogurt", "eggs"]):
        return 14
        
    # 5. High-perishables / Fresh Produce (3 to 7 days)
    elif any(keyword in cat for keyword in ["fresh", "vegetable", "fruit", "salad", "berry", "berries", "bread", "bakery"]):
        return 7
        
    # 6. Fallback default if the category string is vague or generic
    return 30


# Initialize the database engine pointing over the Tailscale tunnel
DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL not found in environment variables")

engine = create_engine(DATABASE_URL)

#@app.get("/")
#def read_root():
#    return {"status": "Freezer Penguin API is online and healthy"}

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
    

# Update the schema model to reflect your exact database structure
class InventoryItemCreate(BaseModel):
    user_id: int = Field(..., example=1)
    quantity: int = Field(..., example=1)
    expiration_date: date = Field(..., example="2026-06-15")
    upc: str = Field(..., example="012345678910")  # Maps to your UPC column
    location_id: int = Field(..., example=1)
    unit_id: int = Field(..., example=1)


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

                # 4. Save to master database cache using our dynamic smart shelf-life tracker
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
                        "shelf_life": smart_shelf_life,  # <-- Activated dynamic tracking!
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
    

@app.get("/inventory/expiring/{user_id}")
def get_expiring_items(user_id: int, limit: int = 5):
        """
        Queries the inventory for a specific user and returns items 
        sorted by the closest expiration date. This drives the 
        'Eat This First' safety dashboard.
        """
        try:
            with engine.connect() as connection:
                query = text("""
                    SELECT 
                        us.user_id, 
                        us.email, 
                        i.item_id, 
                        b.product_name, 
                        b.brand, 
                        c.category_name, 
                        i.quantity, 
                        un.unit_name, 
                        sl.location_name, 
                        i.expiration_date, 
                        DATEDIFF(i.expiration_date, CURDATE()) AS days_remaining,
                        CASE
                            WHEN (DATEDIFF(i.expiration_date, CURDATE()) < 0) THEN 'Expired'
                            WHEN (DATEDIFF(i.expiration_date, CURDATE()) < 3) THEN 'Critical'
                            WHEN (DATEDIFF(i.expiration_date, CURDATE()) < 7) THEN 'Soon'
                            WHEN (DATEDIFF(i.expiration_date, CURDATE()) < 30) THEN 'Good'
                            ELSE 'SAFE'
                        END AS status_urgency
                    FROM inventory_items AS i
                    JOIN storage_locations AS sl
                        ON sl.location_id = i.location_id
                    JOIN barcode_master AS b
                        ON i.UPC = b.UPC
                    JOIN categories AS c
                        ON c.category_id = b.category_id  -- Fixed: Added missing ON keyword
                    JOIN Units AS un
                        ON un.unit_id = i.unit_id
                    JOIN Users as us
                        ON i.user_id = us.user_id
                    WHERE i.user_id = :user_id AND i.quantity > 0  -- Filter logic
                    ORDER BY days_remaining
                    LIMIT :limit
                    """)
                
                result = connection.execute(query, {"user_id": user_id, "limit": limit})
                
                expiring_items = []
                user_email = "Unknown"
                
                for row in result:
                    # Capture the email from the first available record row
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
        


# Place this at the bottom of main.py, BELOW your @app.get and @app.post routes
app.mount("/", StaticFiles(directory=".", html=True), name="static")