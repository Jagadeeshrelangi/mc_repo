"""Pytest fixtures for the Mecha Connect backend."""

import asyncio
from typing import Generator

import pytest

from app.core import database as db_module


@pytest.fixture(scope="session")
def event_loop() -> Generator[asyncio.AbstractEventLoop, None, None]:
    """Provide a session-scoped event loop for async tests."""
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(autouse=True)
def _reset_database_state():
    """Isolate database module state before/after each test.

    Tests never connect to a database; they validate the foundation's
    configuration and lazy wiring. We always leave the module unconfigured to
    avoid leaking a configured engine across tests.
    """
    db_module.dispose_engine()
    yield
    db_module.dispose_engine()