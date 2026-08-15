# TASK3 Stage 3 — Database Auth Models & Migration Report

> **Sprint 2 · Task 3 · Stage 3 · 2026-08-15**
> SQLAlchemy `User` + `RefreshToken` models, additive Alembic migration
> `0002_authentication_foundation.py`, and model-contract unit tests.
> **Scope:** models + migration + tests only. No services, repositories, deps,
> auth routes, frontend, or AI changes.

---

## 1. Executive Summary

Implemented the authentication database layer:

- **`app/models/`** package registering `User` and `RefreshToken` on the shared
  `app.core.database.Base` metadata.
- **`users`** table — authoritative identity fields **plus** the D3
  authentication fields (`role`, `is_active`, `is_verified`, `last_login_at`,
  `failed_login_attempts`, `lockout_at`) with approved defaults.
- **`refresh_tokens`** table — stores only the **SHA-256 digest** (D2) plus
  rotation/lifecycle metadata (D1/D6); no plaintext tokens, no JWT secrets.
- **Migration `0002`** — additive, `0001_baseline.py` untouched, verified via
  `alembic upgrade head --sql` (offline DDL only; **no live DB**).

All **19** new model tests pass; the full suite is **55 passed**; app import
and the **6 existing routes** are unchanged.

## 2. Existing DB Foundation Reused

Inspected before writing anything (`app/core/database.py`, `alembic/env.py`,
`versions/0001_baseline.py`) and **reused as-is**:

| Foundation element | Reused |
|---|---|
| `Base(DeclarativeBase)` | ✅ single metadata root in `app/core/database.py` |
| Async engine/session factory | ✅ `configure_database()` / `AsyncSessionFactory` untouched |
| UUID PKs | ✅ `Uuid(as_uuid=False)` + `server_default=text("gen_random_uuid()")` (matches `schema.sql`) |
| Timestamps | ✅ `DateTime(timezone=True)` (TIMESTAMPTZ) + `server_default=text("now()")` |
| Enum representation | ✅ TEXT + CHECK constraints (matches `membership_tier` convention; **no** PG `ENUM` type) |
| Alembic async env | ✅ reused; single additive import for model discovery |

**Only change to the foundation:** `alembic/env.py` gained
`from app import models` so autogenerate/metadata can discover the new models
(required by the task's model-discovery requirement). No architecture was
replaced.

## 3. User Model — `app/models/user.py`

- Identity fields mirror the authoritative `schema.sql`: `id` (UUID PK),
  `name`, `email`, `phone`, `password_hash` (nullable), `date_of_birth`,
  `gender`, `membership_tier` (`'free'` default), `joined_at`,
  `emergency_contact_*`, `created_at`, `updated_at`.
- D3 authentication fields added:

| Field | Default | Nullable |
|---|---|---|
| `role` | `'customer'` | no |
| `is_active` | `true` | no |
| `is_verified` | `false` | no |
| `last_login_at` | — | **yes** |
| `failed_login_attempts` | `0` | no |
| `lockout_at` | — | **yes** |

- Constraints: `uq_users_email`, `uq_users_phone`, `ck_users_membership_tier`,
  `ck_users_role` (role IN customer/mechanic/admin); indexes on `email`,
  `phone`.
- **No** unrelated profile/business fields added; **no** 39 business tables.

## 4. Role Handling

`UserRole` constant class exposes `customer` / `mechanic` / `admin`
(`VALUES` tuple). Stored as `TEXT` with a CHECK constraint — exactly the
project's existing enum convention (`membership_tier IN ('free','pro')`).
No SQLAlchemy `Enum` type, no unnecessary complexity.

## 5. RefreshToken Model — `app/models/refresh_token.py`

| Column | Purpose |
|---|---|
| `id` | UUID PK (`gen_random_uuid()`) |
| `user_id` | FK → `users.id` (ON DELETE CASCADE), indexed |
| `token_digest` | **SHA-256 hex digest** (String(64)) of the refresh token (D2) |
| `jti` | JWT `jti` claim — stable token/session identifier |
| `expires_at` | token expiration (TIMESTAMPTZ) |
| `created_at` | server default `now()` |
| `revoked_at` | nullable; set when consumed/rotated (D6) |
| `replaced_by_id` | self-FK → `refresh_tokens.id` for rotation lineage (D6) |

- **`token_digest` is unique** (`uq_refresh_tokens_token_digest`) so the
  rotate/verify lookup is indexed and unambiguous; `jti` is also unique.
- **No plaintext token field**, **no access-token field**, **no JWT secret**
  anywhere in the model (verified by tests).
- `user_id` FK explicitly targets `users.id` (verified by test).

## 6. Relationships

- `User.refresh_tokens` — one-to-many, `back_populates="user"`, cascade
  `all, delete-orphan`, `passive_deletes=True`. Uses default `lazy="select"`
  so refresh tokens are **not** auto-loaded onto user graphs (avoids large
  unrelated object graphs).
- `RefreshToken.user` — many-to-one back to `User`.
- `RefreshToken.replaced_by` — self-referential many-to-one for rotation
  lineage (D6), `post_update=True`.

## 7. Migration 0002 — `alembic/versions/0002_authentication_foundation.py`

- `down_revision = "0001"`, additive only.
- `upgrade()` creates `users` (full identity + D3 fields, constraints,
  indexes) then `refresh_tokens` (FKs, unique indexes).
- `downgrade()` drops indexes + tables in reverse order (clean reversal).

## 8. Migration Safety Validation

| Check | Result |
|---|---|
| `alembic history` | `0001 -> 0002 (head)` ✅ |
| `alembic heads` | `0002 (head)` ✅ (single head, no branching) |
| `alembic upgrade head --sql` | **succeeded** — rendered full PostgreSQL DDL ✅ |
| Generated DDL | `users` CREATE TABLE (all fields, 4 constraints, 2 indexes), `refresh_tokens` (2 FKs with CASCADE/SET NULL, unique digest+jti indexes), `UPDATE alembic_version` |
| Live migration | **NOT executed** — no `alembic upgrade head`, no DB connection |

## 9. Model Tests — `tests/test_auth_models.py` (19)

```
$ python -m pytest tests/test_auth_models.py -q
...................                                                      [100%]
19 passed in 0.05s
```

Coverage: metadata contains `users`+`refresh_tokens`; User has all D3 auth
fields + identity fields; `role` default `'customer'`; `is_active=true`;
`is_verified=false`; `failed_login_attempts=0`; nullable `last_login_at` /
`lockout_at`; `ck_users_role`/`ck_users_membership_tier` present; RefreshToken
has non-null `token_digest`; digest uniqueness index represented; User↔
RefreshToken relationships (ONETOMANY/MANYTOONE); FK points to `users.id`;
rotation column `replaced_by_id`; **no plaintext token / access-token / JWT
secret fields**; both models are declarative.

**Documented limitation (not faked):** PostgreSQL server-side behaviours
(actual `gen_random_uuid()` execution, `ON DELETE` enforcement, constraint
firing) require a live DB and are out of scope for this DB-agnostic suite.

## 10. Full Test Results

```
$ python -m pytest tests/ -q
.......................................................                  [100%]
55 passed in 1.75s
```

Breakdown: 8 (DB foundation) + 28 (security engine) + 19 (auth models) = **55**.

## 11. Runtime Validation

- `from app.models import User, UserRole, RefreshToken` → OK; metadata tables:
  `['refresh_tokens', 'users']`.
- `from app.main import app` → **IMPORT OK**; OpenAPI **PATH COUNT: 6**
  (unchanged — `/health` + 5 AI routes, **no auth routes**).
- `alembic history` / `heads` → single chain, head `0002`.

## 12. Files Created

| File | Purpose |
|---|---|
| `backend/app/models/__init__.py` | model package registration |
| `backend/app/models/user.py` | `User` + `UserRole` |
| `backend/app/models/refresh_token.py` | `RefreshToken` |
| `backend/alembic/versions/0002_authentication_foundation.py` | additive migration |
| `backend/tests/test_auth_models.py` | 19 model-contract tests |

## 13. Files Modified

| File | Change |
|---|---|
| `backend/alembic/env.py` | +1 line: `from app import models` for metadata discovery (additive, no behaviour change) |

## 14. Files Explicitly Not Changed

- `backend/alembic/versions/0001_baseline.py` — **UNCHANGED**
- `backend/app/core/security.py` — unchanged (no import-compat changes needed)
- `backend/app/core/database.py`, `config.py`, `exceptions.py`, `logging.py`
- `backend/app/api/` (no auth router), `backend/app/repositories/` (**none**),
  `backend/app/services/` (no auth service), `backend/app/schemas/`
- `backend/ai/**`, `frontend/**` — untouched
- No live DB executed; nothing staged/committed/pushed.

## 15. Known Limitations

- No live PostgreSQL available → server-side DDL execution not exercised
  (offline `--sql` validation only, per task rules).
- Refresh-token rotation logic (D6) is **model-only** here; the service
  implementation that uses `revoked_at`/`replaced_by_id` lands in a later stage.
- `Uuid(as_uuid=False)` stores UUIDs as string values; consistent with the
  security module's string `sub` claims.

## 16. Next Stage

Stage 4 — **repositories** (`repositories/base.py`, `repositories/users.py`)
per D14, then `api/deps.py` (`get_db`, `get_current_user`, `role_required`),
then schemas + auth service + routes.

---

*Predecessors: `TASK3_AUTHENTICATION_DECISIONS.md` (D1–D15),
`TASK3_STAGE1_SECURITY_CONFIG_REPORT.md`, `TASK3_STAGE2_SECURITY_ENGINE_REPORT.md`.
Validated against actual files, `alembic` output, and test results.*

| Status flag | Value |
|---|---|
| 0001 baseline | **UNCHANGED** |
| Live migration | **NOT EXECUTED** |
| Plaintext refresh tokens | **NOT STORED** |
| Auth routes | **NOT CREATED** |
| Repositories | **NOT CREATED** |
| Auth service | **NOT CREATED** |