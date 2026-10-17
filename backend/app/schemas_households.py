"""Household API schemas."""

from datetime import datetime
from pydantic import BaseModel, Field


class HouseholdCreateRequest(BaseModel):
    name: str = Field(min_length=1, max_length=120)


class HouseholdResponse(BaseModel):
    household_id: int
    name: str
    created_by: int
    created_at: datetime

    class Config:
        from_attributes = True


class HouseholdInviteCreateRequest(BaseModel):
    expires_in_days: int = Field(default=7, ge=1, le=30)


class HouseholdInviteResponse(BaseModel):
    invite_code: str
    household_id: int
    expires_at: datetime


class AcceptInviteResponse(BaseModel):
    household: HouseholdResponse
    membership_id: int


class MeResponse(BaseModel):
    user_id: int
    email: str
    households: list[HouseholdResponse]
