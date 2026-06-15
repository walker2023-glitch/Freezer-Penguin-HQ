import polars as pl
from sqlalchemy import text
from main import engine

def seed_database():
    csv_file = "barcodes_seed.csv"
    print(f"🔄 Reading data using Polars from {csv_file}...")
    
    # 1. Fast load and clean using Polars
    df = pl.read_csv(csv_file)
    df = df.drop_nulls(subset=["UPC", "product_name"])
    df = df.unique(subset=["UPC"])
    df = df.with_columns(pl.col("UPC").cast(pl.Utf8))
    
    total_rows = df.height
    print(f"📋 Found {total_rows} unique barcodes to insert.")
    
    # 2. Define our safe chunk sizes
    chunk_size = 10000
    print(f"🚀 Streaming data in blocks of {chunk_size} items over Tailscale...")
    
    # 3. Step through the dataframe in slices
    with engine.connect() as connection:
        query = text("""
            INSERT IGNORE INTO barcode_master (UPC, product_name, category_id)
            VALUES (:UPC, :product_name, 1)
        """)
        
        for offset in range(0, total_rows, chunk_size):
            # Efficiently slice the Polars frame without copying memory arrays
            chunk_df = df.slice(offset, chunk_size)
            records = chunk_df.select(["UPC", "product_name"]).to_dicts()
            
            # Write this slice to the database
            connection.execute(query, records)
            connection.commit()
            
            processed = min(offset + chunk_size, total_rows)
            print(f"   📥 Progress: {processed}/{total_rows} records synchronized ({int((processed/total_rows)*100)}%)")
            
        print(f"✅ Clean Sweep! All {total_rows} items successfully indexed to barcode_master.")

if __name__ == "__main__":
    seed_database()

    