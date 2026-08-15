"""Tests for API dependency wiring (Sprint 2, Task 3, Stage 4).

Uses the existing lazy engine infrastructure (no live database connection):
- ``get_db`` must be the foundation session dependency (single wiring point)
- ``get_db`` raises clearly when the database is unconfigured
- ``get_db`` yields a real ``AsyncSession`` when a factory is configured
  (session creation is lazy and does not connect)

``get_current_user`` / ``role_required`` stubs from Stage 4 were replaced in
Stage 7 with real implementations exercised in ``test_auth_dependencies.py``.
"""

import asyncio

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.core import database as db_module
from app.api import deps


def test_get_db_is_foundation_session_dependency() -> None:
    """api.deps.get_db must be the existing foundation get_db (single wiring point)."""
    assert deps.get_db is db_module.get_db


def test_get_db_raises_when_unconfigured() -> None:
    db_module.dispose_engine()
    assert db_module.AsyncSessionFactory is None

    async def _consume() -> None:
        async for _ in deps.get_db():
            pytest.fail("get_db() should not yield a session when unconfigured")

    with pytest.raises(RuntimeError, match="not configured"):
        asyncio.run(_consume())


def test_get_db_yields_async_session_when_configured() -> None:
    """Creating a session from the lazy factory does NOT connect to Postgres."""
    db_module.configure_database("postgresql+asyncpg://u:p@localhost:5432/testdb")
    try:
        async def _consume() -> AsyncSession:
            sessions: list[AsyncSession] = []
            async for session in deps.get_db():
                sessions.append(session)
            return sessions[0]

        session = asyncio.run(_consume())
        assert isinstance(session, AsyncSession)
        asyncio.run(session.close())
    finally:
        db_module.dispose_engine()


def test_get_db_rolls_back_and_reraises_on_error() -> None:
    db_module.configure_database("postgresql+asyncpg://u:p@localhost:5432/testdb")
    try:
        class _SentinelError(RuntimeError):
            pass

        async def _consume() -> None:
            async for _ in deps.get_db():
                raise _SentinelError("boom")

        with pytest.raises(_SentinelError, match="boom"):
            asyncio.run(_consume())
    finally:
        db_module.dispose_engine()