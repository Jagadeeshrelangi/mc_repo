"""Tests for the repository layer (Sprint 2, Task 3, Stage 4).

Test strategy without a live PostgreSQL database:
- repository construction with an injected (mock) AsyncSession
- SQL statement generation — statements passed to the session are captured
  and compiled against the PostgreSQL dialect (no connection required)
- model/query contract and field mutations

PostgreSQL server-side behavior (actual execution, constraint enforcement,
gen_random_uuid()) is NOT faked and remains documented as requiring a live DB.
"""

import asyncio
from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock, Mock

from sqlalchemy import select
from sqlalchemy.dialects import postgresql
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User, UserRole
from app.models.refresh_token import RefreshToken
from app.repositories.base import BaseRepository
from app.repositories.users import RefreshTokenRepository, UserRepository


def make_session() -> AsyncMock:
    """Build an AsyncSession mock.

    ``add`` is synchronous on the real AsyncSession, so it is a plain Mock;
    the async methods (``delete``, ``scalar``, ``scalars``, ``flush``, ...)
    stay AsyncMocks.
    """
    session = AsyncMock(spec=AsyncSession)
    session.add = Mock()
    return session


def compile_stmt(stmt) -> str:
    """Compile a SQLAlchemy statement to PostgreSQL SQL text (literal binds)."""
    return str(
        stmt.compile(
            dialect=postgresql.dialect(),
            compile_kwargs={"literal_binds": True},
        )
    )


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


# --- Construction / query contract ------------------------------------------


def test_user_repository_construction_injects_session() -> None:
    session = make_session()
    repo = UserRepository(session)
    assert repo.session is session
    assert repo.model is User


def test_refresh_token_repository_construction_injects_session() -> None:
    session = make_session()
    repo = RefreshTokenRepository(session)
    assert repo.session is session
    assert repo.model is RefreshToken


def test_base_repository_is_generic_contract() -> None:
    """BaseRepository is generic and expects a concrete ``model`` subclass."""
    assert BaseRepository.__mro__[0] is BaseRepository
    # Concrete repos are required to set ``model``.
    assert UserRepository.model is User
    assert RefreshTokenRepository.model is RefreshToken


def test_get_by_email_generates_correct_sql() -> None:
    session = make_session()
    session.scalar.return_value = None
    repo = UserRepository(session)
    asyncio.run(repo.get_by_email("user@example.com"))

    stmt = session.scalar.call_args.args[0]
    sql = compile_stmt(stmt)
    assert "FROM users" in sql
    assert "users.email" in sql


def test_get_by_phone_generates_correct_sql() -> None:
    session = make_session()
    session.scalar.return_value = None
    repo = UserRepository(session)
    asyncio.run(repo.get_by_phone("+911234567890"))

    stmt = session.scalar.call_args.args[0]
    sql = compile_stmt(stmt)
    assert "FROM users" in sql
    assert "users.phone" in sql


def test_get_by_digest_generates_correct_sql() -> None:
    session = make_session()
    session.scalar.return_value = None
    repo = RefreshTokenRepository(session)
    asyncio.run(repo.get_by_digest("a" * 64))

    stmt = session.scalar.call_args.args[0]
    sql = compile_stmt(stmt)
    assert "FROM refresh_tokens" in sql
    assert "refresh_tokens.token_digest" in sql


def test_get_by_jti_generates_correct_sql() -> None:
    session = make_session()
    session.scalar.return_value = None
    repo = RefreshTokenRepository(session)
    asyncio.run(repo.get_by_jti("some-jti"))

    stmt = session.scalar.call_args.args[0]
    sql = compile_stmt(stmt)
    assert "FROM refresh_tokens" in sql
    assert "refresh_tokens.jti" in sql


def test_list_generates_filtered_sql() -> None:
    session = make_session()
    session.scalars.return_value.all.return_value = []
    repo = UserRepository(session)
    asyncio.run(repo.list(role="admin", limit=5))

    stmt = session.scalars.call_args.args[0]
    sql = compile_stmt(stmt)
    assert "FROM users" in sql
    assert "users.role" in sql
    assert "LIMIT" in sql and "5" in sql


def test_get_by_primary_key_uses_session_get() -> None:
    session = make_session()
    expected = User(id="abc", name="n", email="e@x.com", phone="p")
    session.get.return_value = expected
    repo = UserRepository(session)

    result = asyncio.run(repo.get("abc"))
    assert result is expected
    session.get.assert_awaited_once_with(User, "abc")


# --- User write operations (no commit) --------------------------------------


def test_create_user_persists_without_commit() -> None:
    session = make_session()
    repo = UserRepository(session)

    user = asyncio.run(
        repo.create_user(
            name="Alice",
            email="alice@example.com",
            phone="+911234567890",
            password_hash="$2b$12$fakehash",
            role=UserRole.CUSTOMER,
        )
    )

    session.add.assert_called_once()
    added: User = session.add.call_args.args[0]
    assert added.name == "Alice"
    assert added.email == "alice@example.com"
    assert added.phone == "+911234567890"
    assert added.password_hash == "$2b$12$fakehash"
    assert added.role == "customer"
    session.flush.assert_awaited_once()
    session.commit.assert_not_called()  # commit is owned by the caller
    assert user is added


def test_record_successful_login_updates_fields_without_commit() -> None:
    session = make_session()
    repo = UserRepository(session)
    user = User(id="u1", name="n", email="e@x.com", phone="p", failed_login_attempts=3)

    asyncio.run(repo.record_successful_login(user))

    assert user.last_login_at is not None
    assert user.failed_login_attempts == 0
    session.flush.assert_awaited_once()
    session.commit.assert_not_called()


def test_record_failed_login_increments_without_commit() -> None:
    session = make_session()
    repo = UserRepository(session)
    user = User(id="u1", name="n", email="e@x.com", phone="p", failed_login_attempts=2)

    asyncio.run(repo.record_failed_login(user))

    assert user.failed_login_attempts == 3
    session.flush.assert_awaited_once()
    session.commit.assert_not_called()


def test_clear_login_failures_resets_counter() -> None:
    session = make_session()
    repo = UserRepository(session)
    user = User(id="u1", name="n", email="e@x.com", phone="p", failed_login_attempts=5)

    asyncio.run(repo.clear_login_failures(user))

    assert user.failed_login_attempts == 0
    session.flush.assert_awaited_once()


def test_lock_account_sets_lockout_at() -> None:
    session = make_session()
    repo = UserRepository(session)
    user = User(id="u1", name="n", email="e@x.com", phone="p")
    when = utcnow() + timedelta(minutes=10)

    asyncio.run(repo.lock_account(user, when))

    assert user.lockout_at == when
    session.flush.assert_awaited_once()


def test_unlock_account_clears_lockout_and_failures() -> None:
    session = make_session()
    repo = UserRepository(session)
    user = User(
        id="u1", name="n", email="e@x.com", phone="p",
        lockout_at=utcnow(), failed_login_attempts=5,
    )

    asyncio.run(repo.unlock_account(user))

    assert user.lockout_at is None
    assert user.failed_login_attempts == 0
    session.flush.assert_awaited_once()


# --- Refresh-token data access ----------------------------------------------


def test_create_refresh_token_persists_digest_without_commit() -> None:
    session = make_session()
    repo = RefreshTokenRepository(session)
    expires = utcnow() + timedelta(days=7)

    record = asyncio.run(
        repo.create_refresh_token(
            user_id="u1", token_digest="a" * 64, jti="jti-1", expires_at=expires,
        )
    )

    session.add.assert_called_once()
    added: RefreshToken = session.add.call_args.args[0]
    assert added.user_id == "u1"
    assert added.token_digest == "a" * 64
    assert added.jti == "jti-1"
    assert added.expires_at == expires
    assert added.revoked_at is None
    assert added.replaced_by_id is None
    session.flush.assert_awaited_once()
    session.commit.assert_not_called()
    assert record is added


def test_revoke_sets_revoked_at_without_commit() -> None:
    session = make_session()
    repo = RefreshTokenRepository(session)
    record = RefreshToken(id="rt1", user_id="u1", token_digest="a" * 64, jti="j", expires_at=utcnow())

    asyncio.run(repo.revoke(record))

    assert record.revoked_at is not None
    session.flush.assert_awaited_once()
    session.commit.assert_not_called()


def test_mark_replaced_sets_replacement_id() -> None:
    session = make_session()
    repo = RefreshTokenRepository(session)
    record = RefreshToken(id="rt1", user_id="u1", token_digest="a" * 64, jti="j", expires_at=utcnow())

    asyncio.run(repo.mark_replaced(record, "rt2"))

    assert record.replaced_by_id == "rt2"
    session.flush.assert_awaited_once()


def test_is_active_true_for_live_token() -> None:
    repo = RefreshTokenRepository(make_session())
    live = RefreshToken(
        id="rt1", user_id="u1", token_digest="a" * 64, jti="j",
        expires_at=utcnow() + timedelta(days=1), revoked_at=None,
    )
    assert repo.is_active(live) is True


def test_is_active_false_when_revoked() -> None:
    repo = RefreshTokenRepository(make_session())
    revoked = RefreshToken(
        id="rt1", user_id="u1", token_digest="a" * 64, jti="j",
        expires_at=utcnow() + timedelta(days=1),
        revoked_at=utcnow(),
    )
    assert repo.is_active(revoked) is False


def test_is_active_false_when_expired() -> None:
    repo = RefreshTokenRepository(make_session())
    expired = RefreshToken(
        id="rt1", user_id="u1", token_digest="a" * 64, jti="j",
        expires_at=utcnow() - timedelta(seconds=1), revoked_at=None,
    )
    assert repo.is_active(expired) is False


# --- Repository never auto-commits ------------------------------------------


def test_repository_write_operations_never_commit() -> None:
    """Read and write ops must leave commit ownership to the caller."""
    session = make_session()
    user_repo = UserRepository(session)
    user = User(id="u1", name="n", email="e@x.com", phone="p")

    asyncio.run(user_repo.create_user(name="b", email="b@x.com", phone="p2"))
    asyncio.run(user_repo.record_failed_login(user))
    asyncio.run(user_repo.delete(user))

    assert session.commit.call_count == 0