"""Household creation, membership, and invite routes."""

import secrets
from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.auth_tokens import get_current_user
from app.database import get_db
from app.household_access import hash_invite_code, require_active_membership, utc_now
from app.models import (
    DBHousehold,
    DBHouseholdInvite,
    DBHouseholdMember,
    DBUser,
)
from app.schemas_households import (
    AcceptInviteResponse,
    HouseholdCreateRequest,
    HouseholdInviteCreateRequest,
    HouseholdInviteResponse,
    HouseholdResponse,
    MeResponse,
)

router = APIRouter(tags=["Households"])


@router.get("/me", response_model=MeResponse)
def get_me(
    current_user: DBUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MeResponse:
    households = (
        db.query(DBHousehold)
        .join(
            DBHouseholdMember,
            DBHouseholdMember.household_id == DBHousehold.household_id,
        )
        .filter(
            DBHouseholdMember.user_id == current_user.user_id,
            DBHouseholdMember.revoked_at.is_(None),
        )
        .order_by(DBHousehold.household_id)
        .all()
    )
    return MeResponse(
        user_id=current_user.user_id,
        email=current_user.email,
        households=[HouseholdResponse.model_validate(item) for item in households],
    )


@router.post(
    "/households",
    response_model=HouseholdResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_household(
    payload: HouseholdCreateRequest,
    current_user: DBUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> HouseholdResponse:
    household = DBHousehold(
        name=payload.name.strip(),
        created_by=current_user.user_id,
        created_at=utc_now(),
    )
    try:
        db.add(household)
        db.flush()
        membership = DBHouseholdMember(
            household_id=household.household_id,
            user_id=current_user.user_id,
            role="owner",
            joined_at=utc_now(),
        )
        db.add(membership)
        db.commit()
        db.refresh(household)
    except Exception as exc:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Could not create household: {exc}",
        ) from exc
    return HouseholdResponse.model_validate(household)


@router.get("/households", response_model=list[HouseholdResponse])
def list_households(
    current_user: DBUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[HouseholdResponse]:
    return get_me(current_user=current_user, db=db).households


@router.post(
    "/households/{household_id}/invites",
    response_model=HouseholdInviteResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_invite(
    household_id: int,
    payload: HouseholdInviteCreateRequest,
    current_user: DBUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> HouseholdInviteResponse:
    household = db.query(DBHousehold).filter(DBHousehold.household_id == household_id).first()
    if household is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Household not found.")
    membership = require_active_membership(household_id, current_user.user_id, db)
    if membership.role not in {"owner", "admin"}:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only household owners or admins can invite members.",
        )
    code = secrets.token_urlsafe(16)
    now = utc_now()
    invite = DBHouseholdInvite(
        household_id=household_id,
        created_by=current_user.user_id,
        invite_code_hash=hash_invite_code(code),
        created_at=now,
        expires_at=now + timedelta(days=payload.expires_in_days),
    )
    try:
        db.add(invite)
        db.commit()
    except Exception as exc:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Could not create invite: {exc}",
        ) from exc
    return HouseholdInviteResponse(
        invite_code=code,
        household_id=household_id,
        expires_at=invite.expires_at,
    )


@router.post(
    "/household-invites/{code}/accept",
    response_model=AcceptInviteResponse,
)
def accept_invite(
    code: str,
    current_user: DBUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> AcceptInviteResponse:
    invite = (
        db.query(DBHouseholdInvite)
        .filter(
            DBHouseholdInvite.invite_code_hash == hash_invite_code(code),
            DBHouseholdInvite.accepted_at.is_(None),
            DBHouseholdInvite.expires_at > utc_now(),
        )
        .first()
    )
    if invite is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invite is invalid or expired.")
    existing = (
        db.query(DBHouseholdMember)
        .filter(
            DBHouseholdMember.household_id == invite.household_id,
            DBHouseholdMember.user_id == current_user.user_id,
            DBHouseholdMember.revoked_at.is_(None),
        )
        .first()
    )
    if existing is None:
        membership = DBHouseholdMember(
            household_id=invite.household_id,
            user_id=current_user.user_id,
            role="member",
            joined_at=utc_now(),
        )
        db.add(membership)
    else:
        membership = existing
    invite.accepted_at = utc_now()
    invite.accepted_by = current_user.user_id
    try:
        db.commit()
        db.refresh(membership)
    except Exception as exc:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Could not accept invite: {exc}",
        ) from exc
    household = db.query(DBHousehold).filter(DBHousehold.household_id == invite.household_id).one()
    return AcceptInviteResponse(
        household=HouseholdResponse.model_validate(household),
        membership_id=membership.membership_id,
    )
