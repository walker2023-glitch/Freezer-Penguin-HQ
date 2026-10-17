import os

os.environ.setdefault("DATABASE_URL", "sqlite:///./test_ci.db")

from app.household_access import hash_invite_code  # noqa: E402
from app.models import DBHousehold, DBHouseholdInvite, DBHouseholdMember  # noqa: E402


def test_invite_code_hash_is_one_way_and_stable():
    code = "apartment-invite-code"
    hashed = hash_invite_code(code)
    assert hashed == hash_invite_code(code)
    assert hashed != code
    assert len(hashed) == 64


def test_household_models_preserve_unique_membership_and_invite_constraints():
    membership_constraints = {
        constraint.name
        for constraint in DBHouseholdMember.__table__.constraints
        if constraint.name
    }
    invite_indexes = {
        index.name
        for index in DBHouseholdInvite.__table__.indexes
        if index.name
    }
    assert "uq_household_members_household_user" in membership_constraints
    assert "ix_household_invites_invite_code_hash" in invite_indexes
    assert DBHousehold.__table__.c.created_by.nullable is False