"""Household membership and authorization helpers."""

import hashlib
from datetime import datetime, timezone

from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.auth_tokens import get_current_user
from app.database import get_db
from app.models import DBHousehold, DBHouseholdMember, DBUser


def utc_now() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


def hash_invite_code(code: str) -> str:
    return hashlib.sha256(code.encode("utf-8")).hexdigest()


def require_active_membership(
    household_id: int,
    user_id: int,
    db: Session,
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
    if membership is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not an active member of this household.",
        )
    return membership


def get_current_household(
    current_user: DBUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> DBHousehold:
    memberships = (
        db.query(DBHouseholdMember, DBHousehold)
        .join(DBHousehold, DBHousehold.household_id == DBHouseholdMember.household_id)
        .filter(
            DBHouseholdMember.user_id == current_user.user_id,
            DBHouseholdMember.revoked_at.is_(None),
        )
        .all()
    )
    if not memberships:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Create or join a household before using inventory.",
        )
    if len(memberships) > 1:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Multiple households are available; household selection is not yet enabled.",
        )
    return memberships[0][1]
