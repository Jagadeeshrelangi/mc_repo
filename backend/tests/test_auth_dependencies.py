"""Tests for the Stage 7 dependency wiring (get_current_user, role_required).

These tests exercise the REAL ``app.api.deps`` functions. The security engine
is exercised with a real configured JWT secret (monkeypatched on ``settings``)
so token creation/verification is genuine; user retrieval is tested against a
small in-memory fake session (no live PostgreSQL).

``role_required`` is asserted to depend on ``get_current_user`` and to reuse
the approved D3 roles — no second role enum is introduced.
"""

import asyncio
from datetime import datetime, timezone
from typing import Dict, Optional

import pytest

from app.api import deps
from app.core import security
from app.core.config import settings
from app.core.exceptions import EntityNotFoundException, UnauthorizedException
from app.models.user import User
from app.repositories.users import UserRepository
from app.schemas.user import UserRoleLiteral, UserOut

TEST_JWT_SECRET = "stage7-test-secret-not-for-production"
USER_ID = "11111111-1111-1111-1111-111111111111"

NOW = datetime(2026, 8, 15, 12, 0, 0, tzinfo=timezone.utc)


class FakeSession:
    """Minimal session supporting exactly the repository calls used here."""

    def __init__(self, users: Dict[str, User]) -> None:
        self.users = users

    async def get(self, model, entity_id) -> Optional[User]:
        if model is User:
            return self.users.get(str(entity_id))
        return None


def make_user(**overrides) -> User:
    defaults: Dict = {
        "id": USER_ID,
        "name": "Jagadeesh Gowda",
        "email": "jagadeesh@example.com",
        "phone": "+919876543210",
        "password_hash": "$2b$12$irrelevantforthisdep",
        "role": "customer",
        "is_active": True,
        "is_verified": False,
        "failed_login_attempts": 0,
        "membership_tier": "free",
        "joined_at": NOW,
        "created_at": NOW,
        "updated_at": NOW,
        "last_login_at": None,
        "lockout_at": None,
    }
    defaults.update(overrides)
    return User(**defaults)


def _access_token(user_id: str = USER_ID) -> str:
    return security.create_access_token(user_id)


def _refresh_token(user_id: str = USER_ID) -> str:
    return security.create_refresh_token(user_id)


@pytest.fixture(autouse=True)
def _jwt_secret(monkeypatch):
    """Provide a real JWT secret for genuine token create/verify (never the
    production secret — tests never read backend/.env)."""
    monkeypatch.setattr(settings, "JWT_SECRET_KEY", TEST_JWT_SECRET)


def test_get_current_user_missing_credentials() -> None:
    async def _run() -> None:
        with pytest.raises(UnauthorizedException):
            await deps.get_current_user(credentials=None, session=FakeSession({}))

    asyncio.run(_run())


def test_get_current_user_malformed_credentials() -> None:
    async def _run() -> None:
        with pytest.raises(UnauthorizedException):
            await deps.get_current_user(
                credentials=type("C", (), {"credentials": "not-a-jwt"})(),
                session=FakeSession({}),
            )

    asyncio.run(_run())


def test_get_current_user_accepts_valid_access_token() -> None:
    async def _run() -> None:
        user = make_user()
        session = FakeSession({USER_ID: user})
        result = await deps.get_current_user(
            credentials=type("C", (), {"credentials": _access_token()})(),
            session=session,
        )
        assert result is user

    asyncio.run(_run())


def test_get_current_user_rejects_refresh_token_as_access() -> None:
    async def _run() -> None:
        user = make_user()
        session = FakeSession({USER_ID: user})
        with pytest.raises(UnauthorizedException):
            await deps.get_current_user(
                credentials=type("C", (), {"credentials": _refresh_token()})(),
                session=session,
            )

    asyncio.run(_run())


def test_get_current_user_rejects_inactive_user() -> None:
    async def _run() -> None:
        user = make_user(is_active=False)
        session = FakeSession({USER_ID: user})
        with pytest.raises(UnauthorizedException):
            await deps.get_current_user(
                credentials=type("C", (), {"credentials": _access_token()})(),
                session=session,
            )

    asyncio.run(_run())


def test_get_current_user_raises_not_found_for_missing_user() -> None:
    async def _run() -> None:
        with pytest.raises(EntityNotFoundException):
            await deps.get_current_user(
                credentials=type("C", (), {"credentials": _access_token()})(),
                session=FakeSession({}),
            )

    asyncio.run(_run())


def test_role_required_allows_matching_role() -> None:
    async def _run() -> None:
        user = make_user(role="admin")
        dep = deps.role_required("admin")
        result = await dep(user=user)
        assert result is user

    asyncio.run(_run())


def test_role_required_forbids_other_roles_generically() -> None:
    async def _run() -> None:
        user = make_user(role="customer")
        dep = deps.role_required("admin", "mechanic")
        with pytest.raises(UnauthorizedException):
            await dep(user=user)

    asyncio.run(_run())


def test_role_required_uses_approved_d3_roles_only() -> None:
    """No second role enum: UserRoleLiteral is the single source (D3)."""
    from app.models.user import UserRole

    literal_values = set(UserRoleLiteral.__args__)  # type: ignore[attr-defined]
    assert literal_values == set(UserRole.VALUES)
    assert "customer" in literal_values
    assert "mechanic" in literal_values
    assert "admin" in literal_values
    assert len(literal_values) == 3


def test_get_current_user_return_serializes_as_safe_user_out() -> None:
    """The authenticated user must project to the safe UserOut (no secrets)."""
    user = make_user()
    out = UserOut.model_validate(user)
    dumped = out.model_dump()
    for secret_field in ("password_hash", "token_digest", "failed_login_attempts", "lockout_at", "last_login_at"):
        assert secret_field not in dumped
    assert dumped["role"] == "customer"