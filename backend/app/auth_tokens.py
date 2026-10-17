"""Signed, expiring bearer tokens for the apartment proof of concept.

The token is deliberately small and dependency-free: an HMAC-SHA256 signature
protects a base64url JSON payload containing the user ID and expiration time.
The signing secret must be supplied through AUTH_TOKEN_SECRET and is never
logged or returned.
"""

import base64
import hashlib
import hmac
import json
import os
import time
from typing import Any

from fastapi import Depends, Header, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import DBUser

_TOKEN_TTL_SECONDS = 7 * 24 * 60 * 60


def _secret() -> bytes:
    value = os.getenv("AUTH_TOKEN_SECRET")
    if not value:
        raise RuntimeError(
            "AUTH_TOKEN_SECRET environment variable is required for authenticated sessions."
        )
    return value.encode("utf-8")


def _encode(value: bytes) -> str:
    return base64.urlsafe_b64encode(value).rstrip(b"=").decode("ascii")


def _decode(value: str) -> bytes:
    padding = "=" * (-len(value) % 4)
    return base64.urlsafe_b64decode((value + padding).encode("ascii"))


def create_access_token(user_id: int) -> str:
    payload = {
        "sub": str(user_id),
        "exp": int(time.time()) + _TOKEN_TTL_SECONDS,
    }
    body = _encode(json.dumps(payload, separators=(",", ":")).encode("utf-8"))
    signature = _encode(
        hmac.new(_secret(), body.encode("ascii"), hashlib.sha256).digest()
    )
    return f"{body}.{signature}"


def _read_user_id(token: str) -> int:
    try:
        body, signature = token.split(".", maxsplit=1)
        expected = hmac.new(
            _secret(), body.encode("ascii"), hashlib.sha256
        ).digest()
        if not hmac.compare_digest(_decode(signature), expected):
            raise ValueError("signature mismatch")
        payload: dict[str, Any] = json.loads(_decode(body))
        user_id = int(payload["sub"])
        if int(payload["exp"]) <= int(time.time()):
            raise ValueError("token expired")
        if user_id <= 0:
            raise ValueError("invalid subject")
        return user_id
    except (ValueError, KeyError, TypeError, json.JSONDecodeError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired authentication token.",
            headers={"WWW-Authenticate": "Bearer"},
        )


def get_current_user(
    authorization: str | None = Header(default=None),
    db: Session = Depends(get_db),
) -> DBUser:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication is required.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user_id = _read_user_id(authorization[7:].strip())
    user = db.query(DBUser).filter(DBUser.user_id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authenticated user no longer exists.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user
