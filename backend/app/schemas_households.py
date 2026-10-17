"""Pydantic schemas for apartment household membership and session context."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class HouseholdCreateRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=120)


class HouseholdResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    household_id: int
    name: str
    role: str
    created_at: datetime


class HouseholdInviteCreateRequest(BaseModel):
    expires_in_hours: int = Field(default=24, ge=1, le=168)


class HouseholdInviteResponse(BaseModel):
    invite_id: int
    household_id: int
    code: str
    expires_at: datetime


class AcceptInviteResponse(BaseModel):
    household_id: int
    household_name: str
    role: str


class MeResponse(BaseModel):
    user_id: int
    email: str
    households: list[HouseholdResponse]