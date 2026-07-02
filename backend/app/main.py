"""
Freezer Penguin Intelligent Stewardship API — application entry point.

Startup sequence:
    1. SQLAlchemy create_all — ensure ORM-managed tables exist in MySQL.
    2. Mount CORSMiddleware.
    3. Register all feature routers under the /api/v1 versioned prefix.

Gemini API key:
    The google-genai SDK client (genai.Client()) is instantiated at module
    level in services_gemini_vision.py and reads GEMINI_API_KEY directly from
    the environment. No genai.configure() call is required or permitted here.
    A startup guard below validates the key is present before the app accepts
    any requests — this ensures a clear RuntimeError at launch rather than a
    cryptic 503 on the first vision request.
"""

import logging
import os

from dotenv import load_dotenv

# ---------------------------------------------------------------------------
# Load .env FIRST — before any app module import that reads env vars.
#
# Explicit absolute path resolved from __file__ (backend/app/.env) guarantees
# the correct file is loaded regardless of which working directory Uvicorn is
# launched from (e.g. backend/, project root, etc.).
# load_dotenv() is idempotent: re-calling it never clears already-set vars.
# ---------------------------------------------------------------------------
load_dotenv(dotenv_path=os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env"))

from fastapi import FastAPI  # noqa: E402
from fastapi.middleware.cors import CORSMiddleware  # noqa: E402

from app.database import engine  # noqa: E402
from app import models  # noqa: E402
from app.routers_inventory import router as inventory_router  # noqa: E402
from app.routers_vision_ingestion import router as vision_router  # noqa: E402
from app.routers_recipes import router as recipes_router  # noqa: E402

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Startup guard: validate GEMINI_API_KEY is present in the environment.
# genai.Client() in services_gemini_vision.py reads this variable directly —
# if it is absent the client raises an error when it first processes a request.
# Checking here gives a clean fail-fast RuntimeError at server boot instead.
# ---------------------------------------------------------------------------
if not os.getenv("GEMINI_API_KEY"):
    raise RuntimeError(
        "GEMINI_API_KEY environment variable is missing. "
        "Add it to backend/.env before starting the server."
    )

# ---------------------------------------------------------------------------
# SQLAlchemy metadata sync
# create_all is additive — tables already present in MySQL are skipped.
# ---------------------------------------------------------------------------
models.Base.metadata.create_all(bind=engine)
logger.info("SQLAlchemy metadata sync complete — all ORM tables confirmed or created")

# ---------------------------------------------------------------------------
# FastAPI application
# ---------------------------------------------------------------------------
app = FastAPI(
    title="Freezer Penguin Intelligent Stewardship API",
    description=(
        "REST API platform handling intelligent freezer inventory tracking "
        "via barcode ingestion (Feature 1.1), Gemini Vision leftover "
        "ingestion (Feature 1.2), inventory fetch (Feature 1.0), and "
        "expiration-driven recipe suggestions (Feature 1.3)."
    ),
    version="1.3.0",
)

# ---------------------------------------------------------------------------
# CORS middleware
# Mounted immediately after app creation and before any router so the
# preflight OPTIONS response is handled at the middleware layer.
#
# NOTE: allow_origins=["*"] and allow_credentials=True cannot be combined —
# the CORS spec forbids it and browsers will block such responses regardless
# of server config. Credentials must travel via Authorization header tokens.
# Replace the wildcard with explicit origins when moving to production.
# ---------------------------------------------------------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# Router registration — all feature routers under /api/v1
# ---------------------------------------------------------------------------
app.include_router(inventory_router, prefix="/api/v1")
app.include_router(vision_router, prefix="/api/v1")
app.include_router(recipes_router, prefix="/api/v1")


@app.get("/", tags=["Health"])
def health_check():
    return {
        "status": "online",
        "system": "Freezer Penguin Backend Platform",
        "version": "1.3.0",
        "features_active": [
            "1.0 Inventory Fetch",
            "1.1 Barcode Ingestion",
            "1.2 Gemini Vision Ingestion",
            "1.3 Recipe Suggestions Engine",
        ],
    }
