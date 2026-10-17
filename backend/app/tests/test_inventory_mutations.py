import os

os.environ.setdefault("DATABASE_URL", "sqlite:///./test_ci.db")

from app.schemas import InventoryItemUpdate, InventoryUseRequest, ManualInventoryCreate  # noqa: E402


def test_manual_inventory_schema_requires_positive_quantity():
    item = ManualInventoryCreate(
        product_name="Milk",
        quantity=2,
        expiration_date="2027-01-01",
        location_id=1,
        unit_id=1,
    )
    assert item.quantity == 2
    assert item.product_name == "Milk"


def test_inventory_mutation_schema_allows_zero_only_for_update():
    update = InventoryItemUpdate(quantity=0)
    use = InventoryUseRequest(quantity=1)
    assert update.quantity == 0
    assert use.quantity == 1
