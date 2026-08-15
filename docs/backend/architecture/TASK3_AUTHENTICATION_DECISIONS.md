# Sprint 2 — Task 3 Authentication Architecture Decisions

> **Sprint 2 · Task 3 · Architecture Decisions · 2026-08-15**
> Locked decisions D1–D15 for the authentication foundation, derived from
> `PRE_TASK3_AUTH_RECONNAISSANCE_REPORT.md`. This document is the contract for
> implementation. **No code, dependencies, migrations, or routes were
> changed while recording these decisions.**

---

## 1. Decision Status Legend

| Mark | Meaning |
|---|---|
| **APPROVED** | Locked for Task 3 implementation |
| **FUTURE / CONFIGURABLE** | Deferred; delivered as an injectable/configurable layer |

---

## D1 — REFRESH TOKEN STORAGE  ✅ APPROVED

- Store refresh tokens in **PostgreSQL** (`refresh_tokens` table).
- **No Redis** in any part of the auth flow.
- Store **only a secure hash/digest** of each refresh token — never plaintext
  refresh tokens.
- Aligned with the Sprint 2 roadmap / no-Redis architecture.

## D2 — REFRESH TOKEN HASHING  ✅ APPROVED

- **SHA-256** digest of the refresh token is what the database stores.
- The plaintext refresh token is returned to the client **only at issuance**.
- The DB digest is what `/refresh` verifies against.

## D3 — USER AUTH COLUMNS  ✅ APPROVED

`users` is extended with:

| Column | Notes |
|---|---|
| `role` | `customer` \| `mechanic` \| `admin`; default `customer` |
| `is_active` | default `true` for new accounts |
| `is_verified` | default `false` for new accounts |
| `last_login_at` | `TIMESTAMPTZ`, nullable |
| `failed_login_attempts` | `INT`, default `0` |
| `lockout_at` | `TIMESTAMPTZ`, nullable |

- Roles: `customer`, `mechanic`, `admin`.
- **Do NOT modify `0001_baseline.py`.** All auth schema changes land in a **new**
  revision starting with **`0002`**.

## D4 — PASSWORD HASHING  ✅ APPROVED

- **bcrypt** with **cost factor 12**.
- Plaintext passwords are never stored anywhere.

## D5 — JWT  ✅ APPROVED

| Parameter | Value |
|---|---|
| Access-token lifetime | **15 minutes** |
| Refresh-token lifetime | **7 days** |

JWT claims (both token types):

- `sub` = user UUID
- `iat` = issued-at timestamp
- `exp` = expiration timestamp
- `jti` = unique token identifier

- Lifetime/algorithm values come from **configuration**
  (`core/config.py` + `.env`), never hardcoded in business logic.

## D6 — REFRESH TOKEN ROTATION  ✅ APPROVED

On successful `/refresh`:

1. Validate the presented refresh token (signature, `exp`).
2. Verify its stored **SHA-256 digest** exists and is not revoked/consumed.
3. Check expiration and revocation state.
4. **Revoke/consume** the old refresh token.
5. Generate a new refresh token.
6. Store only the new token's digest.
7. Return the new access + refresh token pair.

- **No indefinite reuse**: each refresh token is single-use (rotated).
- Reuse/revoked-token reuse → generic auth failure.

## D7 — ACCOUNT VERIFICATION  ✅ APPROVED

- Keep the documented **`POST /auth/verify`** endpoint.
- Build the **verification state** (e.g., `is_verified`, verification-token
  architecture) and token-validated **verification flow**.
- **No external email/SMS provider is invented or hardcoded.**
- Delivery is a **FUTURE / CONFIGURABLE** layer (documented separation).

## D8 — PASSWORD RESET  ✅ APPROVED

- Keep **`POST /auth/forgot-password`** and **`POST /auth/reset-password`**.
- Implement the backend **reset-token architecture** (issue/validate/reset)
  **without** an external email provider.
- Enumeration-safe: the `/forgot-password` response is **generic** and does not
  reveal whether an email/phone exists.
- Delivery integration is a **FUTURE / CONFIGURABLE** layer.

## D9 — LOGIN LOCKOUT  ✅ APPROVED

- MVP policy: **5 failed attempts within 10 minutes → temporary lockout.**
- Reset `failed_login_attempts` after successful authentication.
- Use **secure generic** authentication-failure responses — no leaking whether
  an email/phone is registered.

## D10 — RATE LIMITING  ✅ APPROVED

- Auth endpoints: **10 requests/minute**.
- **Process-local in-memory** rate limiting (MVP). **No Redis.**
- Global rate limiting and other middleware remain **later Sprint 2 work**
  unless required by authentication.

## D11 — AUTH ENDPOINTS  ✅ APPROVED

Documented six (unchanged):

| Method | Path |
|---|---|
| POST | `/api/v1/auth/register` |
| POST | `/api/v1/auth/login` |
| POST | `/api/v1/auth/refresh` |
| POST | `/api/v1/auth/verify` |
| POST | `/api/v1/auth/forgot-password` |
| POST | `/api/v1/auth/reset-password` |

Approved practical additions:

| Method | Path | Reason |
|---|---|---|
| GET | `/api/v1/auth/me` | Flutter client restores the authenticated user |
| POST | `/api/v1/auth/logout` | Explicit refresh-session termination |

## D12 — TOKEN TRANSPORT  ✅ APPROVED

- Access token: `Authorization: Bearer <access_token>`.
- Refresh token: sent in the **request/response body** for MVP.
- **No browser cookies** at this stage.

## D13 — TASK 3 DATABASE SCOPE  ✅ APPROVED

- Task 3 DB changes are **limited to the authentication foundation**:
  1. `users` authentication fields (D3)
  2. `refresh_tokens` table (D1/D2/D6)
- **Do NOT implement all 39 application tables** during Task 3.
- Business tables arrive incrementally in their respective Sprint 2 modules.

## D14 — ARCHITECTURE  ✅ APPROVED

```
backend/app/
├── core/
│   └── security.py            # bcrypt (D4), JWT (D5), token digest (D2)
├── api/
│   ├── deps.py                # get_db, get_current_user, role_required, rate_limit
│   └── v1/
│       ├── auth.py            # D11 endpoints
│       └── users.py           # profile-scoped (owner/admin)
├── models/
│   ├── user.py                # users + D3 columns
│   └── refresh_token.py       # refresh_tokens table
├── schemas/
│   ├── auth.py                # register/login/refresh/verify/forgot/reset/me/logout
│   └── user.py                # user read/update
├── repositories/
│   ├── base.py                # BaseRepository (get/list/create/update/delete)
│   └── users.py               # user + refresh-token data access
└── services/
    └── auth_service.py        # business logic (register/login/refresh/rotation/
                               # verify/forgot/reset/lockout D6/D7/D8/D9)
```

- **Only create directories/files that are genuinely needed**; no dummy/empty
  modules.
- **Existing AI services remain untouched.**
- **Existing AI routes remain DB-free and unchanged.**
- `core/database.py`, `core/exceptions.py`, `core/logging.py`, `main.py`
  lifespan/health are reused as-is (additive hooks only, if approved).

## D15 — BASELINE MIGRATION  ✅ APPROVED

- **ABSOLUTE RULE:** `backend/alembic/versions/0001_baseline.py` is **NOT
  modified.**
- Create **`0002_authentication_foundation.py`** — additive only.
- Validate offline first: `alembic upgrade head --sql`.
- **Do NOT execute a live database migration** during Task 3 implementation
  without explicit approval.

---

## 2. Summary Matrix

| Decision | Status |
|---|---|
| D1 Refresh-token storage (Postgres, no Redis) | APPROVED |
| D2 Refresh-token hashing (SHA-256 digest) | APPROVED |
| D3 User auth columns (role/is_active/is_verified/last_login_at/failed_login_attempts/lockout_at) | APPROVED |
| D4 Password hashing (bcrypt cost 12) | APPROVED |
| D5 JWT (15m / 7d; sub/iat/exp/jti; config-driven) | APPROVED |
| D6 Refresh-token rotation | APPROVED |
| D7 Account verification architecture (delivery configurable) | APPROVED |
| D8 Password reset architecture (delivery configurable; enumeration-safe) | APPROVED |
| D9 Login lockout (5 / 10 min; generic failures) | APPROVED |
| D10 Auth rate limiting (10/min; in-memory; no Redis) | APPROVED |
| D11 Auth endpoints (6 documented + /me + /logout) | APPROVED |
| D12 Token transport (Bearer access; body refresh; no cookies) | APPROVED |
| D13 Task 3 DB scope (users auth fields + refresh_tokens only) | APPROVED |
| D14 Architecture (security/deps/models/schemas/repositories/services) | APPROVED |
| D15 Baseline immutability; new additive `0002` migration | APPROVED |

---

## 3. REMAINING FUTURE / CONFIGURABLE ITEMS (intentionally deferred)

| # | Item | Status | Notes |
|---|---|---|---|
| F1 | Verification delivery (email/SMS/OTP provider) | FUTURE / CONFIGURABLE | D7 — backend state + token architecture now; provider injected later |
| F2 | Password-reset delivery (email/phone link) | FUTURE / CONFIGURABLE | D8 — reset-token architecture now; provider injected later |
| F3 | Global + AI rate limiting and other middleware | FUTURE | D10 — in-memory auth limit now; global/headers later |
| F4 | Redis/caching/session store | FUTURE / NOT PLANNED | Explicitly **excluded** by D1/D10 |
| F5 | Browser-cookie token transport | FUTURE | D12 excludes cookies for MVP |
| F6 | All 39 business tables | FUTURE (per module) | D13 restricts Task 3 to auth foundation |
| F7 | bcrypt cost tuning beyond 12 | FUTURE | Cost 12 locked (D4); revisit only on upgrade |
| F8 | MFA / social login (e.g., Google Sign-In) | FUTURE | Frontend spec mentions Google; not in Task 3 scope |

No item above blocks Task 3 implementation; each is a deliberately separate
decision recorded at its module.

---

## 4. Validation Status

- Repository unchanged while recording this document (verify `git status`).
- No packages installed; `requirements.txt` untouched.
- No models, migrations, routes, `.env`, frontend, or AI-service changes made.
- No live DB migration executed.
- Decision content verified against `PRE_TASK3_AUTH_RECONNAISSANCE_REPORT.md`
  §10 (D1–D12 cross-reference) and the Task-3 prompt (D1–D15).

---

*Predecessor: `PRE_TASK3_AUTH_RECONNAISSANCE_REPORT.md`. Implementation will be
executed only after approval.*

*No code, dependencies, models, migrations, routes, frontend, or AI-service
changes were made during this document's creation.*