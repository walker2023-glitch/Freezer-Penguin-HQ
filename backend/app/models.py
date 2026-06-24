from sqlalchemy import Column, Integer, String, DateTime
from datetime import datetime
from app.database import Base  # Import the Base registry we just defined

class DBFoodItem(Base):
    """
    This class instructs SQLAlchemy to build a SQL table named 'inventory_items'
    with columns that perfectly mimic our data properties.
    """
    __tablename__ = "inventory_items"

    # Primary Key: Automatically increments (1, 2, 3...) for every new item
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    
    # Text columns. nullable=False means the database will reject empty entries
    name = Column(String, nullable=False, index=True)
    quantity = Column(Integer, nullable=False, default=1)
    storage_zone = Column(String, nullable=False)
    
    # Nullable columns (equivalent to Optional in Pydantic)
    upc = Column(String, nullable=True, index=True)
    notes = Column(String, nullable=True)
    
    # Timestamp: default=datetime.utcnow tells the server to log the exact save time
    timestamp = Column(DateTime, default=datetime.utcnow, nullable=False)