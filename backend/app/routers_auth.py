"""
Authentication router — Feature 2.0 (Login & Registration Skeleton).

Routes:
    POST /auth/register  → 201 Created
    POST /auth/login     → 200 OK

Password security:
    BCrypt via passlib CryptContext.

Token:
    secrets.token_urlsafe(32) opaque bearer token placeholder.
    TODO: replace with signed JWT (python-jose / RS256) before production.

SKILL.md compliance:
    GR-2  — single auto-increment PK on DBUser (user_id).
    §3.1  — Pydantic v2 response models with from_attributes = True.
    §3.2  — Explicit fastapi.status codes on every route.
    §3.3  — All DB writes wrapped in try/except/rollback via get_db().
    §4.1  — Module-level logger; INFO on success, WARNING/ERROR on failure.
"""

import logging
import secrets
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import DBUser
from app.schemas_auth import (
    AuthResponse,
    LoginRequest,
    RegisterRequest,
    RegisterResponse,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["Authentication"])

# BCrypt context — auto-rehashes deprecated rounds on verify
_pwd = CryptContext(schemes=["bcrypt"], deprecated="auto")


# ---------------------------------------------------------------------------
# POST /auth/register
# ---------------------------------------------------------------------------

@router.post(
    "/register",
    response_model=RegisterResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new user account",
)
def register(
    payload: RegisterRequest,
    db: Session = Depends(get_db),
) -> RegisterResponse:
    logger.info("Registration request — email=%s", payload.email)

    existing = db.query(DBUser).filter(DBUser.email == payload.email).first()
    if existing:
        logger.warning(
            "Registration rejected — duplicate email=%s", payload.email
        )
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"An account with email '{payload.email}' already exists.",
        )

    user = DBUser(
        email=payload.email,
        hashed_password=_pwd.hash(payload.password),
        tier_status="Basic",
        created_at=datetime.now(tz=timezone.utc),
    )
    try:
        db.add(user)
        db.commit()
        db.refresh(user)
        logger.info(
            "DB INSERT complete — Users.user_id=%s email=%s",
            user.user_id,
            user.email,
        )
    except Exception as exc:
        db.rollback()
        logger.error(
            "DB write failed during register — email=%s error=%s",
            payload.email,
            str(exc),
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database write operation failed. Transaction rolled back.",
        )

    return RegisterResponse(
        user_id=user.user_id,
        email=user.email,
        created_at=user.created_at,
    )


# ---------------------------------------------------------------------------
# POST /auth/login
# ---------------------------------------------------------------------------

@router.post(
    "/login",
    response_model=AuthResponse,
    status_code=status.HTTP_200_OK,
    summary="Authenticate a user and return a bearer access token",
)
def login(
    payload: LoginRequest,
    db: Session = Depends(get_db),
) -> AuthResponse:
    logger.info("Login attempt — email=%s", payload.email)

    user = db.query(DBUser).filter(DBUser.email == payload.email).first()

    # Unified failure path — no distinction between "no such user" and "wrong
    # password" to prevent email enumeration attacks.
    if not user or not user.hashed_password or not _pwd.verify(
        payload.password, user.hashed_password
    ):
        logger.warning("Login failed — invalid credentials email=%s", payload.email)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = secrets.token_urlsafe(32)
    logger.info("Login successful — user_id=%s", user.user_id)

    return AuthResponse(
        user_id=user.user_id,
        email=user.email,
        access_token=token,
        token_type="bearer",
    )
