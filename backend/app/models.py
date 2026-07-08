from sqlalchemy import (
    BigInteger, Boolean, Column, Date, DateTime,
    ForeignKey, Integer, Numeric, String, Text,
)
from app.database import Base


class DBCategory(Base):
    """
    ORM mapping for the `categories` reference table.
    Used by the barcode ingestion router to validate the category FK
    before writing to barcode_master.
    """
    __tablename__ = "categories"

    category_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    category_name = Column(String(50), nullable=False)


class DBBarcodeMaster(Base):
    """
    ORM mapping for the `barcode_master` reference catalog.

    This table is populated on cache-miss by the Open Food Facts service and
    treated as read-only for all other application code (see SKILL.md FR-10).

    Live DDL primary key: UPC (VARCHAR 15) — sole single-column PK.
    """
    __tablename__ = "barcode_master"

    UPC = Column(String(15), primary_key=True, index=True)
    product_name = Column(String(100), nullable=False)
    brand = Column(String(100), nullable=True)
    default_shelf_life = Column(Integer, nullable=True)
    category_id = Column(
        Integer,
        ForeignKey("categories.category_id"),
        nullable=False,
    )


class DBUser(Base):
    """
    Full ORM mapping for the `Users` table.

    GR-2: user_id is the sole auto-increment primary key.
    All other columns are nullable per the live DDL to support
    partial inserts (e.g. OAuth users with no password hash).
    Feature 2.0 authentication reads/writes this model directly.
    """
    __tablename__ = "Users"

    user_id = Column(Integer, primary_key=True, autoincrement=True)  # GR-2: sole PK
    email = Column(String(255), nullable=False, unique=True, index=True)
    hashed_password = Column(String(255), nullable=True)
    tier_status = Column(String(10), nullable=True)   # 'Basic' | 'Premium'
    created_at = Column(DateTime, nullable=True)
    total_spent = Column(Numeric(10, 2), nullable=True)
    lifetime_item_count = Column(Integer, nullable=True)
    current_item_count = Column(Integer, nullable=True)
    total_food_wasted = Column(Integer, nullable=True)
    total_food_wasted_cost = Column(Numeric(10, 2), nullable=True)


class DBStorageLocation(Base):
    """
    ORM shell for the `storage_locations` reference table.

    Declared so SQLAlchemy's relationship mapper can resolve the FK defined on
    inventory_items.location_id → storage_locations.location_id.
    """
    __tablename__ = "storage_locations"

    location_id = Column(Integer, primary_key=True, autoincrement=True)


class DBUnit(Base):
    """
    ORM shell for the `Units` reference table.

    Declared so SQLAlchemy's relationship mapper can resolve the FK defined on
    inventory_items.unit_id → Units.unit_id.
    """
    __tablename__ = "Units"

    unit_id = Column(Integer, primary_key=True, autoincrement=True)


class DBInventoryItem(Base):
    """
    ORM mapping for the `inventory_items` transaction ledger.

    GUARDRAIL GR-1: UPC is explicitly nullable=True. This column MUST NEVER be
    set to nullable=False. Raw leftover items (Feature 1.2) have no UPC.

    GUARDRAIL GR-2: item_id is declared as the sole Python-side primary key.
    The live MySQL DDL carries a composite PK of (item_id, user_id, unit_id) as
    a legacy constraint. item_id is auto-increment and unique; all application
    queries and ORM identity resolution use it exclusively.
    """
    __tablename__ = "inventory_items"

    item_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("Users.user_id"), nullable=False)
    quantity = Column(Integer, nullable=True, default=1)
    expiration_date = Column(Date, nullable=False, index=True)
    UPC = Column(
        String(15),
        ForeignKey("barcode_master.UPC"),
        nullable=True,   # GR-1: must remain nullable
        index=True,
    )
    location_id = Column(
        Integer,
        ForeignKey("storage_locations.location_id"),
        nullable=False,
    )
    unit_id = Column(Integer, ForeignKey("Units.unit_id"), nullable=False)
    is_consumed = Column(
        Boolean,
        nullable=True,   # nullable=True is non-breaking for rows pre-dating this column
        default=False,
        index=True,
    )


class DBRecipe(Base):
    """
    ORM mapping for the `recipes` cache table — Feature 1.3 (Recipe Engine).

    Rows are inserted via a spoonacular_id-based upsert pattern so repeated
    calls for the same ingredient set never duplicate records. gemini_rank and
    gemini_safety_approved are updated in the same atomic commit after the
    Gemini ranking step (FR-8, FR-10).
    """
    __tablename__ = "recipes"

    recipe_id = Column(Integer, primary_key=True, autoincrement=True)
    spoonacular_id = Column(Integer, nullable=False, unique=True, index=True)
    title = Column(String(500), nullable=False)
    image_url = Column(Text, nullable=True)
    source_url = Column(Text, nullable=True)
    ready_in_minutes = Column(Integer, nullable=True)
    servings = Column(Integer, nullable=True)
    gemini_safety_approved = Column(Boolean, nullable=False, default=False)
    gemini_rank = Column(Integer, nullable=True, index=True)
    cached_at = Column(DateTime, nullable=False)


class DBRecipeIngredient(Base):
    """
    ORM mapping for the `recipe_ingredients` table — Feature 1.3.

    One row per ingredient per recipe. item_id is nullable (SET NULL on delete)
    so the match record survives even if the linked inventory item is consumed.
    is_matched_to_inventory=True only when the ingredient name fuzzy-matches a
    live barcode_master.product_name for this user.
    """
    __tablename__ = "recipe_ingredients"

    id = Column(Integer, primary_key=True, autoincrement=True)
    recipe_id = Column(
        Integer,
        ForeignKey("recipes.recipe_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    item_id = Column(
        Integer,
        ForeignKey("inventory_items.item_id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    ingredient_name = Column(String(255), nullable=False)
    spoonacular_ingredient_id = Column(Integer, nullable=True)
    is_matched_to_inventory = Column(Boolean, nullable=False, default=False)


class DBRecipeHasIngredient(Base):
    """
    ORM shell for the `recipe_ingredients_has_recipes` legacy join table.

    Declared so SQLAlchemy's MetaData registry resolves any FK references
    to this table without raising NoReferencedTableError at startup. Only
    FK columns and an auto-increment surrogate PK are mapped here — the exact
    composite-key DDL is deferred pending SHOW CREATE TABLE confirmation.
    """
    __tablename__ = "recipe_ingredients_has_recipes"

    id = Column(Integer, primary_key=True, autoincrement=True)
    recipe_ingredients_id = Column(
        Integer,
        ForeignKey("recipe_ingredients.id", ondelete="CASCADE"),
        nullable=True,
    )
    recipes_recipe_id = Column(
        Integer,
        ForeignKey("recipes.recipe_id", ondelete="CASCADE"),
        nullable=True,
    )


class DBAIAuditLog(Base):
    """
    ORM mapping for the `ai_audit_logs` append-only audit table.

    Every Gemini Vision inference call writes exactly one row here (SKILL.md §4.4).
    This table MUST NOT be queried, updated, or deleted by application code — it
    is an immutable observability record.

    Live DDL:
        log_id              BIGINT AUTO_INCREMENT PK
        input_prompt        TEXT   NOT NULL  — full system prompt sent to the model
        raw_output          TEXT   NOT NULL  — verbatim model response (truncated to 2000 chars)
        accuracy_coefficient DECIMAL(5,4)   — Gemini confidence_score; nullable if absent
    """
    __tablename__ = "ai_audit_logs"

    log_id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    input_prompt = Column(Text, nullable=False)
    raw_output = Column(Text, nullable=False)
    accuracy_coefficient = Column(Numeric(precision=5, scale=4), nullable=True)
