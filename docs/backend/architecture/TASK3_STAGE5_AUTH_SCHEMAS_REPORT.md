# TASK3_STAGE5_AUTH_SCHEMAS_REPORT.md

**Sprint 2 | Task 3: Authentication Foundation**
**Stage 5: Auth Schemas (Pydantic Validation Contracts)**
**Date:** 2026-08-15

---

## 1. Executive Summary

- Created **`backend/app/schemas/auth.py`** — pure request/response validation
  contracts for all eight approved auth endpoints (D11).
- Created **`backend/app/schemas/user.py`** — the safe public `UserOut`
  contract genuinely required by `GET /auth/me` (owner-scoped projection).
- **No** auth service, routes, JWT logic, hashing, repositories, models,
  migrations, middleware, or rate limiting were implemented — schemas are
  pure Pydantic contracts.
- Role representation reuses the existing `UserRole` constants (D3); no second
  enum created.
- Full suite: **136 passed** (up from 83; +53 in this stage). App import OK,
  route count unchanged at **6**.

## 2. Schema Inventory

| Schema | Module | Kind | Endpoint |
|---|---|---|---|
| `RegisterRequest` | `auth.py` | Request | `POST /auth/register` |
| `LoginRequest` | `auth.py` | Request | `POST /auth/login` |
| `TokenResponse` | `auth.py` | Response | `/login`, `/refresh` |
| `RefreshRequest` | `auth.py` | Request | `POST /auth/refresh` |
| `LogoutRequest` | `auth.py` | Request | `POST /auth/logout` |
| `LogoutResponse` | `auth.py` | Response | `POST /auth/logout` |
| `VerifyRequest` | `auth.py` | Request | `POST /auth/verify` |
| `ForgotPasswordRequest` | `auth.py` | Request | `POST /auth/forgot-password` |
| `ForgotPasswordResponse` | `auth.py` | Response | `POST /auth/forgot-password` |
| `ResetPasswordRequest` | `auth.py` | Request | `POST /auth/reset-password` |
| `ResetPasswordResponse` | `auth.py` | Response | `POST /auth/reset-password` |
| `CurrentUserResponse` | `auth.py` | Response | `GET /auth/me` |
| `UserOut` | `user.py` | Response (shared) | `GET /auth/me` |
| `UserRoleLiteral` | `user.py` | Literal alias | role typing (D3) |

## 3. Register Contract

`RegisterRequest { name, email, phone, password }`

- Mirrors the frontend SignUp contract (`AuthService.register(name, email, phone, password)`).
- `name`: min 3 / max 100 chars (frontend validates ≥3).
- `email`: regex-validated (pattern mirrors frontend `AuthService.validateEmail`), max 254.
- `phone`: required — `users.phone` is `NOT NULL UNIQUE` in the authoritative schema — pattern `^\+?[0-9]{10,15}$`.
- `password`: required, min 8 / max 128 chars. **Input validation only** — no hashing in the schema (D4 lives in `app.core.security`).

## 4. Login Contract

`LoginRequest { identifier, password }`

- Recon §5.1 documents login by **email/phone**, so `identifier` accepts
  either an email address or a phone number (`IDENTIFIER_PATTERN`); the future
  auth service resolves the matching column. No guessing was involved — this
  decision follows the documented contract.
- `password`: required, min 8 / max 128 (frontend login validates ≥6, but
  register enforces ≥8; the stricter min is applied consistently).

## 5. Token Contracts

`TokenResponse { access_token, refresh_token, token_type="bearer", expires_in }`

- Pure typed container — **no JWT generation or signature verification in a
  schema** (verified by test `test_token_schemas_cannot_decode_or_hash`).
- `token_type` is `Literal["bearer"]` (D12 Bearer transport).
- `expires_in` is `int` > 0, in seconds; the value (D5: 900 s) is computed by
  the auth service from configuration, not baked into the schema.

## 6. Refresh Contract

`RefreshRequest { refresh_token }`

- D12: refresh token travels in the **request body** — no cookies.
- Accepts the refresh token for the D6 rotation flow; rotation logic is
  deferred to the auth service.

## 7. Logout Contract

`LogoutRequest { refresh_token }` → `LogoutResponse { message }`

- Carries the refresh token so the auth service can revoke/consume the refresh
  session (approved `/auth/logout` addition in D11). Revocation logic is NOT
  implemented in this stage.
- Response is a generic message; no credential echo.

## 8. Current User Contract

`CurrentUserResponse(UserOut)` for `GET /auth/me`

- Reuses the safe `UserOut` projection (from `app.schemas.user`), which exposes
  only: `id, name, email, phone, role, is_active, is_verified, membership_tier,
  joined_at, date_of_birth, gender, emergency_contact_name`.
- `role` typed via `UserRoleLiteral` derived from the existing `UserRole`
  constants (customer | mechanic | admin) — single source of truth (D3).
- `ConfigDict(from_attributes=True)` for future ORM mapping.

## 9. Verification Contract

`VerifyRequest { token }`

- D7: backend verification-token architecture only — the token carries
  identity. No email/SMS provider is invented or hardcoded (delivery remains a
  FUTURE / CONFIGURABLE layer per F1).

## 10. Password Reset Contracts

- `ForgotPasswordRequest { identifier }` → `ForgotPasswordResponse { message }`
  — accepts email or phone; the endpoint is **enumeration-safe** (D8): the
  generic response message ("If an account exists…") is identical whether or
  not the identifier exists.
- `ResetPasswordRequest { token, new_password }` → `ResetPasswordResponse { message }`
  — carries the reset token + new password (min 8 / max 128; input validation
  only; hashing stays in `app.core.security`).

## 11. Security/Privacy Boundaries

Schemas are pure contracts and MUST NOT (enforced by design + tests):
- hash passwords, create/decode JWTs, or store tokens;
- access the database, query repositories, or call services;
- log credentials.

Tests assert `UserOut`/`CurrentUserResponse` expose **no** `password_hash`,
`token_digest`, `refresh_token`, `jwt`/`secret`, or internal security state
(`failed_login_attempts`, `lockout_at`, `last_login_at`). Unknown extra fields
are ignored (default `extra=ignore`), verified by `test_user_out_ignores_unknown_extra_fields`.

## 12. Tests

`backend/tests/test_auth_schemas.py` — **53 tests**, DB-free, accepted +
rejected inputs per schema:
- Register: valid, missing/short name, missing/invalid email, missing/invalid
  phone, missing/short/overlong password, email-pattern parity with the
  frontend regex.
- Login: valid email / valid phone, missing identifier/password, short
  password, invalid identifiers.
- Token response: valid, missing access/refresh token, invalid `token_type`,
  non-positive `expires_in`.
- Refresh: valid, missing/empty token.
- Logout: request valid/missing, response valid.
- Verify: valid, missing/empty token.
- Forgot-password: valid email/phone, missing/invalid identifier, generic
  enumeration-safe response.
- Reset-password: valid, missing token / new password, short new password.
- Safe user response: required fields, all three roles, unknown-role rejected,
  `password_hash` / `token_digest` / internal-state **not exposed** (checked on
  `model_fields` and via `model_dump`).

## 13. Full Test Results

- `python -m pytest tests/ -q` → **136 passed** (baseline 83 → +53).
- The 12 `PydanticDeprecatedSince20` warnings about `Field(..., example=)` are
  **pre-existing project-wide convention** — identical warnings are emitted by
  `chat.py`, `diagnosis.py`, `knowledge.py`. Kept consistent with existing
  schema style.

## 14. Runtime Validation

- `from app.main import app` → **IMPORT OK** (AI stack initializes; unchanged).
- Route count: **6** (unchanged — no auth routes added, as scoped).
- `from app.schemas.auth import ...` and `from app.schemas.user import UserOut`
  → import OK.

## 15. Files Created/Modified

Created (Stage 5):
- `backend/app/schemas/auth.py`
- `backend/app/schemas/user.py`
- `backend/tests/test_auth_schemas.py`

## 16. Files Explicitly Not Changed

- `backend/app/services/**` (no auth service) · `backend/app/api/v1/**` and
  `backend/app/api/router.py` (no auth routes) · `backend/app/api/deps.py`
  (Stage 4 stubs untouched) · `backend/app/core/security.py` (no new logic) ·
  `backend/app/models/**` (unchanged) · `backend/alembic/**` (no migration) ·
  `backend/app/core/{config,database,exceptions,logging}.py` ·
  `backend/app/main.py` · `backend/requirements*.txt` (no new deps —
  `email-validator` intentionally NOT added; email regex mirrors frontend) ·
  `frontend/**` · `backend/ai/**`.

## 17. Known Limitations

- Email/phone validation uses regex (project/frontend convention) rather than
  `email-validator` — no new dependency added per gated workflow.
- No live Postgres: schema tests are pure-validation (no DB required).
- Auth service, routes, lockout, and token issuance remain pending (Stage 6+).

## 18. Next Stage

- **Auth service** (`backend/app/services/auth_service.py`): register/login/
  refresh (rotation D6)/verify/forgot+reset (D7/D8) + lockout policy (D9),
  wiring `app.core.security`, repositories, and these schemas.
- Expected to follow the approved gated workflow with its own report.