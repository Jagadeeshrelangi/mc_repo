# TASK3_STAGE4_REPOSITORY_DEPENDENCY_REPORT.md

**Sprint 2 | Task 3: Authentication Foundation**
**Stage 4: Repository & Database Dependency Layer**
**Date:** 2026-08-15

---

## 1. Stage Scope

- `backend/app/repositories/base.py` — reusable async repository base.
- `backend/app/repositories/__init__.py` — repository package exports.
- `backend/app/repositories/users.py` — `UserRepository` + `RefreshTokenRepository` (D14: user + refresh-token data access together).
- `backend/app/api/deps.py` — infrastructure dependency wiring.
- `backend/tests/test_auth_repositories.py`, `backend/tests/test_api_dependencies.py`.
- NOT in scope (later stages): auth service, auth schemas, auth routes, further migrations.

## 2. Approved Decisions (D) Applied

| Decision | Applied |
|---|---|
| D1 (no Redis, PG refresh tokens) | Refresh-token records persisted in `refresh_tokens` (digest only) via `RefreshTokenRepository` |
| D2 (SHA-256 digest) | `create_refresh_token` accepts the already-hashed digest; plaintext never stored |
| D6 (rotation) | `mark_replaced(replaced_by_id)` + `revoke()` support the rotation workflow (policy in future service) |
| D3 (user auth fields) | Mutated via `record_successful_login`, `record_failed_login`, `clear_login_failures`, `lock_account`, `unlock_account` |
| D9 (lockout) | Lockout **policy** (thresholds) left to auth service; repo only persists `lockout_at` / counters |
| Data-access-only separation | No hashing/JWT/business decisions inside repositories |

## 3. Architecture Delivered

### 3.1 `repositories/base.py` — `BaseRepository[T]`
- Generic async CRUD bound to `Base`.
- Constructor **injects** `AsyncSession` — repositories never create/own sessions.
- `get`, `list(offset, limit, **filters)`, `create`, `update`, `delete`.
- **Transaction ownership convention:** writes `flush()` only (surfaces DB errors, materializes server-generated UUIDs); **never commit**. Caller (future auth service) owns the commit boundary for atomic multi-step workflows.
- `list` orders by `model.id` for determinism; filters are column-equality conditions.

### 3.2 `repositories/users.py`
**`UserRepository(BaseRepository[User])`** (DATA ACCESS ONLY — hashing lives in `app.core.security`, policy in future service):
- `get_by_id` (inherited `get`), `get_by_email`, `get_by_phone`
- `create_user(name, email, phone, password_hash, role)` — accepts an already-hashed password
- `record_successful_login` / `record_failed_login` / `clear_login_failures`
- `lock_account(user, lockout_at)` / `unlock_account(user)`

**`RefreshTokenRepository(BaseRepository[RefreshToken])`**:
- `create_refresh_token(user_id, token_digest, jti, expires_at)`
- `get_by_digest`, `get_by_jti`
- `revoke(record)`, `mark_replaced(record, replaced_by_id)`
- `is_active(record)` — pure data-level check (not revoked AND not expired), no DB call

All writes `flush()` without committing; both repositories live in `users.py` per D14.

### 3.3 `api/deps.py`
- `get_db` — **re-export** of the existing foundation session dependency from `app.core.database` (single wiring point; no duplicate implementation).
- `get_current_user()` — **documented contract stub** raising `NotImplementedError` (auth service pending Stage 5/6). Fails loudly so accidental use is never silently unauthenticated.
- `role_required(*roles)` — **documented contract stub** factory raising `NotImplementedError` for the same reason.
- No JWT logic, no user lookup, no auth-service import in the deps layer.

## 4. Testing Summary

Full suite: **83 passed, 0 failed** (up from 55; +28 new in this stage).

New tests:
- `tests/test_auth_repositories.py` (22 tests) — construction/DI, SQL generation compiled against the PostgreSQL dialect (via captured statements), field mutations, refresh-token data-access, and the **never-auto-commit** guarantee.
- `tests/test_api_dependencies.py` (6 tests) — `get_db is db_module.get_db` identity, raise-when-unconfigured, lazy session yield without connecting, rollback-on-error contract, and stub `NotImplementedError` behavior.

Testing approach without a live PostgreSQL server (documented limitation):
- AsyncMock `AsyncSession` capturing statements → compiled with `postgresql.dialect()` (no connection needed).
- Lazy engine factory: session creation does not connect, so `get_db` yield/rollback paths are exercised for real.
- PG-specific server behavior (actual execution, constraint enforcement, `gen_random_uuid()`) is **not faked** and requires a live DB to verify later.

## 5. Runtime Validation

- `python -m pytest tests/ -q` → **83 passed**
- `from app.main import app` → **IMPORT OK** (RAG/XGBoost/Gemini all initialized)
- Route count: **6** (unchanged — no auth routes added yet, as scoped)

## 6. Files Delivered (Stage 4)

- `backend/app/repositories/base.py` (new)
- `backend/app/repositories/__init__.py` (new)
- `backend/app/repositories/users.py` (new)
- `backend/app/api/deps.py` (new)
- `backend/tests/test_auth_repositories.py` (new)
- `backend/tests/test_api_dependencies.py` (new)

## 7. Files from Earlier Stages (modified, still uncommitted)

- `backend/requirements.txt` (pins: `python-jose[cryptography]==3.5.0`, `passlib==1.7.4`, `bcrypt==4.0.1`, `pytest==9.1.1`, `pytest-asyncio==1.4.0` in dev requirements)
- `backend/app/core/config.py` (JWT settings)
- `backend/.env.example` (JWT placeholders)
- `backend/alembic/env.py` (`from app import models`)
- `backend/alembic/versions/0002_authentication_foundation.py` (Stage 3 migration)
- `backend/app/core/security.py`, `backend/app/models/*`, `backend/tests/test_security.py`, `backend/tests/test_auth_models.py`

## 8. Next Stage (5) Preview

- **Auth schemas** (`app/schemas/auth.py`): Pydantic request/response contracts for register/login/refresh/logout.
- Expected to follow the approved gated workflow with its own report.

## 9. Not Done (pending)

- Live PostgreSQL execution of repository writes/migrations (no server available).
- Auth service business logic (lockout thresholds, refresh rotation orchestration).
- Auth routes and `get_current_user` / `role_required` wiring (Stage 5/6).