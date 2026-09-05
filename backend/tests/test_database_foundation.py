"""Tests for the Sprint 2 database foundation (Task 2).

These tests validate the *configuration* and *lazy wiring* of the async
SQLAlchemy stack WITHOUT requiring a live PostgreSQL server. A second
database system is intentionally not used (per Sprint 2 constraints), so no
live queries are executed here.

Live connectivity is verified separately via `scripts/db_check.py` when a
PostgreSQL instance is available.
"""

import asyncio
from typing import AsyncIterator

import pytest

from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase

from app.core import database as db_module
from app.core.database import Base
from app.core.config import settings


def test_base_is_declarative() -> None:
    """The shared Base must be a SQLAlchemy 2.x DeclarativeBase."""
    assert issubclass(Base, DeclarativeBase)


def test_unconfigured_state_initial(monkeypatch: pytest.MonkeyPatch) -> None:
    """Without DATABASE_URL the engine/factory must not exist."""
    monkeypatch.setattr(settings, "DATABASE_URL", None)
    asyncio.run(db_module.dispose_engine())
    asyncio.run(db_module.configure_database(None))
    assert db_module.engine is None
    assert db_module.AsyncSessionFactory is None


def test_configure_creates_engine() -> None:
    """configure_database() with a valid asyncpg URL creates a lazy engine.

    Engine creation does NOT connect; this passes with no Postgres running.
    """
    asyncio.run(db_module.configure_database("postgresql+asyncpg://u:p@localhost:5432/testdb"))
    try:
        assert isinstance(db_module.engine, AsyncEngine)
        assert isinstance(db_module.AsyncSessionFactory, async_sessionmaker)
        assert db_module.engine.url.get_backend_name() == "postgresql"
        assert db_module.engine.url.get_driver_name() == "asyncpg"
    finally:
        asyncio.run(db_module.dispose_engine())


def test_session_factory_produces_async_session() -> None:
    """The session factory must produce AsyncSession objects (lazy, no connect)."""
    asyncio.run(db_module.configure_database("postgresql+asyncpg://u:p@localhost:5432/testdb"))
    try:
        factory = db_module.AsyncSessionFactory
        assert isinstance(factory, async_sessionmaker)
        session = factory()
        assert isinstance(session, AsyncSession)
        asyncio.run(session.close())  # AsyncSession.close() is a coroutine; await it
    finally:
        asyncio.run(db_module.dispose_engine())


def test_reconfigure_disposes_previous_engine() -> None:
    """Calling configure_database() twice with a new URL must not leak engines."""
    asyncio.run(db_module.configure_database("postgresql+asyncpg://u:p@localhost:5432/a"))
    first_engine = db_module.engine
    asyncio.run(db_module.configure_database("postgresql+asyncpg://u:p@localhost:5432/b"))
    second_engine = db_module.engine
    try:
        assert first_engine is not second_engine
        assert second_engine.url.database == "b"
    finally:
        asyncio.run(db_module.dispose_engine())


def test_dispose_engine_clears_state() -> None:
    asyncio.run(db_module.configure_database("postgresql+asyncpg://u:p@localhost:5432/a"))
    asyncio.run(db_module.dispose_engine())
    assert db_module.engine is None
    assert db_module.AsyncSessionFactory is None


def test_get_db_raises_when_unconfigured(monkeypatch: pytest.MonkeyPatch) -> None:
    """get_db() must raise a clear error when the DB is not configured."""
    monkeypatch.setattr(settings, "DATABASE_URL", None)
    asyncio.run(db_module.dispose_engine())
    asyncio.run(db_module.configure_database(None))
    assert db_module.AsyncSessionFactory is None

    async def _consume() -> None:
        gen: AsyncIterator[AsyncSession] = db_module.get_db()
        async for _ in gen:
            pytest.fail("get_db() should not yield a session when unconfigured")

    with pytest.raises(RuntimeError, match="not configured"):
        asyncio.run(_consume())


def test_check_database_false_when_unconfigured(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(settings, "DATABASE_URL", None)
    asyncio.run(db_module.dispose_engine())
    asyncio.run(db_module.configure_database(None))

    assert asyncio.run(db_module.check_database()) is False
