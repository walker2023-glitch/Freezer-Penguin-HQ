import os
import httpx
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    print("❌ Error: DATABASE_URL not found in .env file.")
    exit(1)

engine = create_engine(DATABASE_URL)

def calculate_shelf_life(category: str) -> int:
    cat = category.lower()
    if any(k in cat for k in ["canned", "can", "dried", "dry", "rice", "pasta", "beans", "spices"]): return 365
    if any(k in cat for k in ["frozen", "ice cream", "pizza", "sorbet", "freezer"]): return 120
    if any(k in cat for k in ["cheese", "butter", "sauce", "condiment", "jam", "pickled"]): return 45
    if any(k in cat for k in ["meat", "poultry", "chicken", "beef", "pork", "fish", "milk", "eggs"]): return 14
    if any(k in cat for k in ["fresh", "vegetable", "fruit", "salad", "berry", "bread", "bakery"]): return 7
    return 30

def fetch_and_cache_upc(upc_string: str):
    """Fetches product details from the web and inserts them directly into barcode_master."""
    print(f"🔍 Checking local cache for barcode: {upc_string}...")
    
    with engine.connect() as conn:
        # Check if it already exists
        existing = conn.execute(
            text("SELECT product_name FROM barcode_master WHERE UPC = :upc"), 
            {"upc": upc_string}
        ).fetchone()
        
        if existing:
            print(f"✅ Item already indexed locally: '{existing[0]}'")
            return

        print(f"🌐 Cache Miss! Fetching metadata from Open Food Facts API...")
        api_url = f"https://world.openfoodfacts.org/api/v2/product/{upc_string}.json"
        
        try:
            with httpx.Client() as client:
                response = client.get(api_url, timeout=6.0)
            
            if response.status_code != 200:
                print(f"❌ Failed to connect to API. Status code: {response.status_code}")
                return
                
            api_data = response.json()
            if api_data.get("status") != 1:
                print(f"❌ Barcode {upc_string} not found in the global Open Food Facts registry.")
                return
                
            product_data = api_data.get("product", {})
            product_name = product_data.get("product_name", "Unknown Food Item")
            brand_name = product_data.get("brands", "Generic")
            category_name = "General"
            
            tags = product_data.get("categories_tags", [])
            if tags:
                category_name = tags[0].replace("en:", "").replace("-", " ").title()
            
            # Check or insert category row
            cat_check = conn.execute(
                text("SELECT category_id FROM categories WHERE category_name = :name"),
                {"name": category_name}
            ).fetchone()
            
            if cat_check:
                category_id = cat_check[0]
            else:
                new_cat = conn.execute(
                    text("INSERT INTO categories (category_name) VALUES (:name)"),
                    {"name": category_name}
                )
                category_id = new_cat.lastrowid

            shelf_life = calculate_shelf_life(category_name)

            # Insert raw item properties into master catalog database
            conn.execute(
                text("""
                    INSERT INTO barcode_master (UPC, product_name, brand, default_shelf_life, category_id)
                    VALUES (:upc, :name, :brand, :shelf_life, :cat_id)
                """),
                {
                    "upc": upc_string,
                    "name": product_name,
                    "brand": brand_name,
                    "shelf_life": shelf_life,
                    "cat_id": category_id
                }
            )
            conn.commit()
            print(f"🎉 Success! Cached into database: {product_name} ({brand_name})")
            
        except Exception as e:
            print(f"❌ Automation Error: {str(e)}")

if __name__ == "__main__":
    # Test it with a real-world UPC string (e.g., standard snack food item)
    test_upc = "041196910719" 
    fetch_and_cache_upc(test_upc)