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