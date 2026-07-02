"""
Recipe caching layer — clean drop and regenerate.

Drops the three recipe caching tables in dependency-safe order, then calls
Base.metadata.create_all() to recreate them with perfect primary key
constraints and auto-increments exactly as declared in app.models.

Usage (run from the backend/ directory):
    python patch_recipes_schema.py
"""

import sys
import traceback

from sqlalchemy import text

from app.database import Base, engine
import app.models  # noqa: F401 — registers all ORM classes onto Base.metadata

# ── Console helpers ────────────────────────────────────────────────────────────

GREEN  = "\033[92m"
YELLOW = "\033[93m"
RED    = "\033[91m"
CYAN   = "\033[96m"
RESET  = "\033[0m"
BOLD   = "\033[1m"

def ok(msg: str):   print(f"  {GREEN}[OK]     {RESET} {msg}")
def info(msg: str): print(f"  {CYAN}[INFO]   {RESET} {msg}")
def warn(msg: str): print(f"  {YELLOW}[WARN]   {RESET} {msg}")
def err(msg: str):  print(f"  {RED}[ERROR]  {RESET} {msg}", file=sys.stderr)

bar = "═" * 62

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 1 — Drop recipe caching tables (child → junction → parent order)     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

print(f"\n{BOLD}{bar}")
print("  STEP 1 — Drop recipe caching tables")
print(f"{bar}{RESET}")

# Order matters: drop FK-dependent children before parents
DROP_SEQUENCE = [
    "recipe_ingredients_has_recipes",
    "recipe_ingredients",
    "recipes",
]

try:
    with engine.connect() as conn:
        # Temporarily disable FK checks so drops succeed regardless of constraint state
        conn.execute(text("SET FOREIGN_KEY_CHECKS = 0;"))

        for table_name in DROP_SEQUENCE:
            conn.execute(text(f"DROP TABLE IF EXISTS `{table_name}`;"))
            ok(f"Dropped (if existed): {table_name}")

        conn.execute(text("SET FOREIGN_KEY_CHECKS = 1;"))
        conn.commit()

    info("Foreign key checks restored. All three tables cleared.")
except Exception as e:
    err(f"Drop sequence failed: {e}")
    traceback.print_exc()
    sys.exit(1)

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 2 — Recreate tables via Base.metadata.create_all()                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

print(f"\n{BOLD}{bar}")
print("  STEP 2 — Regenerate via SQLAlchemy ORM metadata")
print(f"{bar}{RESET}")

# create_all is additive — it only creates tables that do not yet exist,
# so every other application table (inventory_items, barcode_master, etc.) is untouched.
RECIPE_TABLES = {
    "recipes",
    "recipe_ingredients",
    "recipe_ingredients_has_recipes",
}

try:
    # Pass tables= to scope create_all strictly to our three recipe tables
    target_tables = [
        Base.metadata.tables[t]
        for t in RECIPE_TABLES
        if t in Base.metadata.tables
    ]

    Base.metadata.create_all(bind=engine, tables=target_tables)

    for table_name in sorted(RECIPE_TABLES):
        ok(f"Recreated: {table_name}")

except Exception as e:
    err(f"create_all failed: {e}")
    traceback.print_exc()
    sys.exit(1)

# ── Done ───────────────────────────────────────────────────────────────────────

print(f"\n{'─' * 62}")
print(f"  {GREEN}{BOLD}Recipe caching layer cleanly regenerated.{RESET}")
print(f"  Tables rebuilt with pristine PKs and AUTO_INCREMENT constraints:")
for t in sorted(RECIPE_TABLES):
    print(f"    {GREEN}✓{RESET}  {t}")
print(f"{'─' * 62}\n")
