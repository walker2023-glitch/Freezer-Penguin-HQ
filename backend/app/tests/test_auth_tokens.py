import os

import pytest
from fastapi import HTTPException

os.environ.setdefault("AUTH_TOKEN_SECRET", "test-only-auth-secret")

from app.auth_tokens import create_access_token, _read_user_id  # noqa: E402


def test_signed_token_round_trips_user_id():
    token = create_access_token(42)
    assert _read_user_id(token) == 42


def test_tampered_token_is_rejected():
    token = create_access_token(42)
    body, signature = token.split(".", maxsplit=1)
    with pytest.raises(HTTPException) as error:
        _read_user_id(f"{body}.tampered{signature}")
    assert error.value.status_code == 401


def test_malformed_token_is_rejected():
    with pytest.raises(HTTPException) as error:
        _read_user_id("not-a-token")
    assert error.value.status_code == 401
