"""Tests for the D10 process-local auth rate limiter + dependency wiring.

Strategy: the ``RateLimiter`` takes an injectable clock, so every test advances
a fake clock deterministically — no real 60-second waits. The API-level test
exercises the FastAPI dependency via a TestClient on a minimal app that mounts
only the auth router (no live PostgreSQL, no AI stack).
"""

import pytest

from app.api import deps
from app.core.rate_limit import RateLimiter
from app.api.v1.auth import router as auth_router


class FakeClock:
    """Deterministic monotonic-ish clock for the rate limiter."""

    def __init__(self, start: float = 0.0) -> None:
        self._now = start

    def __call__(self) -> float:
        return self._now

    def advance(self, seconds: float) -> None:
        self._now += seconds


# ============================================================================
# RateLimiter unit tests (injectable clock, no sleeping)
# ============================================================================


def test_allows_first_ten_requests_within_window() -> None:
    clock = FakeClock()
    limiter = RateLimiter(max_requests=10, window_seconds=60, clock=clock)
    for _ in range(10):
        assert limiter.allow("client-1") is True


def test_rejects_eleventh_request_within_window() -> None:
    clock = FakeClock()
    limiter = RateLimiter(max_requests=10, window_seconds=60, clock=clock)
    for _ in range(10):
        limiter.allow("client-1")
    assert limiter.allow("client-1") is False


def test_allows_again_after_window_elapses() -> None:
    clock = FakeClock()
    limiter = RateLimiter(max_requests=10, window_seconds=60, clock=clock)
    for _ in range(10):
        limiter.allow("client-1")
    assert limiter.allow("client-1") is False
    clock.advance(61)
    assert limiter.allow("client-1") is True


def test_keys_are_independent() -> None:
    clock = FakeClock()
    limiter = RateLimiter(max_requests=2, window_seconds=60, clock=clock)
    limiter.allow("client-a")
    limiter.allow("client-a")
    assert limiter.allow("client-a") is False
    assert limiter.allow("client-b") is True


def test_reset_clears_single_key() -> None:
    clock = FakeClock()
    limiter = RateLimiter(max_requests=1, window_seconds=60, clock=clock)
    limiter.allow("client-1")
    assert limiter.allow("client-1") is False
    limiter.reset("client-1")
    assert limiter.allow("client-1") is True


def test_reset_all_clears_every_key() -> None:
    clock = FakeClock()
    limiter = RateLimiter(max_requests=1, window_seconds=60, clock=clock)
    limiter.allow("client-a")
    limiter.allow("client-b")
    limiter.reset()
    assert limiter.allow("client-a") is True
    assert limiter.allow("client-b") is True


def test_invalid_constructor_arguments_rejected() -> None:
    with pytest.raises(ValueError):
        RateLimiter(max_requests=0)
    with pytest.raises(ValueError):
        RateLimiter(window_seconds=0)


# ============================================================================
# API-level: the FastAPI dependency applied to the auth router (D10)
# ============================================================================


def _build_client(monkeypatch):
    """Mount ONLY the auth router (no AI stack, no DB) and isolate the limiter."""
    from fastapi import FastAPI
    from fastapi.testclient import TestClient

    app = FastAPI()
    app.include_router(auth_router, prefix="/api/v1/auth")

    async def _default_db():
        yield object()

    from app.api.deps import get_db

    app.dependency_overrides[get_db] = _default_db
    monkeypatch.setattr(
        deps,
        "auth_rate_limiter",
        RateLimiter(max_requests=10, window_seconds=60, clock=FakeClock()),
    )
    return TestClient(app)


def test_api_eleventh_request_rejected_within_window(monkeypatch) -> None:
    from fastapi import FastAPI
    from fastapi.testclient import TestClient
    from app.api.deps import get_db

    app = FastAPI()
    app.include_router(auth_router, prefix="/api/v1/auth")

    async def _default_db():
        yield object()

    app.dependency_overrides[get_db] = _default_db
    monkeypatch.setattr(
        deps,
        "auth_rate_limiter",
        RateLimiter(max_requests=10, window_seconds=60, clock=FakeClock()),
    )
    client = TestClient(app)

    # /forgot-password is enumeration-safe and requires no DB/service writes,
    # so it is a clean target for rate-limit testing without a live database.
    body = {"identifier": "jagadeesh@example.com"}
    for _ in range(10):
        response = client.post("/api/v1/auth/forgot-password", json=body)
        assert response.status_code == 200

    eleventh = client.post("/api/v1/auth/forgot-password", json=body)
    assert eleventh.status_code == 429
    assert "Too many requests" in eleventh.json()["detail"]


def test_api_rate_limit_window_restores_access(monkeypatch) -> None:
    from fastapi import FastAPI
    from fastapi.testclient import TestClient

    clock = FakeClock()
    app = FastAPI()
    app.include_router(auth_router, prefix="/api/v1/auth")

    from app.api.deps import get_db

    async def _default_db():
        yield object()

    app.dependency_overrides[get_db] = _default_db
    monkeypatch.setattr(
        deps,
        "auth_rate_limiter",
        RateLimiter(max_requests=3, window_seconds=60, clock=clock),
    )
    client = TestClient(app)

    body = {"identifier": "jagadeesh@example.com"}
    for _ in range(3):
        assert client.post("/api/v1/auth/forgot-password", json=body).status_code == 200
    assert client.post("/api/v1/auth/forgot-password", json=body).status_code == 429

    clock.advance(61)
    assert client.post("/api/v1/auth/forgot-password", json=body).status_code == 200


def test_rate_limiter_not_applied_outside_auth_router(monkeypatch) -> None:
    """The limiter is scoped to the auth router; other routers are unaffected."""
    from fastapi import FastAPI
    from fastapi.testclient import TestClient

    app = FastAPI()

    @app.get("/health")
    async def health():
        return {"status": "healthy"}

    app.include_router(auth_router, prefix="/api/v1/auth")

    from app.api.deps import get_db

    async def _default_db():
        yield object()

    app.dependency_overrides[get_db] = _default_db
    monkeypatch.setattr(
        deps,
        "auth_rate_limiter",
        RateLimiter(max_requests=1, window_seconds=60, clock=FakeClock()),
    )
    client = TestClient(app)

    # The non-auth route is never rate-limited, even after the auth limiter
    # is exhausted for the same client.
    body = {"identifier": "jagadeesh@example.com"}
    assert client.post("/api/v1/auth/forgot-password", json=body).status_code == 200
    assert client.post("/api/v1/auth/forgot-password", json=body).status_code == 429
    assert client.get("/health").status_code == 200