"""Shared authorization helpers for apartment household boundaries."""

import hashlib
from datetime import datetime, timezone

from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.auth_tokens import get_current_user
from app.database import get_db
from app.models import DBHousehold, DBHouseholdMember, DBUser


def hash_invite_code(code: str) -> str:
    """Hash an invite before persistence so database reads cannot redeem it."""
    return hashlib.sha256(code.encode("utf-8")).hexdigest()


def get_current_household(
    current_user: DBUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> DBHousehold:
    """Resolve the user's only active household for the apartment POC."""
    memberships = (
        db.query(DBHouseholdMember, DBHousehold)
        .join(
            DBHousehold,
            DBHousehold.household_id == DBHouseholdMember.household_id,
        )
        .filter(
            DBHouseholdMember.user_id == current_user.user_id,
            DBHouseholdMember.revoked_at.is_(None),
        )
        .order_by(DBHouseholdMember.joined_at.asc())
        .all()
    )
    if not memberships:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Join or create a household before using inventory.",
        )
    if len(memberships) > 1:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Multiple households exist; household selection is not implemented yet.",
        )
    return memberships[0][1]


def require_active_membership(
    db: Session,
    household_id: int,
    user_id: int,
) -> DBHouseholdMember:
    membership = (
        db.query(DBHouseholdMember)
        .filter(
            DBHouseholdMember.household_id == household_id,
            DBHouseholdMember.user_id == user_id,
            DBHouseholdMember.revoked_at.is_(None),
        )
        .first()
    )
    if not membership:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not an active member of this household.",
        )
    return membership


def utc_now() -> datetime:
    return datetime.now(tz=timezone.utc)
