-- Freezer Penguin 0.1 inventory mutation migration
-- Apply after 001_households.sql and after taking a database backup.
-- This stores names for manual and vision-scanned items without a UPC.
ALTER TABLE inventory_items
    ADD COLUMN product_name VARCHAR(255) NULL;
