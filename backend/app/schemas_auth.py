"""
Pydantic v2 schemas for Feature 2.0 — Login & Registration Skeleton.

Three-tier hierarchy per SKILL.md §3.1:
  RegisterRequest / LoginRequest  — inbound payloads
  RegisterResponse / AuthResponse — outbound serialized records
"""

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class RegisterRequest(BaseModel):
    """Payload for POST /auth/register."""

    email: str = Field(
        ...,
        description="Unique user email address",
        json_schema_extra={"example": "penguin@example.com"},
    )
    password: str = Field(
        ...,
        min_length=6,
        description="Plain-text password (minimum 6 characters); hashed before storage",
        json_schema_extra={"example": "s3cr3tP@ss"},
    )


class LoginRequest(BaseModel):
    """Payload for POST /auth/login."""

    email: str = Field(
        ...,
        description="Registered user email address",
        json_schema_extra={"example": "penguin@example.com"},
    )
    password: str = Field(
        ...,
        description="Account password",
        json_schema_extra={"example": "s3cr3tP@ss"},
    )


class RegisterResponse(BaseModel):
    """Response returned by POST /auth/register (HTTP 201)."""

    model_config = ConfigDict(from_attributes=True)

    user_id: int = Field(
        ...,
        description="Auto-increment database primary key (GR-2)",
        json_schema_extra={"example": 1},
    )
    email: str = Field(
        ...,
        description="Registered email address",
        json_schema_extra={"example": "penguin@example.com"},
    )
    created_at: Optional[datetime] = Field(
        None,
        description="Server-generated account creation timestamp",
        json_schema_extra={"example": "2026-07-07T19:00:00"},
    )


class AuthResponse(BaseModel):
    """
    Response returned by POST /auth/login (HTTP 200).

    access_token is a secrets.token_urlsafe(32) placeholder.
    TODO: replace with signed JWT (python-jose) before production.
    """

    model_config = ConfigDict(from_attributes=True)

    user_id: int = Field(
        ...,
        description="Authenticated user primary key",
        json_schema_extra={"example": 1},
    )
    email: str = Field(
        ...,
        description="Authenticated user email",
        json_schema_extra={"example": "penguin@example.com"},
    )
    access_token: str = Field(
        ...,
        description="Bearer token for subsequent authenticated requests",
        json_schema_extra={"example": "xK9mPq3..."},
    )
    token_type: str = Field(
        default="bearer",
        description="OAuth2 token type; always 'bearer'",
        json_schema_extra={"example": "bearer"},
    )
