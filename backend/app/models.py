from sqlalchemy import BigInteger, Column, Integer, Numeric, String, Date, ForeignKey, Text
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
    expiration_date = Column(Date, nullable=False)
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
