"""Database foundation for Mecha Connect backend.

SQLAlchemy 2.x async setup targeting PostgreSQL via asyncpg.

The engine is created from ``settings.DATABASE_URL`` (or an explicit URL).
If no URL is configured, ``engine`` and ``AsyncSessionFactory`` stay ``None``
so the application can still boot and serve the AI/health endpoints without a
live database (Sprint 2 pattern: no database dependency at import time).
"""

from collections.abc import AsyncIterator
from typing import Any, Optional

from sqlalchemy import text
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase

from app.core.config import settings
from app.core.logging import logger


class Base(DeclarativeBase):
    """Declarative base for all SQLAlchemy ORM models (added in later tasks)."""


engine: Optional[AsyncEngine] = None
AsyncSessionFactory: Optional[async_sessionmaker[AsyncSession]] = None


def configure_database(url: Optional[str] = None) -> None:
    """Create (or reload) the async engine and session factory.

    Passing ``None``/empty URL leaves the database unconfigured so the app
    keeps booting without a database. Re-running with a new URL disposes the
    previous engine (idempotent; useful in tests).
    """
    global engine, AsyncSessionFactory

    configured_url = url or settings.DATABASE_URL

    if not configured_url:
        if engine is not None:
            raise RuntimeError(
                "configure_database() without a URL while an engine is already configured."
            )
        logger.warning(
            "Database not configured: DATABASE_URL is unset. DB-dependent features are disabled."
        )
        engine = None
        AsyncSessionFactory = None
        return

    if not configured_url.startswith("postgresql"):
        logger.warning(
            f"DATABASE_URL uses a non-PostgreSQL scheme: {configured_url.split('@')[-1]}. "
            "Sprint 2 target is PostgreSQL via asyncpg."
        )

    if engine is not None:
        engine.sync_engine.dispose()

    engine = create_async_engine(
        configured_url,
        echo=False,
        pool_pre_ping=True,
        pool_size=5,
        max_overflow=10,
    )
    AsyncSessionFactory = async_sessionmaker(
        engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )
    logger.info("Async SQLAlchemy engine created for Mecha Connect backend.")


async def get_db() -> AsyncIterator[AsyncSession]:
    """FastAPI dependency yielding an async database session.

    Yields a session for the lifetime of a request. On error the session is
    rolled back and re-raised; committed explicitly by the caller/service.
    """
    if AsyncSessionFactory is None:
        raise RuntimeError("Database is not configured. Set DATABASE_URL in backend/.env.")
    async with AsyncSessionFactory() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise


async def check_database() -> bool:
    """Run a trivial connectivity query (`SELECT 1`) against the DB."""
    if AsyncSessionFactory is None:
        return False
    async with AsyncSessionFactory() as session:
        result = await session.execute(text("SELECT 1"))
        return result.scalar() == 1


def dispose_engine() -> None:
    """Dispose the engine (used by tests / lifecycle teardown)."""
    global engine, AsyncSessionFactory
    if engine is not None:
        engine.sync_engine.dispose()
    engine = None
    AsyncSessionFactory = None


# Expose the engine type alias for annotations elsewhere.
AsyncEngineType: Any = AsyncEngine