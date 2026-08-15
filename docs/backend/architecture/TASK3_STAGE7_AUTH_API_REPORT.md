# TASK3_STAGE7_AUTH_API_REPORT.md

**Sprint 2 | Task 3: Authentication Foundation**
**Stage 7: Auth API Routes + Dependency Wiring + Rate Limiting**
**Date:** 2026-08-15

---

## 1. Executive Summary

- Created **`backend/app/api/v1/auth.py`** — 8 thin HTTP endpoints
  (register, login, refresh, verify, forgot-password, reset-password, me,
  logout) wrapping `AuthService`. Routes contain **no business logic**: no
  hashing, no JWT creation, no SQLAlchemy queries, no lockout/rotation policy.
- Replaced the Stage 4 **`get_current_user` / `role_required` stubs** in
  `backend/app/api/deps.py` with real implementations: Bearer access-token
  verification via `security.verify_access_token()` + `UserRepository`, plus a
  router-scoped **D10 process-local rate limiter** (10 requests/minute).
- Mounted the auth router at **`/api/v1/auth`** in `router.py`.
- Verification and reset-password **surface their documented Stage 6 boundary
  as HTTP 501** — never a fake success.
- Full suite: **209 passed** (172 → 209; +39 new, −2 obsolete stub tests).
  Real app imports cleanly, OpenAPI path count **6 → 14** (8 auth + 6 existing).

## 2. Route Table

All endpoints under `GET/POST /api/v1/auth`; every handler constructs
`AuthService(session)` and delegates to a single service method (verify/reset
additionally map the Stage 6 `NotImplementedError` boundary to 501). Exact
Stage 5 schemas are reused as-is.

| Method | Path               | Status | Schema (req → resp)              |
|--------|--------------------|--------|----------------------------------|
| POST   | `/register`        | 201    | `RegisterRequest` → `UserOut`    |
| POST   | `/login`           | 200    | `LoginRequest` → `TokenResponse` |
| POST   | `/refresh`         | 200    | `RefreshRequest` → `TokenResponse` |
| POST   | `/verify`          | 501    | `VerifyRequest` → documented boundary |
| POST   | `/forgot-password` | 200    | `ForgotPasswordRequest` → `ForgotPasswordResponse` |
| POST   | `/reset-password`  | 501    | `ResetPasswordRequest` → documented boundary |
| GET    | `/me`              | 200    | (auth) → `CurrentUserResponse`   |
| POST   | `/logout`          | 200    | `LogoutRequest` → `LogoutResponse` |

The router is registered with
`dependencies=[Depends(get_auth_rate_limit)]` so **rate limiting applies to
every auth endpoint** and only to auth endpoints.

## 3. Dependency Wiring (`app/api/deps.py`)

- **`get_db`** remains a re-export of the foundation session dependency
  (`app.core.database.get_db`) — single wiring point (identity asserted by
  test).
- **`get_current_user`**:
  1. `HTTPBearer(auto_error=False)` — missing/malformed header → generic 401.
  2. `security.verify_access_token()` — expired, tampered, wrong-secret, or
     **wrong-type** (a refresh token) → `security.SecurityError` → generic
     `UnauthorizedException("Invalid or expired access token")` (no jose leaks).
  3. `UserRepository(session).get(claims["sub"])` — missing → `EntityNotFoundException` (404).
  4. Inactive account → `UnauthorizedException` (401).
  5. Returns the ORM `User`; serialization to `CurrentUserResponse` is left to
     the `/me` route.
- **`role_required(*roles)`**: dependency factory over `get_current_user`;
  `user.role not in allowed` → generic `UnauthorizedException`. Uses the
  **approved D3 string values** (`UserRole.VALUES` — no second role enum; a
  test asserts `set(UserRoleLiteral.__args__) == set(UserRole.VALUES)`).
- **`get_auth_rate_limit(request)`**: D10 limiter keyed on
  `request.client.host`; over the limit → `HTTPException(429)`. Module-level
  instance `auth_rate_limiter` is swapped by tests for a deterministic clock.

## 4. Rate Limiting (D10) — `app/core/rate_limit.py`

New isolated module `RateLimiter(max_requests=10, window_seconds=60, clock=None)`:

- **Process-local in-memory** sliding-window store (per client key), guarded by
  a `threading.Lock`; prunes entries older than the window.
- **Injectable clock** (default `time.monotonic`) — tests advance a `FakeClock`,
  never sleeping 60 s.
- `allow(key) -> bool`, `reset(key=None)`.
- Applied **only** to auth endpoints via the router dependency; `/health` and
  AI routes are never rate-limited (asserted by test).
- No Redis, no external state, no new dependencies.

## 5. /auth/me

- Depends on the real `get_current_user` (Bearer access token).
- Returns `CurrentUserResponse` — the safe projection: `id`, `name`, `email`,
  `phone`, `role`, `is_active`, `is_verified`, `membership_tier`, `joined_at`.
  Never `password_hash`, token digests, JWT secrets, `failed_login_attempts`,
  `lockout_at`, or `last_login_at` (asserted by test on a fully-populated user).
- Missing `Authorization` → 401; malformed token → 401; refresh token → 401;
  inactive user → 401; unknown `sub` → 404.

## 6. Verify (documented boundary — 501)

`POST /auth/verify` calls `AuthService.verify(token)` and maps the Stage 6
`NotImplementedError` boundary to **`HTTPException(501)`**. It does **not**
invent verification-token storage, a token type, an email/SMS provider, or a
fake success. The approved Task 3 DB scope (D13) has no verification-token
persistence.

## 7. Reset Password (documented boundary — 501)

`POST /auth/reset-password` calls `AuthService.reset_password(token,
new_password)` and maps the Stage 6 `NotImplementedError` boundary to
**`HTTPException(501)`**. No reset-token persistence exists in the approved
scope (D8/F2); no fake success is returned.

## 8. Forgot Password (enumeration-safe)

`POST /auth/forgot-password` delegates to
`AuthService.forgot_password(identifier)` — the enumeration-safe generic
message (D8) with no lookup and no writes. The route performs no identifier
resolution; it cannot be used to enumerate accounts.

## 9. Thinness Invariant (routes)

Route handlers contain **no** business rules. Each is a construction of
`AuthService(session)` + one service call (+ optional 501 mapping). Hash,
JWT, digest, lockout, and rotation policy remain exclusively in
`AuthService` / the security engine (verified by code review + tests that
patch `AuthService` methods at the class level and assert the route only
forwards).

## 10. Exception Mapping

- `MechaException` → `app.main` handlers (unchanged): `UNAUTHORIZED`→401,
  `NOT_FOUND`→404, `BAD_REQUEST`→400, `INFERENCE_FAILED`→422.
- `HTTPException(429)` (rate limit) and `HTTPException(501)` (boundaries) use
  FastAPI/Starlette's built-in handlers — no change to `main.py`.
- Security-engine errors are converted to generic `UnauthorizedException` in
  `deps.get_current_user` (no jose internals surface).

## 11. Router Mounting

`router.py` mounts:
- `auth.router` at `prefix="/auth"` (new)
- `diagnosis`, `knowledge`, `conversation` (unchanged)

Real-app OpenAPI paths: **14** (8 auth + `/health` + 3 conversation +
diagnosis + knowledge). AI routes remain intact.

## 12. Runtime Behavior Without Live DB (POSTGRES LIMITATION)

`.env` has **no `DATABASE_URL`**, so every auth route resolves `get_db` → the
documented `RuntimeError("Database is not configured")` → the generic 500
handler. Verified live: `/health` → 200 (`database: "not_configured"`);
all 8 auth routes respond with the DB-not-configured path (HTTP 500 via the
generic handler). This is **expected and honest** — no live migrations were
run and no fake DB success is reported. Route logic itself is exercised
against fake sessions in the test suite.

## 13. Tests

### `tests/test_auth_rate_limit.py` — 10 tests
- **Unit (7)**: first 10 allowed; 11th rejected; window elapse restores;
  keys independent; single-key reset; full reset; invalid args rejected.
- **API (3)**: 11th request → 429 (with `FakeClock`); window restore → 200;
  non-auth `/health` unaffected while auth limiter exhausted.

### `tests/test_auth_dependencies.py` — 10 tests
- Real `get_current_user`: missing/malformed credentials → 401; valid access
  token accepted; **refresh token rejected as access**; inactive user rejected;
  missing user → `EntityNotFoundException`.
- Real `role_required`: matching role allowed; other roles rejected generically;
  **single-source roles** (`UserRoleLiteral` == `UserRole.VALUES`, exactly 3).
- Safe `UserOut` serialization (no secrets).

### `tests/test_auth_api.py` — 19 tests
Minimal FastAPI app mirroring `main.py`'s `MechaException` mapping; mounts only
the auth router (no heavy AI import); per-test `FakeSession` via
`dependency_overrides[get_db]`; `AuthService` methods patched at class level;
rate limiter isolated.
- **Register (3)**: reaches service + safe response; 422 validation; duplicate → 400.
- **Login (3)**: valid → tokens; invalid credentials → generic 401;
  inactive account → generic 401.
- **Refresh (2)**: valid rotation; invalid token → generic 401.
- **Logout (2)**: success; idempotent repeat.
- **Me (6)**: missing auth → 401; malformed → 401; access token accepted;
  **refresh token rejected**; inactive rejected; safe fields only.
- **Verify / Reset (2)**: documented **501** boundaries.
- **Forgot password (1)**: enumeration-safe generic response.

### `tests/test_api_dependencies.py` — 4 tests (2 obsolete stub tests removed)
`get_db` identity, unconfigured error, yields `AsyncSession`, rollback-on-error
retained. The Stage 4 `get_current_user`/`role_required` "pending stub" tests
were removed because Stage 7 replaced those stubs with real implementations.

## 14. Full Test Results

- `python -m pytest tests/ -q` → **209 passed** (172 → +39 new, −2 removed).
- Pre-existing `PydanticDeprecatedSince20` / `StarletteDeprecationWarning`
  warnings unchanged (project-wide `Field(example=)` convention; httpx/starlette
  TestClient notices) — no new failures.

## 15. Route Count Verification

- Before: 6 paths (3 conversation + diagnosis + knowledge + health).
- After: **14 paths** (verified via `app.openapi()` on the real app).
- The 8 auth paths each appear once; AI routes unchanged.

## 16. Real App Verification

- `from app.main import app` imports cleanly (≈16–19 s, heavy AI init; benign
  `faiss.swigfaiss_avx2` ModuleNotFoundError warning, pre-existing).
- `app.openapi()` → 14 paths; all 8 auth + all 6 existing.
- `TestClient(app)` live probes: `/health` → 200 `{"database": "not_configured"}`;
  auth endpoints reach the documented DB-not-configured path (no fake success).

## 17. Files Created/Modified

Created (Stage 7):
- `backend/app/core/rate_limit.py`
- `backend/app/api/v1/auth.py`
- `backend/tests/test_auth_rate_limit.py`
- `backend/tests/test_auth_dependencies.py`
- `backend/tests/test_auth_api.py`

Modified (Stage 7):
- `backend/app/api/deps.py` — real `get_current_user`, `role_required`, `get_auth_rate_limit`
- `backend/app/api/router.py` — mounted auth router
- `backend/tests/test_api_dependencies.py` — removed 2 obsolete stub tests

## 18. Files Explicitly Not Changed

- `backend/app/core/security.py`, `config.py`, `database.py`, `logging.py`
- `backend/app/models/**`, `backend/app/repositories/**`, `backend/app/schemas/**`
- `backend/app/services/auth_service.py` (Stage 6 — untouched)
- `backend/app/main.py`, `backend/app/core/exceptions.py`
- `backend/app/api/v1/{diagnosis,knowledge,conversation}.py`
- `backend/ai/**`, `backend/alembic/**` (no migration, no table creation)
- `frontend/**`, `backend/requirements*.txt`

## 19. Git Safety

- No `git add`, `commit`, `push`, `reset`, or `revert` performed.
- No live migrations, no DB table creation, no schema changes.

## 20. Known Limitations

- All auth routes require a configured `DATABASE_URL` to serve real traffic;
  without one they hit the documented DB-not-configured 500 (honest, not fake).
- Verify / reset-password remain **501** until their persistence structures are
  approved (D7/F1, D8/F2) — outside Task 3 scope.
- D10 limiter is **process-local**; multi-worker deployments would need a shared
  store (Redis) — out of scope; documented for future work.
- `/auth/me` and dependency behavior with a live DB (real `RETURNING`,
  constraint races) not yet exercised against a running PostgreSQL server.

## 21. Next Stage

- **Stage 8 (proposed):** wire auth into AI feature routers (protected
  diagnosis/knowledge/conversation endpoints), apply `role_required` where roles
  are gated, and any remaining auth-related integration tests.
- Will follow the approved gated workflow with its own report.