# TASK3_STAGE6_AUTH_SERVICE_REPORT.md

**Sprint 2 | Task 3: Authentication Foundation**
**Stage 6: Auth Service — Business Logic**
**Date:** 2026-08-15

---

## 1. Executive Summary

- Created **`backend/app/services/auth_service.py`** — `AuthService` coordinates
  schemas → security engine → repositories → database transaction.
- Implemented: registration, email/phone login, D9 lockout, token issuance,
  D6 refresh rotation, logout, current-user, enumeration-safe forgot-password.
- **Verification and reset-password STOP at a documented boundary**: the
  approved Task 3 DB scope (D13) has no verification/reset-token persistence,
  and the security engine defines only access/refresh token types. No table,
  token type, or provider was invented.
- Full suite: **172 passed** (up from 136; +36 in this stage). App import OK,
  route count unchanged at **6**.

## 2. Service Architecture

```
schemas (app.schemas.auth / app.schemas.user)
   ↓
AuthService (this stage — owns business rules + transaction boundaries)
   ↓
security engine (app.core.security: bcrypt D4 / JWT D5 / digest D2)
   ↓
repositories (app.repositories.users: UserRepository, RefreshTokenRepository)
   ↓
AsyncSession (request-scoped; commit/rollback owned here)
```

- **Constructor DI**: `AuthService(session, user_repository=None, refresh_token_repository=None)`.
  Repositories default to real ones bound to the session; tests inject fakes.
- **No** route decorators, HTTP handling, SQLAlchemy query construction, raw
  session creation, hashing, or JWT implementation inside the service.
- **Request-scoped** (session is per-request from `app.api.deps.get_db`); no
  module-level singleton.

## 3. Registration Flow

`register(RegisterRequest) -> UserOut`

1. Email uniqueness (`get_by_email`) → `InvalidInputException` on duplicate.
2. Phone uniqueness (`get_by_phone`) → `InvalidInputException` on duplicate.
3. `security.hash_password()` (D4) — plaintext never stored.
4. `UserRepository.create_user(role=UserRole.CUSTOMER)`; explicit defaults
   `is_active=True`, `is_verified=False`, `failed_login_attempts=0`.
5. Single `session.commit()`.
6. Returns `UserOut` (safe projection — no password_hash / internal state).

## 4. Login Flow

`login(identifier, password) -> TokenResponse`

1. Resolve identifier: email (contains `@`) else phone (`_find_by_identifier`).
2. Generic failure if: unknown identifier, no password_hash, or inactive
   account — same `GENERIC_LOGIN_FAILURE` message (enumeration-safe, D9).
3. D9 lockout check.
4. `security.verify_password()`.
5. Success: unlock (clear lockout + failures), record successful login
   (last_login_at, reset counters), issue tokens, store digest, commit once.
6. Failure: record failed attempt, lock on threshold, commit (so lockout
   survives the request), raise generic `UnauthorizedException`.

## 5. Lockout Implementation (D9)

- `MAX_FAILED_LOGIN_ATTEMPTS = 5`, `LOCKOUT_DURATION = timedelta(minutes=10)`.
- **Active lock** (`lockout_at` set and within 10 minutes): deny generically —
  password is never even verified, no counter change.
- **Expired lock**: `unlock_account()` clears stale state, then auth proceeds.
- **On the 5th failure**: `lock_account(now)`.
- **On success**: failures reset to 0, lockout cleared, last_login_at = UTC now.
- Lockout is **service policy**; repositories only persist the fields.

## 6. Token Issuance

- `security.create_access_token()` / `security.create_refresh_token()` (D5).
- `_issue_tokens()` verifies the fresh refresh token back through the engine to
  obtain its `jti` claim and `exp` timestamp for DB storage — the service never
  touches JWT internals directly.
- `security.hash_refresh_token()` → SHA-256 digest (D2); only the digest is
  stored via `RefreshTokenRepository.create_refresh_token`.
- `TokenResponse.expires_in = ACCESS_TOKEN_EXPIRE_MINUTES * 60` (config-driven).

## 7. Refresh Rotation (D6)

`refresh(refresh_token) -> TokenResponse` — fully atomic (one commit):

1. `security.verify_refresh_token()` — signature, expiry, **type** (an access
   token raises `TokenTypeError` → generic failure). Security errors are
   converted to a generic `UnauthorizedException` (no jose leaks).
2. SHA-256 digest → `get_by_digest`.
3. `is_active()` — revoked/expired → generic failure.
4. Load user; inactive user → generic failure.
5. `revoke(old)` → issue new pair → store new digest → `mark_replaced(old, new.id)`.
6. Single `session.commit()`.

Old tokens become unusable (revoked/consumed); reuse yields a generic failure.
Everything is inside ONE transaction — never committed halfway.

## 8. Logout

`logout(refresh_token) -> LogoutResponse`

- Best-effort structural verification (never raises to the caller).
- SHA-256 digest lookup; if a record exists it is revoked + committed.
- **Idempotent** (repeat logout is safe) and **leak-free** (unknown tokens
  return the same generic success; no credential is echoed).

## 9. Current User

`get_current_user(user_id) -> UserOut`

- `UserRepository.get(user_id)`; missing → `EntityNotFoundException`.
- Inactive account → `UnauthorizedException`.
- Returns the safe `UserOut` projection — password_hash, token digests, JWT
  secrets, failed_login_attempts, lockout_at, and internal state are omitted.

## 10. Verification (documented boundary — D7)

**STOP at approved-schema boundary.** D7 requires a verification-token
persistence/validation structure for a secure `/verify` state transition. The
approved Task 3 scope (D13) contains ONLY the users auth fields + the
`refresh_tokens` table; there is no verification-token storage and the security
engine defines only access/refresh token types. `verify()` raises a documented
`NotImplementedError` naming the exact missing dependency (D7/F1). No table,
token type, email/SMS provider, or delivery mechanism was invented.

## 11. Forgot Password (D8)

`forgot_password(identifier) -> ForgotPasswordResponse`

- **Enumeration-safe**: returns an identical generic message regardless of
  whether the identifier exists.
- Performs **no account lookup** to avoid the timing side-channel that would
  leak account existence; makes **no DB writes** (verified by test).
- Reset-token issuance and delivery remain deferred (F2) — the approved schema
  has no reset-token persistence.

## 12. Reset Password (documented boundary — D8)

**STOP at approved-schema boundary.** D8 requires a secure reset-token
persistence/validation mechanism, which the approved Task 3 scope (D13) does
not contain. `reset_password()` raises a documented `NotImplementedError`
naming the exact missing dependency (D8/F2). No storage was invented. When a
reset-token structure is approved, the final password hash will use
`security.hash_password()` (never plaintext).

## 13. Transaction Boundaries

- Repositories flush() without committing (Stage 4 convention).
- `AuthService` owns commit/rollback:
  - Successful multi-step flows (register, login, refresh rotation, logout)
    → **one** `session.commit()`.
  - Refresh rotation is atomic: revoke + create replacement + mark lineage in
    a single transaction.
  - Failures → `session.rollback()` and the controlled error re-raised.
- Verified by tests: rotation commits exactly once; a mid-flow repository
  failure rolls back with zero commits.

## 14. Error Handling

- Uses the existing `app.core.exceptions` hierarchy:
  `UnauthorizedException` (generic auth failures), `InvalidInputException`
  (duplicate email/phone), `EntityNotFoundException` (missing user).
- Security-engine errors (`SecurityError` family) are converted to generic
  `UnauthorizedException` — jose/SQLAlchemy/bcrypt internals never surface.
- Generic messages (`GENERIC_LOGIN_FAILURE`, `GENERIC_REFRESH_FAILURE`) never
  reveal whether identifier, password, account state, or lockout caused a
  failure. HTTP status mapping stays outside the service (main.py handlers).

## 15. Tests

`backend/tests/test_auth_service.py` — **36 tests** (DB-free; fakes only test
coordination, not PostgreSQL server behavior):

- **Registration (6)**: success, password hashed (not plaintext), default
  customer/active/unverified, duplicate email, duplicate phone, safe result
  (no password_hash/internal fields).
- **Login (12)**: email login, phone login, refresh digest stored (not
  plaintext), wrong password → generic, unknown identifier → generic,
  inactive account → generic, counter increments, lockout after 5 failures,
  denied while locked, expired-lockout recovery, success clears failures +
  lockout, last_login_at updated.
- **Refresh (9)**: valid rotation, access-token-as-refresh rejected, expired
  rejected, revoked rejected, unknown digest rejected, inactive user rejected,
  old token becomes unusable, rotation commits exactly once, mid-flow failure
  rolls back with zero commits (last two are the transaction-safety cases).
- **Logout (3)**: valid token revoked, repeated logout safe, unknown token no
  leak.
- **Current user (3)**: existing active, missing, inactive.
- **Verification (1)**: documented boundary raised.
- **Forgot password (1)**: identical generic response for existing/unknown.
- **Reset password (1)**: documented boundary raised.

## 16. Full Test Results

- `python -m pytest tests/ -q` → **172 passed** (baseline 136 → +36).
- 12 `PydanticDeprecatedSince20` warnings (pre-existing project-wide `Field(example=)`
  convention) — unchanged from Stage 5.

## 17. PostgreSQL Limitations

- No live PostgreSQL server: service tests use in-memory session/repository
  fakes and patched security functions — they verify service orchestration and
  transaction boundaries, never PG server behavior.
- DB constraint enforcement (e.g. `uq_users_email` unique race under concurrency),
  `gen_random_uuid()`, and real flush/RETURNING behavior require a live DB and
  are documented as not-yet-verified.

## 18. Files Created/Modified

Created (Stage 6):
- `backend/app/services/auth_service.py`
- `backend/tests/test_auth_service.py`

## 19. Files Explicitly Not Changed

- `backend/app/api/**` (no auth routes), `backend/app/api/deps.py` (Stage 4
  stubs), `backend/app/core/security.py`, `backend/app/core/config.py`,
  `backend/app/models/**`, `backend/app/repositories/**`,
  `backend/app/schemas/**`, `backend/alembic/**` (no migration),
  `backend/app/main.py`, `backend/requirements*.txt`, `frontend/**`,
  `backend/ai/**`.

## 20. Known Limitations

- **Verification (`/verify`) not implemented** — requires a verification-token
  persistence structure outside approved Task 3 scope (D7/F1).
- **Password reset not implemented** — requires reset-token persistence outside
  approved Task 3 scope (D8/F2).
- Forgot-password performs no lookup/issuance (enumeration-safe by design;
  delivery deferred to F2).
- Concurrency-safe uniqueness (DB-level unique race) unverified without a live DB.

## 21. Next Stage

- **Auth routes** (`backend/app/api/v1/auth.py` + mount in `router.py`):
  register/login/refresh/verify/forgot-password/reset-password/me/logout wiring
  `AuthService`, `get_db`, and the schema contracts; auth rate limiting (D10).
- Verification/reset-password endpoints to surface the documented boundaries
  until their persistence structures are approved.
- Expected to follow the approved gated workflow with its own report.