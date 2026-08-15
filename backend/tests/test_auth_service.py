"""Tests for the AuthService (Sprint 2, Task 3, Stage 6).

Strategy: the service is a coordination layer, so these tests use lightweight
in-memory fakes for the session and repositories plus patched security-engine
functions. This exercises service orchestration and transaction boundaries
without a live PostgreSQL server and without faking DB server behavior.

Password hashing, JWT creation, and token verification are already tested in
``tests/test_security.py``; here the security functions are patched so we can
control outcomes (right/wrong password, expired token, wrong token type).
"""

import hashlib
from datetime import datetime, timedelta, timezone
from typing import Dict, Optional

import pytest

from app.core import security
from app.core.exceptions import (
    EntityNotFoundException,
    InvalidInputException,
    UnauthorizedException,
)
from app.models.refresh_token import RefreshToken
from app.models.user import User
from app.schemas.auth import ForgotPasswordResponse, LogoutResponse, TokenResponse
from app.schemas.user import UserOut
from app.services import auth_service as auth_svc
from app.services.auth_service import AuthService

NOW = datetime(2026, 8, 15, 12, 0, 0, tzinfo=timezone.utc)
FAKE_ACCESS = "access-token"
FAKE_REFRESH = "refresh-token"
FAKE_DIGEST = hashlib.sha256(FAKE_REFRESH.encode("utf-8")).hexdigest()
FAKE_HASH = "$2b$12$fakehashedpassword"
FAKE_JTI = "jti-1"


class FakeDatetime(datetime):
    """Controllable ``datetime`` for the auth service module."""

    _now: datetime = NOW

    @classmethod
    def now(cls, tz=None):  # noqa: N805 - matches datetime signature
        return cls._now


class FakeSession:
    def __init__(self) -> None:
        self.commits = 0
        self.rollbacks = 0

    async def commit(self) -> None:
        self.commits += 1

    async def rollback(self) -> None:
        self.rollbacks += 1


class FakeUserRepo:
    def __init__(self) -> None:
        self.users: Dict[str, User] = {}
        self.created: list[User] = []
        self.events: list[tuple] = []

    def add(self, user: User) -> None:
        self.users[user.id] = user

    def _find(self, field: str, value: str) -> Optional[User]:
        for user in self.users.values():
            if getattr(user, field) == value:
                return user
        return None

    async def get(self, user_id: str) -> Optional[User]:
        return self.users.get(user_id)

    async def get_by_email(self, email: str) -> Optional[User]:
        return self._find("email", email)

    async def get_by_phone(self, phone: str) -> Optional[User]:
        return self._find("phone", phone)

    async def create_user(self, **kwargs) -> User:
        user = make_user(**kwargs)
        self.users[user.id] = user
        self.created.append(user)
        return user

    async def record_successful_login(self, user: User) -> None:
        self.events.append(("success", user.id))
        user.last_login_at = NOW
        user.failed_login_attempts = 0

    async def record_failed_login(self, user: User) -> None:
        self.events.append(("fail", user.id))
        user.failed_login_attempts = (user.failed_login_attempts or 0) + 1

    async def clear_login_failures(self, user: User) -> None:
        self.events.append(("clear", user.id))
        user.failed_login_attempts = 0

    async def lock_account(self, user: User, lockout_at: datetime) -> None:
        self.events.append(("lock", user.id))
        user.lockout_at = lockout_at

    async def unlock_account(self, user: User) -> None:
        self.events.append(("unlock", user.id))
        user.lockout_at = None
        user.failed_login_attempts = 0


class FakeRefreshRepo:
    def __init__(self) -> None:
        self.records: Dict[str, RefreshToken] = {}
        self.created: list[RefreshToken] = []
        self.events: list[tuple] = []
        self._counter = 1000

    async def get_by_digest(self, digest: str) -> Optional[RefreshToken]:
        for record in self.records.values():
            if record.token_digest == digest:
                return record
        return None

    async def get_by_jti(self, jti: str) -> Optional[RefreshToken]:
        for record in self.records.values():
            if record.jti == jti:
                return record
        return None

    async def create_refresh_token(self, *, user_id: str, token_digest: str, jti: str, expires_at: datetime) -> RefreshToken:
        self._counter += 1
        record = RefreshToken(
            id=f"rt-{self._counter}",
            user_id=user_id,
            token_digest=token_digest,
            jti=jti,
            expires_at=expires_at,
            revoked_at=None,
            replaced_by_id=None,
        )
        self.records[record.id] = record
        self.created.append(record)
        return record

    async def revoke(self, record: RefreshToken) -> None:
        self.events.append(("revoke", record.id))
        record.revoked_at = NOW

    async def mark_replaced(self, record: RefreshToken, replaced_by_id: str) -> None:
        self.events.append(("replaced", record.id, replaced_by_id))
        record.replaced_by_id = replaced_by_id

    def is_active(self, record: RefreshToken) -> bool:
        return record.revoked_at is None and record.expires_at > NOW


def make_user(**overrides) -> User:
    defaults: Dict = {
        "id": "u-1",
        "name": "Jagadeesh Gowda",
        "email": "jagadeesh@example.com",
        "phone": "+919876543210",
        "password_hash": FAKE_HASH,
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


def make_refresh_record(**overrides) -> RefreshToken:
    defaults: Dict = {
        "id": "rt-1",
        "user_id": "u-1",
        "token_digest": FAKE_DIGEST,
        "jti": FAKE_JTI,
        "expires_at": NOW + timedelta(days=7),
        "revoked_at": None,
        "replaced_by_id": None,
    }
    defaults.update(overrides)
    return RefreshToken(**defaults)


@pytest.fixture(autouse=True)
def _auth_service_env(monkeypatch):
    """Patch time + security functions; restore everything after each test."""
    monkeypatch.setattr(auth_svc, "datetime", FakeDatetime)
    monkeypatch.setattr(security, "hash_password", lambda p: FAKE_HASH)
    monkeypatch.setattr(security, "verify_password", lambda p, h: True)
    monkeypatch.setattr(security, "create_access_token", lambda uid, **kw: FAKE_ACCESS)
    monkeypatch.setattr(security, "create_refresh_token", lambda uid, **kw: FAKE_REFRESH)
    monkeypatch.setattr(
        security,
        "verify_refresh_token",
        lambda token: {
            "sub": "u-1",
            "iat": int(NOW.timestamp()),
            "exp": int((NOW + timedelta(days=7)).timestamp()),
            "jti": FAKE_JTI,
            "type": "refresh",
        },
    )


def make_service(user_repo: Optional[FakeUserRepo] = None, refresh_repo: Optional[FakeRefreshRepo] = None):
    session = FakeSession()
    service = AuthService(
        session,
        user_repository=user_repo or FakeUserRepo(),
        refresh_token_repository=refresh_repo or FakeRefreshRepo(),
    )
    return service, session


# ============================================================================
# REGISTRATION
# ============================================================================


def test_register_success() -> None:
    from app.schemas.auth import RegisterRequest

    svc, session = make_service()
    payload = RegisterRequest(
        name="Jagadeesh Gowda",
        email="new@example.com",
        phone="+911234567890",
        password="StrongPass123",
    )

    result = await_result(svc.register(payload))

    assert isinstance(result, UserOut)
    assert result.email == "new@example.com"
    assert result.role == "customer"
    assert result.is_active is True
    assert result.is_verified is False
    assert svc.user_repo.created and svc.user_repo.created[0].id == result.id
    assert session.commits == 1
    assert session.rollbacks == 0


def test_register_password_is_hashed_not_plaintext() -> None:
    from app.schemas.auth import RegisterRequest

    svc, _ = make_service()
    payload = RegisterRequest(
        name="Jagadeesh Gowda",
        email="new@example.com",
        phone="+911234567890",
        password="StrongPass123",
    )

    await_result(svc.register(payload))

    created = svc.user_repo.created[0]
    assert created.password_hash == FAKE_HASH
    assert created.password_hash != "StrongPass123"
    assert "StrongPass123" not in created.password_hash


def test_register_defaults_customer_active_unverified() -> None:
    from app.schemas.auth import RegisterRequest

    svc, _ = make_service()
    payload = RegisterRequest(
        name="Jagadeesh Gowda",
        email="new@example.com",
        phone="+911234567890",
        password="StrongPass123",
    )

    await_result(svc.register(payload))

    created = svc.user_repo.created[0]
    assert created.role == "customer"
    assert created.is_active is True
    assert created.is_verified is False
    assert created.failed_login_attempts == 0


def test_register_duplicate_email() -> None:
    from app.schemas.auth import RegisterRequest

    repo = FakeUserRepo()
    repo.add(make_user(email="dup@example.com", phone="+911111111111"))
    svc, session = make_service(user_repo=repo)
    payload = RegisterRequest(
        name="Jagadeesh Gowda",
        email="dup@example.com",
        phone="+911234567890",
        password="StrongPass123",
    )

    with pytest.raises(InvalidInputException) as exc_info:
        await_result(svc.register(payload))

    assert "email" in str(exc_info.value.message).lower()
    assert session.rollbacks == 1
    assert svc.user_repo.created == []


def test_register_duplicate_phone() -> None:
    from app.schemas.auth import RegisterRequest

    repo = FakeUserRepo()
    repo.add(make_user(email="other@example.com", phone="+911234567890"))
    svc, session = make_service(user_repo=repo)
    payload = RegisterRequest(
        name="Jagadeesh Gowda",
        email="new@example.com",
        phone="+911234567890",
        password="StrongPass123",
    )

    with pytest.raises(InvalidInputException) as exc_info:
        await_result(svc.register(payload))

    assert "phone" in str(exc_info.value.message).lower()
    assert session.rollbacks == 1
    assert svc.user_repo.created == []


def test_register_result_does_not_expose_password_hash() -> None:
    from app.schemas.auth import RegisterRequest

    svc, _ = make_service()
    payload = RegisterRequest(
        name="Jagadeesh Gowda",
        email="new@example.com",
        phone="+911234567890",
        password="StrongPass123",
    )

    result = await_result(svc.register(payload))

    dumped = result.model_dump()
    assert "password_hash" not in dumped
    assert "failed_login_attempts" not in dumped
    assert "lockout_at" not in dumped


# ============================================================================
# LOGIN
# ============================================================================


def test_login_success_by_email() -> None:
    repo = FakeUserRepo()
    repo.add(make_user())
    svc, session = make_service(user_repo=repo)

    result = await_result(svc.login("jagadeesh@example.com", "StrongPass123"))

    assert isinstance(result, TokenResponse)
    assert result.access_token == FAKE_ACCESS
    assert result.refresh_token == FAKE_REFRESH
    assert result.token_type == "bearer"
    assert result.expires_in > 0
    assert ("unlock", "u-1") in svc.user_repo.events
    assert ("success", "u-1") in svc.user_repo.events
    assert session.commits == 1


def test_login_success_by_phone() -> None:
    repo = FakeUserRepo()
    repo.add(make_user())
    svc, _ = make_service(user_repo=repo)

    result = await_result(svc.login("+919876543210", "StrongPass123"))

    assert result.access_token == FAKE_ACCESS


def test_login_stores_refresh_digest_not_plaintext() -> None:
    repo = FakeUserRepo()
    repo.add(make_user())
    refresh_repo = FakeRefreshRepo()
    svc, _ = make_service(user_repo=repo, refresh_repo=refresh_repo)

    await_result(svc.login("jagadeesh@example.com", "StrongPass123"))

    assert len(refresh_repo.created) == 1
    stored = refresh_repo.created[0]
    assert stored.token_digest == FAKE_DIGEST
    assert stored.token_digest != FAKE_REFRESH
    assert stored.user_id == "u-1"
    assert stored.jti == FAKE_JTI


def test_login_wrong_password_generic_failure() -> None:
    repo = FakeUserRepo()
    repo.add(make_user())
    svc, session = make_service(user_repo=repo)

    from app.core import security as sec

    def _wrong(password, hashed):
        return False

    import app.core.security as core_sec
    from unittest.mock import patch

    with patch.object(core_sec, "verify_password", _wrong):
        with pytest.raises(UnauthorizedException) as exc_info:
            await_result(svc.login("jagadeesh@example.com", "WrongPass123"))

    assert exc_info.value.message == auth_svc.GENERIC_LOGIN_FAILURE
    assert ("fail", "u-1") in svc.user_repo.events
    # The failure counter must persist across requests (lockout relies on it).
    assert session.commits >= 1


def test_login_unknown_identifier_generic_failure() -> None:
    svc, session = make_service()
    with pytest.raises(UnauthorizedException) as exc_info:
        await_result(svc.login("nobody@example.com", "StrongPass123"))
    assert exc_info.value.message == auth_svc.GENERIC_LOGIN_FAILURE
    assert svc.user_repo.events == []


def test_login_inactive_account_generic_failure() -> None:
    repo = FakeUserRepo()
    repo.add(make_user(is_active=False))
    svc, _ = make_service(user_repo=repo)

    with pytest.raises(UnauthorizedException) as exc_info:
        await_result(svc.login("jagadeesh@example.com", "StrongPass123"))
    assert exc_info.value.message == auth_svc.GENERIC_LOGIN_FAILURE


def test_login_failed_attempt_counter_increments() -> None:
    repo = FakeUserRepo()
    user = make_user(failed_login_attempts=1)
    repo.add(user)
    svc, _ = make_service(user_repo=repo)

    from unittest.mock import patch

    import app.core.security as core_sec

    with patch.object(core_sec, "verify_password", lambda p, h: False):
        with pytest.raises(UnauthorizedException):
            await_result(svc.login("jagadeesh@example.com", "WrongPass123"))

    assert user.failed_login_attempts == 2


def test_login_lockout_after_five_failures() -> None:
    repo = FakeUserRepo()
    user = make_user(failed_login_attempts=4)
    repo.add(user)
    svc, _ = make_service(user_repo=repo)

    from unittest.mock import patch

    import app.core.security as core_sec

    with patch.object(core_sec, "verify_password", lambda p, h: False):
        with pytest.raises(UnauthorizedException):
            await_result(svc.login("jagadeesh@example.com", "WrongPass123"))

    assert user.failed_login_attempts == 5
    assert user.lockout_at == NOW
    assert ("lock", "u-1") in svc.user_repo.events


def test_login_denied_while_locked() -> None:
    repo = FakeUserRepo()
    user = make_user(lockout_at=NOW - timedelta(minutes=1))
    repo.add(user)
    svc, _ = make_service(user_repo=repo)

    from unittest.mock import patch

    import app.core.security as core_sec

    with patch.object(core_sec, "verify_password", lambda p, h: True):
        with pytest.raises(UnauthorizedException) as exc_info:
            await_result(svc.login("jagadeesh@example.com", "StrongPass123"))

    assert exc_info.value.message == auth_svc.GENERIC_LOGIN_FAILURE
    # Verify was never attempted and no new failure was recorded.
    assert ("fail", "u-1") not in svc.user_repo.events


def test_login_expired_lockout_allows_auth_and_clears_state() -> None:
    repo = FakeUserRepo()
    user = make_user(lockout_at=NOW - timedelta(minutes=11), failed_login_attempts=5)
    repo.add(user)
    svc, session = make_service(user_repo=repo)

    result = await_result(svc.login("jagadeesh@example.com", "StrongPass123"))

    assert result.access_token == FAKE_ACCESS
    assert ("unlock", "u-1") in svc.user_repo.events
    assert user.lockout_at is None
    assert user.failed_login_attempts == 0
    assert session.commits == 1


def test_login_success_clears_failures_and_lockout() -> None:
    repo = FakeUserRepo()
    user = make_user(failed_login_attempts=3)
    repo.add(user)
    svc, _ = make_service(user_repo=repo)

    await_result(svc.login("jagadeesh@example.com", "StrongPass123"))

    assert ("unlock", "u-1") in svc.user_repo.events
    assert ("success", "u-1") in svc.user_repo.events
    assert user.lockout_at is None
    assert user.failed_login_attempts == 0


def test_login_updates_last_login_at() -> None:
    repo = FakeUserRepo()
    user = make_user()
    repo.add(user)
    svc, _ = make_service(user_repo=repo)

    await_result(svc.login("jagadeesh@example.com", "StrongPass123"))

    assert user.last_login_at == NOW


# ============================================================================
# REFRESH ROTATION (D6)
# ============================================================================


def test_refresh_valid_rotation() -> None:
    user = make_user()
    user_repo = FakeUserRepo()
    user_repo.add(user)
    refresh_repo = FakeRefreshRepo()
    refresh_repo.records["rt-1"] = make_refresh_record()
    svc, session = make_service(user_repo=user_repo, refresh_repo=refresh_repo)

    result = await_result(svc.refresh(FAKE_REFRESH))

    assert isinstance(result, TokenResponse)
    assert result.access_token == FAKE_ACCESS
    assert result.refresh_token == FAKE_REFRESH
    old = refresh_repo.records["rt-1"]
    assert old.revoked_at == NOW
    assert ("revoke", "rt-1") in refresh_repo.events
    # Replacement stored + lineage recorded.
    assert len(refresh_repo.created) == 1
    replacement = refresh_repo.created[0]
    assert replacement.token_digest == FAKE_DIGEST
    assert ("replaced", "rt-1", replacement.id) in refresh_repo.events
    assert old.replaced_by_id == replacement.id
    # Atomic: exactly one commit, no rollback.
    assert session.commits == 1
    assert session.rollbacks == 0


def test_refresh_rejects_access_token_type() -> None:
    svc, session = make_service()
    refresh_repo = FakeRefreshRepo()
    refresh_repo.records["rt-1"] = make_refresh_record()
    svc, session = make_service(refresh_repo=refresh_repo)

    from unittest.mock import patch

    import app.core.security as core_sec
    from app.core.security import TokenTypeError

    def _type_check(token):
        raise TokenTypeError("token is not a refresh token")

    with patch.object(core_sec, "verify_refresh_token", _type_check):
        with pytest.raises(UnauthorizedException) as exc_info:
            await_result(svc.refresh("an.access.token"))

    assert exc_info.value.message == auth_svc.GENERIC_REFRESH_FAILURE
    assert session.commits == 0


def test_refresh_rejects_expired_token() -> None:
    refresh_repo = FakeRefreshRepo()
    refresh_repo.records["rt-1"] = make_refresh_record()
    svc, session = make_service(refresh_repo=refresh_repo)

    from unittest.mock import patch

    import app.core.security as core_sec
    from app.core.security import ExpiredTokenError

    def _expired(token):
        raise ExpiredTokenError("token has expired")

    with patch.object(core_sec, "verify_refresh_token", _expired):
        with pytest.raises(UnauthorizedException) as exc_info:
            await_result(svc.refresh(FAKE_REFRESH))

    assert exc_info.value.message == auth_svc.GENERIC_REFRESH_FAILURE
    assert session.commits == 0
    assert refresh_repo.events == []


def test_refresh_rejects_revoked_token() -> None:
    user = make_user()
    user_repo = FakeUserRepo()
    user_repo.add(user)
    refresh_repo = FakeRefreshRepo()
    refresh_repo.records["rt-1"] = make_refresh_record(revoked_at=NOW)
    svc, session = make_service(user_repo=user_repo, refresh_repo=refresh_repo)

    with pytest.raises(UnauthorizedException) as exc_info:
        await_result(svc.refresh(FAKE_REFRESH))

    assert exc_info.value.message == auth_svc.GENERIC_REFRESH_FAILURE
    assert refresh_repo.events == []
    assert session.commits == 0


def test_refresh_rejects_unknown_digest() -> None:
    svc, _ = make_service()
    with pytest.raises(UnauthorizedException) as exc_info:
        await_result(svc.refresh(FAKE_REFRESH))
    assert exc_info.value.message == auth_svc.GENERIC_REFRESH_FAILURE


def test_refresh_rejects_inactive_user() -> None:
    user = make_user(is_active=False)
    user_repo = FakeUserRepo()
    user_repo.add(user)
    refresh_repo = FakeRefreshRepo()
    refresh_repo.records["rt-1"] = make_refresh_record()
    svc, session = make_service(user_repo=user_repo, refresh_repo=refresh_repo)

    with pytest.raises(UnauthorizedException):
        await_result(svc.refresh(FAKE_REFRESH))

    assert refresh_repo.events == []
    assert session.commits == 0


def test_refresh_old_token_becomes_unusable() -> None:
    user = make_user()
    user_repo = FakeUserRepo()
    user_repo.add(user)
    refresh_repo = FakeRefreshRepo()
    refresh_repo.records["rt-1"] = make_refresh_record()
    svc, _ = make_service(user_repo=user_repo, refresh_repo=refresh_repo)

    await_result(svc.refresh(FAKE_REFRESH))

    old = refresh_repo.records["rt-1"]
    # After rotation the old record is revoked (reuse → generic failure).
    assert old.revoked_at is not None
    assert refresh_repo.is_active(old) is False


# ============================================================================
# TRANSACTION SAFETY (refresh rotation must not commit partially)
# ============================================================================


def test_refresh_rotation_rolls_back_on_mid_flow_failure() -> None:
    user = make_user()
    user_repo = FakeUserRepo()
    user_repo.add(user)
    refresh_repo = FakeRefreshRepo()
    refresh_repo.records["rt-1"] = make_refresh_record()

    class _BrokenRefreshRepo(FakeRefreshRepo):
        async def create_refresh_token(self, **kwargs):
            raise RuntimeError("simulated DB failure")

    broken = _BrokenRefreshRepo()
    broken.records["rt-1"] = make_refresh_record()
    svc, session = make_service(user_repo=user_repo, refresh_repo=broken)

    with pytest.raises(RuntimeError):
        await_result(svc.refresh(FAKE_REFRESH))

    assert session.commits == 0
    assert session.rollbacks == 1


def test_refresh_rotation_commits_exactly_once_on_success() -> None:
    user = make_user()
    user_repo = FakeUserRepo()
    user_repo.add(user)
    refresh_repo = FakeRefreshRepo()
    refresh_repo.records["rt-1"] = make_refresh_record()
    svc, session = make_service(user_repo=user_repo, refresh_repo=refresh_repo)

    await_result(svc.refresh(FAKE_REFRESH))

    assert session.commits == 1
    assert session.rollbacks == 0


# ============================================================================
# LOGOUT
# ============================================================================


def test_logout_revokes_valid_token() -> None:
    refresh_repo = FakeRefreshRepo()
    refresh_repo.records["rt-1"] = make_refresh_record()
    svc, session = make_service(refresh_repo=refresh_repo)

    result = await_result(svc.logout(FAKE_REFRESH))

    assert isinstance(result, LogoutResponse)
    assert ("revoke", "rt-1") in refresh_repo.events
    assert session.commits == 1
    assert FAKE_REFRESH not in result.model_dump().values()


def test_logout_repeated_is_safe() -> None:
    refresh_repo = FakeRefreshRepo()
    refresh_repo.records["rt-1"] = make_refresh_record()
    svc, session = make_service(refresh_repo=refresh_repo)

    await_result(svc.logout(FAKE_REFRESH))
    await_result(svc.logout(FAKE_REFRESH))

    assert session.commits == 2
    assert ("revoke", "rt-1") in refresh_repo.events


def test_logout_unknown_token_does_not_leak() -> None:
    svc, session = make_service()

    result = await_result(svc.logout("nonexistent-token"))

    assert isinstance(result, LogoutResponse)
    assert session.commits == 0
    assert session.rollbacks == 0
    assert "Successfully logged out" in result.message


# ============================================================================
# CURRENT USER
# ============================================================================


def test_get_current_user_existing_active() -> None:
    repo = FakeUserRepo()
    repo.add(make_user())
    svc, _ = make_service(user_repo=repo)

    result = await_result(svc.get_current_user("u-1"))

    assert isinstance(result, UserOut)
    assert result.id == "u-1"
    assert "password_hash" not in result.model_dump()


def test_get_current_user_missing() -> None:
    svc, _ = make_service()
    with pytest.raises(EntityNotFoundException):
        await_result(svc.get_current_user("missing"))


def test_get_current_user_inactive() -> None:
    repo = FakeUserRepo()
    repo.add(make_user(is_active=False))
    svc, _ = make_service(user_repo=repo)

    with pytest.raises(UnauthorizedException):
        await_result(svc.get_current_user("u-1"))


# ============================================================================
# VERIFICATION (documented boundary — D7)
# ============================================================================


def test_verify_raises_documented_boundary() -> None:
    svc, _ = make_service()
    with pytest.raises(NotImplementedError) as exc_info:
        await_result(svc.verify("some-token"))
    assert "verification-token" in str(exc_info.value)
    assert "approved Task 3 database scope" in str(exc_info.value)


# ============================================================================
# FORGOT PASSWORD (D8 — enumeration-safe)
# ============================================================================


def test_forgot_password_identical_generic_response_for_existing_and_unknown() -> None:
    repo = FakeUserRepo()
    repo.add(make_user())
    svc, session = make_service(user_repo=repo)

    existing = await_result(svc.forgot_password("jagadeesh@example.com"))
    unknown = await_result(svc.forgot_password("nobody@example.com"))

    assert isinstance(existing, ForgotPasswordResponse)
    assert isinstance(unknown, ForgotPasswordResponse)
    assert existing.message == unknown.message
    assert session.commits == 0  # enumeration-safe: no writes, no leak


# ============================================================================
# RESET PASSWORD (documented boundary — D8)
# ============================================================================


def test_reset_password_raises_documented_boundary() -> None:
    svc, _ = make_service()
    with pytest.raises(NotImplementedError) as exc_info:
        await_result(svc.reset_password("reset-token", "NewStrongPass456"))
    assert "reset-token" in str(exc_info.value)
    assert "approved Task 3 database scope" in str(exc_info.value)


# ============================================================================
# Helpers
# ============================================================================


def await_result(coro):
    """Run a coroutine on the current event loop (sync-test convention)."""
    import asyncio

    return asyncio.run(coro)