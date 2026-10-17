"""Household membership and invitation routes for the apartment POC."""

import logging
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
    DBInventoryItem,
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

logger = logging.getLogger(__name__)
router = APIRouter(tags=["Households"])


def _household_response(household: DBHousehold, role: str) -> HouseholdResponse:
    return HouseholdResponse(
        household_id=household.household_id,
        name=household.name,
        role=role,
        created_at=household.created_at,
    )


@router.get("/me", response_model=MeResponse, status_code=status.HTTP_200_OK)
def get_me(
    current_user: DBUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MeResponse:
    rows = (
        db.query(DBHousehold, DBHouseholdMember)
        .join(
            DBHouseholdMember,
            DBHouseholdMember.household_id == DBHousehold.household_id,
        )
        .filter(
            DBHouseholdMember.user_id == current_user.user_id,
            DBHouseholdMember.revoked_at.is_(None),
        )
        .order_by(DBHouseholdMember.joined_at.asc())
        .all()
    )
    return MeResponse(
        user_id=current_user.user_id,
        email=current_user.email,
        households=[
            _household_response(household, membership.role)
            for household, membership in rows
        ],
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
    now = utc_now()
    household = DBHousehold(
        name=payload.name.strip(),
        created_by=current_user.user_id,
        created_at=now,
    )
    try:
        db.add(household)
        db.flush()
        db.add(
            DBHouseholdMember(
                household_id=household.household_id,
                user_id=current_user.user_id,
                role="owner",
                joined_at=now,
            )
        )
        db.query(DBInventoryItem).filter(
            DBInventoryItem.user_id == current_user.user_id,
            DBInventoryItem.household_id.is_(None),
        ).update(
            {DBInventoryItem.household_id: household.household_id},
            synchronize_session=False,
        )
        db.commit()
        db.refresh(household)
    except Exception as exc:
        db.rollback()
        logger.error("Household creation failed — user_id=%s error=%s", current_user.user_id, exc)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Could not create household. Transaction rolled back.",
        )
    return _household_response(household, "owner")


@router.get(
    "/households",
    response_model=list[HouseholdResponse],
    status_code=status.HTTP_200_OK,
)
def list_households(
    current_user: DBUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[HouseholdResponse]:
    rows = (
        db.query(DBHousehold, DBHouseholdMember)
        .join(
            DBHouseholdMember,
            DBHouseholdMember.household_id == DBHousehold.household_id,
        )
        .filter(
            DBHouseholdMember.user_id == current_user.user_id,
            DBHouseholdMember.revoked_at.is_(None),
        )
        .order_by(DBHouseholdMember.joined_at.asc())
        .all()
    )
    return [
        _household_response(household, membership.role)
        for household, membership in rows
    ]


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
    membership = require_active_membership(db, household_id, current_user.user_id)
    if membership.role != "owner":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only a household owner can create invites.",
        )
    household = db.get(DBHousehold, household_id)
    if household is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Household not found.",
        )

    code = secrets.token_urlsafe(24)
    expires_at = utc_now() + timedelta(hours=payload.expires_in_hours)
    invite = DBHouseholdInvite(
        household_id=household_id,
        created_by=current_user.user_id,
        invite_code_hash=hash_invite_code(code),
        expires_at=expires_at,
        created_at=utc_now(),
    )
    try:
        db.add(invite)
        db.commit()
        db.refresh(invite)
    except Exception as exc:
        db.rollback()
        logger.error("Invite creation failed — household_id=%s error=%s", household_id, exc)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Could not create household invite. Transaction rolled back.",
        )
    return HouseholdInviteResponse(
        invite_id=invite.invite_id,
        household_id=household_id,
        code=code,
        expires_at=invite.expires_at,
    )


@router.post(
    "/household-invites/{code}/accept",
    response_model=AcceptInviteResponse,
    status_code=status.HTTP_200_OK,
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
        )
        .first()
    )
    if invite is None or invite.expires_at <= utc_now():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invite is invalid or expired.",
        )
    existing = (
        db.query(DBHouseholdMember)
        .filter(
            DBHouseholdMember.household_id == invite.household_id,
            DBHouseholdMember.user_id == current_user.user_id,
        )
        .first()
    )
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="User is already a member of this household.",
        )
    household = db.get(DBHousehold, invite.household_id)
    if household is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Household no longer exists.",
        )
    now = utc_now()
    try:
        db.add(
            DBHouseholdMember(
                household_id=invite.household_id,
                user_id=current_user.user_id,
                role="member",
                joined_at=now,
            )
        )
        invite.accepted_at = now
        invite.accepted_by = current_user.user_id
        db.commit()
    except Exception as exc:
        db.rollback()
        logger.error(
            "Invite acceptance failed — household_id=%s user_id=%s error=%s",
            invite.household_id,
            current_user.user_id,
            exc,
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Could not accept invite. Transaction rolled back.",
        )
    return AcceptInviteResponse(
        household_id=household.household_id,
        household_name=household.name,
        role="member",
    )
