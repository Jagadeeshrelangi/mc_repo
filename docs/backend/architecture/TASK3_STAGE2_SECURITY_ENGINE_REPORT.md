# TASK3 Stage 2 — Security Engine Report

> **Sprint 2 · Task 3 · Stage 2 · 2026-08-15**
> Reusable security engine (`backend/app/core/security.py`): bcrypt (D4),
> JWT (D5), token-type enforcement, SHA-256 refresh-token digest (D2).
> **Scope:** security module + its unit tests only. No models, migrations,
> routes, repositories, auth service, deps, frontend, or AI changes.

---

## 1. Executive Summary

Implemented the infrastructure-level security engine exactly as scoped:

- **Password** — bcrypt at cost factor **12** (D4), with `hash_password` /
  `verify_password` helpers and explicit rejection of invalid inputs.
- **JWT** — `create_access_token` / `create_refresh_token` (D5) with required
  claims (`sub`, `iat`, `exp`, `jti`), config-driven lifetimes (15 min / 7 days)
  and algorithm, and a fail-safe missing-secret error (no silent random secret).
- **Token-type claim** — `type` = `"access" | "refresh"`, enforced by dedicated
  `verify_access_token` / `verify_refresh_token` helpers.
- **Refresh digest** — deterministic SHA-256 hex digest via `hash_refresh_token`
  for DB storage (D2). No `refresh_tokens` table created.

All 28 new unit tests pass; the full suite remains green (36 passed). The
running app still imports and exposes exactly **6 routes** (no auth routes).

## 2. Security Engine Design

`backend/app/core/security.py` is standalone infrastructure code:

- **No SQLAlchemy, FastAPI, repositories, HTTP responses, or database logic.**
- Reuses `app.core.exceptions.MechaException` via purpose-built controlled
  errors so API layers can map them without exposing internal `jose`/passlib
  exceptions to clients.
- Reads all security inputs from `app.core.config.settings`
  (`JWT_SECRET_KEY`, `JWT_ALGORITHM`, `ACCESS_TOKEN_EXPIRE_MINUTES`,
  `REFRESH_TOKEN_EXPIRE_DAYS`). Values are **never** hardcoded in logic.
- Timezone-aware UTC timestamps for `iat`/`exp` (epoch seconds in tokens).

Error hierarchy (internal, controlled):

- `SecurityError(MechaException)`
  - `SecurityConfigurationError` — missing/invalid `JWT_SECRET_KEY`
  - `TokenVerificationError`
    - `ExpiredTokenError` — expired token
    - `TokenTypeError` — correct signature, wrong token type

## 3. Password Hashing

- `hash_password(password: str) -> str` — bcrypt with `passlib` `CryptContext`,
  `schemes=["bcrypt"]`, `bcrypt__rounds=12` yields `$2b$12$...` hashes.
  Raises `ValueError` for empty and >72-byte inputs (explicit rejection rather
  than silent truncation). Plaintext is never stored.
- `verify_password(password, hashed_password) -> bool` — constant-time verify;
  returns `False` on invalid/empty inputs and on mismatch (never raises on a
  normal mismatch, so login code can answer generically).
- The `CryptContext` object is module-private (`_pwd_context`); callers only
  see the two helpers.

## 4. JWT Implementation

- `create_access_token(user_id, expires_in=None)` — default lifetime from
  `settings.ACCESS_TOKEN_EXPIRE_MINUTES` (15 min, D5).
- `create_refresh_token(user_id, expires_in=None)` — default lifetime from
  `settings.REFRESH_TOKEN_EXPIRE_DAYS` (7 days, D5).
- Both accept `str` or `UUID`; `sub` is the canonical UUID string.
- Signing: `jose.jwt.encode` with `JWT_ALGORITHM` (HS256) and the configured
  secret. The optional `expires_in` parameter exists only to let tests
  exercise expiry; production callers omit it.
- Missing `JWT_SECRET_KEY` → `SecurityConfigurationError` with a clear message.
  The module never generates or silently falls back to a random secret.

## 5. Token Claims

Both token types always carry (documented contract):

| Claim | Meaning | Source |
|---|---|---|
| `sub` | user UUID (string) | provided `user_id` |
| `iat` | issued-at, UTC epoch seconds | `datetime.now(timezone.utc)` |
| `exp` | expiration, UTC epoch seconds | `iat` + configured lifetime |
| `jti` | unique token identifier | `secrets.token_urlsafe(24)` |
| `type` | token type: `"access"` or `"refresh"` | module constant |

The token-type claim name is the module constant `TOKEN_TYPE_CLAIM = "type"`
(public, used consistently by creation and verification).

## 6. Token-Type Validation

- `verify_access_token(token)` decodes + validates signature/expiry/claims and
  raises `TokenTypeError` unless `type == "access"`.
- `verify_refresh_token(token)` behaves symmetrically for `type == "refresh"`.
- A refresh token presented as an access token (and vice-versa) is rejected,
  and the JWT spec requirement "a refresh token must not be accepted as an
  access token" is satisfied.

## 7. Refresh-Token SHA-256 Digest

- `hash_refresh_token(token) -> str` — `sha256(token.encode()).hexdigest()`.
- Deterministic 64-char lowercase hex, safe for database storage (D2).
- Plaintext refresh tokens are never stored/returned by this module.
- The refresh token is returned to the client **only** at issuance (by the
  future auth service); the DB stores only the digest (D1/D2).
- The `refresh_tokens` table is **not** created in this stage (D13).

## 8. Files Created / Modified

| File | Action |
|---|---|
| `backend/app/core/security.py` | **Created** — security engine |
| `backend/tests/test_security.py` | **Created** — 28 unit tests |

Unchanged from Stage 1 (already applied): `requirements.txt`,
`app/core/config.py`, `.env.example`.

## 9. Files Explicitly Not Changed

- `app/models/` — **none created** (users/refresh_tokens models deferred)
- `app/repositories/` — none created
- `app/schemas/` — none created
- `app/api/deps.py` — **not created**
- `app/api/v1/auth.py` **and all auth routes** — not created
- Alembic migrations — unchanged; **no `0002_authentication_foundation.py`**
- `app/db/`, `app/main.py` (no routers added), `app/services/` — unchanged
- `frontend/` — unchanged
- All AI services/routes — unchanged
- `backend/.env` — not touched
- No `git add`, no commit, no push.

## 10. Unit Test Results (new)

```
$ python -m pytest tests/test_security.py -q
............................                                     [100%]
28 passed in 1.47s
```

Coverage per requirement:

- **Password:** hash succeeds · correct verifies · wrong fails · cost is
  `$2b$12$` · empty/None rejected · >72-byte rejected · invalid verify inputs
  → `False`.
- **JWT:** access + refresh creation · required claims present · access ≈ 15 min
  · refresh ≈ 7 days · `jti` unique · UTC epoch timing · correct token types.
- **Type:** refresh rejected as access · access rejected as refresh.
- **Failures:** malformed token · empty token · expired · tampered signature ·
  wrong secret · missing secret (`SecurityConfigurationError`).
- **Digest:** 64-hex · deterministic · same token → same digest · different
  tokens differ · plaintext never returned.

## 11. Full Test Results

```
$ python -m pytest tests/ -q
....................................                       [100%]
36 passed in 1.51s
```

Existing tests remain passing (8 DB-foundation tests), new suite adds 28.

## 12. Runtime Validation

```
python -c "from app.core.security import hash_password, verify_password,
create_access_token, create_refresh_token, verify_access_token,
verify_refresh_token, hash_refresh_token"
```
- hash prefix `$2b$12$`, verify `True` for correct password
- access token: `sub` = UUID, `type` = access, TTL = 900 s (15 min)
- refresh token: `sub` = UUID, `type` = refresh, TTL = 7.0 days
- `jti` present on both; digest = 64-hex SHA-256
- `from app.main import app` → **IMPORT OK**
- OpenAPI paths → **PATH COUNT: 6** (unchanged — no auth routes)

## 13. Security Considerations

- No secrets, passwords, or tokens are logged or printed (test secret is a
  fixed non-production string; runtime validation used a throwaway value and
  never printed tokens).
- Missing JWT secret fails safely instead of generating a random production
  secret (explicit deny vs. accidental sign-anything).
- `jti` uses `secrets.token_urlsafe(24)` (cryptographically strong).
- Controlled exceptions keep raw `jose`/passlib internals out of API responses.
- bcrypt cost factor 12 (D4) verified at runtime.
- Passlib import/call paths on Python 3.13 with `bcrypt==4.0.1` emit no
  `(trapped) ...` traces (compatibility already established in Stage 1).

## 14. Known Limitations

- Rate limiting, lockout, refresh-token rotation **state** (D6), and
  verification/reset flows are out of scope by design — they live in
  `services/auth_service.py` + repositories (later stages).
- `verify_password` treats empty/None candidate passwords as `False` (generic
  failure) rather than a distinct error.
- bcrypt cost is locked at 12 (D4/F7); re-tuning requires an explicit future
  decision.

## 15. Next Stage

Stage 3 — user + refresh-token **models** (D3/D13) and additive
`0002_authentication_foundation.py` migration (D15), validated offline with
`alembic upgrade head --sql` (no live DB run).

---

*Predecessors: `TASK3_AUTHENTICATION_DECISIONS.md` (D2/D4/D5/D6),
`TASK3_STAGE1_SECURITY_CONFIG_REPORT.md`. Validated against actual files and
test output; no out-of-scope changes were made.*