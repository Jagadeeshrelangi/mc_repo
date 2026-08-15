# Sprint 2 — Task 3 Pre-Reconnaissance Report (Authentication Foundation)

> **Sprint 2 · Task 3 · Reconnaissance only · 2026-08-15**
> Complete, verified inventory of the repository ahead of authentication
> implementation. **No code was written, no migration was generated, nothing was
> installed — analysis and read-only validation only.**

---

## 1. Executive Summary

| Metric | Value |
|---|---|
| Repository HEAD | `b6eaa60 feat(backend): sprint 2 database foundation and repo hygiene` |
| Branch / remote | `main` == `origin/main` == `b6eaa60` |
| Working tree | **clean** (verified `git status --short` → empty) |
| Existing authentication | **NONE — NOT FOUND** (no code, no deps, no models, no routes) |
| Database schema | `docs/backend/database/schema.sql` — **39 tables**, authoritative; baseline migration is EMPTY (no tables) |
| Auth dependencies | **MISSING** — no `python-jose`, no `passlib`, no `bcrypt` |
| Auth API contract | **DOCUMENTED (partial)** in `docs/backend/Authentication.md` + `Architecture.md` §4.1: register/login/refresh/verify/forgot-password/reset-password |
| Task 3 readiness | **READY TO IMPLEMENT** — foundation is correct; several UNDEFINED / REQUIRES DECISION items must be settled before/during coding (see §10) |

This is a green-field authentication build: the Sprint 2 DB foundation (async
SQLAlchemy + Alembic baseline, unit-tested 8/8) is in place, but **no user
model, no security module, no auth routes, and no auth dependencies exist**.

---

## 2. Current Backend State

### 2.1 Actual structure (confirmed from repository)

```
backend/
├── .env / .env.example          (gitignored / placeholder doc; DATABASE_URL empty)
├── requirements.txt             (pinned; no jose/passlib/bcrypt)
├── requirements-dev.txt         (pytest 9.1.1, pytest-asyncio 1.4.0)
├── alembic.ini                  (URL empty; read from settings)
├── alembic/
│   ├── env.py                   (async; reads settings.DATABASE_URL; offline → postgresql dialect)
│   ├── script.py.mako
│   └── versions/0001_baseline.py  (EMPTY root revision — creates NO tables)
├── scripts/db_check.py          (readiness probe; exit 0/1/2)
├── tests/                       (conftest.py + test_database_foundation.py — 8 tests)
├── ai/                          (RAG index, XGBoost, knowledge base — untouched)
└── app/
    ├── main.py                  FastAPI app, lifespan (configure/dispose engine), /health, CORS, exception handlers
    ├── __init__.py              (Task 1 marker)
    ├── core/                    config.py, database.py, exceptions.py, logging.py
    ├── api/
    │   ├── router.py            mounts diagnosis, knowledge, conversation
    │   └── v1/                  conversation.py, diagnosis.py, knowledge.py
    ├── schemas/                 chat.py, diagnosis.py, knowledge.py
    └── services/                chat_service.py, diagnosis_service.py, rag_service.py
```

**NOT present (confirmed):** `models/`, `repositories/`, `middleware/`,
`api/deps.py`, `services/security.py` or any auth/security service. No
`users` implementation anywhere.

### 2.2 Database stack (confirmed)

| Item | State | Evidence |
|---|---|---|
| SQLAlchemy | 2.0.51 async, `DeclarativeBase Base` in `core/database.py` | file |
| Engine/session | `configure_database()` lazy; `AsyncSessionFactory`; no URL → unconfigured boot | file |
| `get_db()` Depends | exists but not consumed by any route | file + grep |
| Alembic | 1.19.1 async env; **baseline `0001` only, empty** | `alembic heads` → `0001 (head)` |
| Models | **none** (no `app/models/`) | tree |
| Registered routes | 6: `/health`, 5× AI (`conversation/chat|session|history`, `diagnosis/diagnose`, `knowledge/query`) | `openapi()` → PATH COUNT 6 |

### 2.3 Config (confirmed from repository)

`core/config.py` settings: `PROJECT_NAME`, `API_V1_STR`, `LOG_LEVEL`,
`GEMINI_API_KEY`, `GEMINI_MODEL`, `FIREBASE_CREDENTIALS_PATH`,
`ENABLE_FALLBACK`, `DEFAULT_VEHICLE_MILEAGE`, `DATABASE_URL`, `CORS_ORIGINS`.
**No JWT/bcrypt settings exist** (`JWT_SECRET_KEY`, `JWT_ALGORITHM`,
`ACCESS_TOKEN_EXPIRE_MINUTES`, `REFRESH_TOKEN_EXPIRE_*` — all absent).

### 2.4 Exceptions (confirmed from repository)

`core/exceptions.py`: `MechaException` + `EntityNotFoundException`
(`NOT_FOUND`), `UnauthorizedException` (`UNAUTHORIZED`), `InvalidInputException`
(`BAD_REQUEST`), `InferenceException` (`INFERENCE_FAILED`). `main.py` maps
`UNAUTHORIZED` → 401. Reusable for auth error responses.

---

## 3. Existing Authentication Findings

**RESULT: NO authentication functionality exists. NOT FOUND.**

Repository-wide search (backend `*.py`, `requirements*.txt`,
`.env.example`) for `jwt | bcrypt | passlib | python-jose | oauth | bearer |
access_token | refresh_token | get_current_user | current_user | login |
register | password_hash | is_active | is_verified | role | rbac`:

| Term | Hits | Location of any hits (all benign) |
|---|---|---|
| `role` | 3 | `chat.py:26`, `chat_service.py` (AI message role) |
| `register` | 0 | — |
| `login` | 2 | `chat_service.py:152` (chat keyword "login issue") |
| `password` | 0 | — |
| `jwt/bcrypt/jose/token` | 0 | — |

All hits are unrelated (AI message `role`/`history` semantics). No security
module, no `Depends(get_current_user)`, no auth middleware, no Bearer scheme,
no `security.py`, **no user table/model**.

The frontend (`frontend/lib/features/auth/`) contains only a **local-only RC1
mock**: `AuthProvider` / `AuthService` / `AuthRepository` + 3 screens
(Login / SignUp / ForgotPassword), persisting `is_logged_in` via
SharedPreferences. **No real credentials; no backend integration.**

---

## 4. Database Contract Findings

### 4.1 Authoritative source (CONFIRMED FROM DOCUMENTATION)

`docs/CANONICAL_DOCUMENT_MAP.md` → **Database topic canonical doc:
`docs/backend/Database.md`**, supporting: `docs/backend/database/schema.sql`
(39-table DDL) and `docs/backend/database/data_model.md`.

- **39 tables confirmed** in `schema.sql` (identity 4: users, vehicles,
  addresses, notification_settings; wallet 3; marketplace 9; orders 3;
  mechanic 11; fuel 6; AI 3 — per ANALYSIS §2.1).
- The **39-table contract IS defined and authoritative**. ⚠️ It does **NOT**
  yet contain auth-required additions (see 4.3).

### 4.2 Users table — CONFIRMED from `schema.sql` / `Database.md`

| Column | Type | Notes |
|---|---|---|
| id | UUID PK | gen_random_uuid() |
| name | TEXT NOT NULL | |
| email | TEXT UNIQUE NOT NULL | login identifier |
| phone | TEXT UNIQUE NOT NULL | login identifier |
| password_hash | TEXT | nullable at RC1 |
| date_of_birth | DATE | |
| gender | TEXT | |
| membership_tier | TEXT NOT NULL DEFAULT 'free' | CHECK `free`/`pro` |
| joined_at | TIMESTAMPTZ | |
| emergency_contact_name/_relation/_phone | TEXT | |
| created_at / updated_at | TIMESTAMPTZ | |

**Present:** UUID PK, `password_hash`, email+phone UNIQUE login keys,
timestamp audit.
**Missing (NOT FOUND in schema):** `role`, `is_active`, `is_verified`,
`last_login_at`, `failed_login_attempts`, `lockout_at`.

### 4.3 Auth-related schema gaps (analysis-documented, not in schema)

| Item | Schema status | Documented intent |
|---|---|---|
| `refresh_tokens` table | **NOT FOUND** | ANALYSIS §2.3 + ROADMAP §3: store **hashed** refresh tokens in a Postgres table (no Redis) |
| `request_log` table (rate-limit counters) | **NOT FOUND** | ANALYSIS §2.3 suggests optional; ROADMAP §3 allows in-memory for MVP instead |
| `sessions` table | **NOT FOUND** | not planned |
| `users.role` | **NOT FOUND** | ANALYSIS §4.2.3 + ROADMAP: RBAC roles `customer`/`mechanic`/`admin` as a `users` column |
| `users.is_active` / `is_verified` / lockout columns | **NOT FOUND** | ANALYSIS §2.3 (needed for login throttling + account status) |

### 4.4 Conventions (CONFIRMED from `Database.md` / `schema.sql`)

- **UUID PKs** (`gen_random_uuid()`); **TIMESTAMPTZ**; money `NUMERIC(12,2)`.
- **Soft delete** quoted as convention (`deleted_at where noted`) but **not
  uniformly applied** in `schema.sql` (ANALYSIS §2.3 flags this; decide once).
- **FK conventions**: `user_id UUID NOT NULL REFERENCES users(id)`.
- **VARCHAR statuses + CHECK constraints** bound to frozen client enums.
- `created_at`/`updated_at` on mutable tables (`conversations`, `products`, …).

### 4.5 Baseline migration

`alembic/versions/0001_baseline.py` is an **empty root revision** (verified
content + `alembic upgrade head --sql` earlier: only `alembic_version`
bookkeeping; **no tables**). Task 3 will add auth tables via a **new** revision
(`0002_…`); baseline is NOT to be modified.

---

## 5. API Contract Findings

### 5.1 Documented Auth endpoints (DOCUMENTED CONTRACT)
Canonical: `docs/backend/Authentication.md` §2 + `docs/backend/Architecture.md`
§4.1 (base `/api/v1/auth/`):

| Method | Path | Description |
|---|---|---|
| POST | `/api/v1/auth/register` | Register new user |
| POST | `/api/v1/auth/login` | Login with email/phone |
| POST | `/api/v1/auth/refresh` | Refresh JWT token |
| POST | `/api/v1/auth/verify` | Verify account |
| POST | `/api/v1/auth/forgot-password` | Send reset link |
| POST | `/api/v1/auth/reset-password` | Reset password |

### 5.2 NOT CURRENTLY DEFINED

| Endpoint | Status |
|---|---|
| `GET /api/v1/auth/me` | **NOT DEFINED** in any canonical doc (users GET `/{id}` exists under `/api/v1/users/` for profile; no `/auth/me`) |
| `POST /api/v1/auth/logout` | **NOT DEFINED** in canonical docs |
| `POST /auth/register` request/response payload shapes | **NOT DEFINED** at the HTTP-field level (frontend only validates email format + password ≥ 6 + confirm match) |

**RECOMMENDATION:** Adopt exactly the six documented endpoints first; surface
`/auth/me` and `/auth/logout` as **decisions** (§10) since the frozen client
currently maps "profile" to `/api/v1/users/{id}` and logout is on-device only.

### 5.3 Live surface vs contract

Currently registered: only `/health` + 5 AI routes (openapi PATH COUNT 6). No
auth, users, or any business routes exist yet (CONFIRMED FROM REPOSITORY).

---

## 6. Dependency Findings

### 6.1 Existing (CONFIRMED from `requirements.txt` / venv)

fastapi 0.139.0 · uvicorn 0.49.0 · pydantic 2.13.4 · pydantic-settings 2.14.2 ·
pandas · numpy · scikit-learn · xgboost · joblib · python-multipart ·
python-dotenv · requests · **firebase-admin 7.5.0** · langchain 1.3.11 ·
langchain-community · langchain-google-genai · faiss-cpu · sentence-transformers ·
pypdf · python-docx · **sqlalchemy 2.0.51 · greenlet 3.5.3 · asyncpg 0.31.0 ·
alembic 1.19.1**.

Dev: pytest 9.1.1 · pytest-asyncio 1.4.0 · (venv also has `anyio`, `httpx`,
`langsmith` as transitive deps).

### 6.2 Required for auth — MISSING (vs roadmap §0, ANALYSIS §4.2, BLUEPRINT)

| Package | Purpose | Present? |
|---|---|---|
| `python-jose[cryptography]` | JWT create/verify | **NOT FOUND** |
| `passlib` (+ bcrypt backend) | password hashing | **NOT FOUND** |
| `bcrypt` | bcrypt library (passlib backend) | **NOT FOUND** |
| `httpx` | async test client for API tests | NOT in requirements-dev (present transitively) |
| `email-validator`/mime libs | verification/forgot-password email (if email) | **NOT FOUND** — depends on strategy |

Firebase (`firebase-admin`) is installed for FCM/credentials; auth itself is
documented as **JWT + bcrypt** (native), not Firebase Auth, in the canonical
backend docs — but `Authentication.md`/handbook mention Firebase Auth + JWT in
spots (see §7.5 conflict). **Do NOT install anything in this reconnaissance
phase.**

---

## 7. Security Design Findings

CONFIRMED FROM DOCUMENTATION (canonical `Authentication.md`, `Architecture.md`
§6, `CODING_STANDARDS.md` §2, `SECURITY.md`, roadmap) unless marked otherwise:

| Topic | Contract | Status |
|---|---|---|
| **Access-token lifetime** | **15 minutes** | DOCUMENTED |
| **Refresh-token lifetime** | **7 days** | DOCUMENTED |
| **Password hashing** | **bcrypt** (passlib); cost not stated in canonical docs (legacy handbook shows cost=12 — archived) | DOCUMENTED (algo), **cost= REQUIRES DECISION** |
| **RBAC roles** | `customer`, `mechanic`, `admin` | DOCUMENTED |
| **Token storage (refresh)** | ⚠️ **CONFLICT** — `Authentication.md`/`Infrastructure.md`/`Architecture.md` say Redis; `ROADMAP` §3 + `ANALYSIS` §2.3/§6 say **Postgres `refresh_tokens` (hashed), no Redis** | **REQUIRES DECISION → Postgres per roadmap (recommended)** |
| Refresh-token hashing | hashed in Postgres (ANALYSIS/ROADMAP) — hash function (e.g. SHA-256) **NOT stated** | REQUIRES DECISION |
| **Token revocation** | open sessions revocable at refresh/rotate (legacy handbook); formal rotation policy **NOT in canonical docs** | REQUIRES DECISION |
| **Account verification** | `/verify` endpoint exists; mechanism (email code/OTP/phone) **NOT specified** | REQUIRES DECISION |
| **Password reset** | `/forgot-password` + `/reset-password` exist; delivery mechanism (email link / token) **NOT specified** | REQUIRES DECISION |
| **Rate limiting** | auth **10/min** (`Authentication.md` §3, `Architecture.md` §6.4, ANALYSIS §3.5); global 100/min IP, AI 60/min | DOCUMENTED; **repo = none**; implementation in-memory for MVP (ROADMAP) |
| **Auth failure handling / lockout** | lockout on failed login mentioned (ANALYSIS §6, SECURITY); attempt count / window **NOT in canonical docs** (legacy handbook: 5 attempts / 10 min — archived) | REQUIRES DECISION |
| **JWT settings / secret** | `JWT_SECRET_KEY`, `JWT_ALGORITHM`, `ACCESS_TOKEN_EXPIRE_MINUTES` (etc.) to be added to config | UNDEFINED (planned) |
| **Token transport** | Bearer header assumed (Bearer sample in legacy handbook; not in canonical docs) | REQUIRES DECISION |

---

## 8. Testing Findings

### 8.1 Current tests (CONFIRMED FROM REPOSITORY)

`backend/tests/`:
- `conftest.py` — session-scoped `event_loop` fixture; autouse
  `_reset_database_state` (calls `dispose_engine()` before/after).
- `test_database_foundation.py` — **8 tests** (Base declarative, unconfigured
  state, engine creation, async session factory, reconfigure disposes old
  engine, dispose clears state, `get_db` raises when unconfigured,
  `check_database()` false when unconfigured).

**Result: 8 passed, 0 warnings** (re-verified `pytest tests/ -q`). No
FastAPI TestClient/httpx tests, no DB-isolation-against-real-DB strategy, no
coverage tooling yet (coverage ≥80% new code / 100% auth per
`CODING_STANDARDS.md` §2 is an aspirational target).

### 8.2 Auth testing gap

- **Test DB**: none. Tests are DB-agnostic by design (no live Postgres). No
  migration-strategy for tests (transactional rollback / per-test DB) defined.
- **Fixtures**: no user fixtures, no auth header fixtures, no mock token util.
- **Async**: pytest-asyncio `Mode.STRICT`; anyio plugin present.

---

## 9. Architecture Compatibility

Target tree (`SPRINT_2_ROADMAP.md` §1) vs today (CONFIRMED):

```
backend/app/
├── main.py                    ✅ exists
├── core/                      ✅ exists (config, database, exceptions, logging)
│                                ➕ needs security.py (JWT/bcrypt)
├── api/
│   ├── deps.py                ➕ NEEDED (get_db, get_current_user, role_required, rate_limit)
│   └── v1/                    ✅ exists (3 feature routers)
│                                ➕ auth.py, users.py
├── models/                    ➕ NEEDED (user.py first, + auth tables) — NEW dir
├── schemas/                   ✅ exists ➕ auth.py, user.py
├── repositories/              ➕ NEEDED (base + users) — NEW dir
├── services/                  ✅ exists ➕ auth_service.py
└── middleware/                ➕ optional for MVP (rate-limit/security headers later)
```

**Verdict:** the auth implementation fits cleanly; **nothing existing needs to
be rewritten**. `router.py` mounts feature routers under `/api/v1` — an `auth`
router will be added the same way. Repository pattern + `Depends` are the
documented conventions; no empty dirs are to be created — only what Task 3
genuinely needs (`models/user.py`, `repositories/{base,users}.py`,
`api/deps.py`, `services/auth_service.py`, `core/security.py`,
`schemas/{auth,user}.py`, `api/v1/auth.py`).

---

## 10. Missing / Undefined Decisions

| # | Item | Where used | REQUIRES DECISION |
|---|---|---|---|
| D1 | Refresh-token store | **Redis vs Postgres `refresh_tokens`** — canonical auth/infra docs say Redis; roadmap/analysis (no-Redis constraint) say Postgres hashed | → **Postgres (recommended, roadmap-aligned)** |
| D2 | Refresh-token hashing algorithm | e.g. SHA-256 digest stored in `refresh_tokens.token_hash`; plaintext JWT also passed to client | hash fn to choose |
| D3 | `users` auth columns | **`role`, `is_active`, `is_verified`, `last_login_at`, `failed_login_attempts`, `lockout_at`** — absent from schema.sql; must be added via new migration | add + defaults |
| D5 | Token rotation & revocation | on each `/refresh`, rotate + expire old hashed row? blacklist? | policy |
| D6 | Verification mechanism | `/verify` — email code, phone OTP, or link | mechanism |
| D7 | Password-reset delivery | email link? reset token (TTL) in DB? | mechanism |
| D8 | bcrypt cost | canonical docs don't state; legacy = 12 | cost factor |
| D9 | Account lockout policy | attempt count / lock window (legacy: 5 / 10 min) | numbers |
| D10 | `/auth/me` & `/auth/logout` | **NOT defined** in canonical docs; client maps profile→`/users/{id}`, logout on-device | include or omit |
| D11 | JWT claims & issuer/audience | `sub` = user id, `exp`, `iat`, `jti`(rotation) | set |
| D12 | Token transport | Bearer `Authorization` header; refresh token body/cookie | set |

---

## 11. Recommended Task 3 Implementation Order

Sequential, each landed + unit-tested before the next:

1. **Dependencies** (approve + pin): `python-jose[cryptography]`, `passlib`,
   `bcrypt`. Install into venv, pin in `requirements.txt`.
2. **Config**: add `JWT_SECRET_KEY`, `JWT_ALGORITHM`, `ACCESS_TOKEN_EXPIRE_MINUTES`,
   `REFRESH_TOKEN_EXPIRE_DAYS` (+ `.env.example` placeholders; keep secrets out of git).
3. **Models + migration**: `models/user.py` (+ refresh token model) mirroring
   `schema.sql` **plus** decided auth columns (D3); new Alembic revision
   `0002_…` (baseline untouched); `alembic upgrade head --sql` checked offline.
4. **Security core**: `core/security.py` — bcrypt hash/verify (bcrypt_password, passlib `CryptContext`),
   JWT create/verify, refresh-token hash util.
5. **Repository layer**: `repositories/base.py` (get/list/create/update/delete + soft-delete),
   `repositories/users.py` (+ refresh tokens).
6. **Dependencies**: `api/deps.py` — `get_db`, `get_current_user`, `role_required`.
7. **Schemas + services**: `schemas/auth.py`, `schemas/user.py`;
   `services/auth_service.py` (register/login/refresh/verify/forgot+reset, lockout check).
8. **Routes**: `api/v1/auth.py` + `api/v1/users.py` (profile scope); mount in `router.py`.
9. **Auth rate-limit** (in-memory, auth 10/min) + secure failure messages; map
   security exceptions through existing `main.py` handlers.
10. **Tests** (auth-focused, ≥100% per standards): password hash/verify, JWT
    lifecycle, register/login/refresh, wrong-password, role guard, lockout,
    token rotation; TestClient with `get_db` override + fake/in-memory store
    (no live DB required initially), then final full-suite run.

---

## 12. Risks

| Risk | Mitigation |
|---|---|
| `users.role`/auth columns not in frozen schema.sql → schema contract deviation | Add via **new** migration with explicit owner approval; document in report; keep additive |
| passlib+bcrypt on Python 3.13 wheels | Verify install early (venv is 3.13.5); pin tested versions |
| Redis vs Postgres refresh-token conflict | Decide D1 **before** coding; roadmap recommends Postgres |
| Breaking frozen AI routes when wiring `get_db` | AI endpoints stay DB-free/unauthenticated; auth protection applied to new business routes only |
| No live Postgres on the machine | Tests remain DB-agnostic (dependency-override); live `SELECT 1` deferred as before |
| Client contract drift (no `/auth/me`, local logout) | Ship the 6 documented endpoints; treat `/auth/me`+`/logout` as approved additions only if owner decides |

---

## 13. Exact Files Expected to Change During Task 3

### New (expected)
- `backend/app/core/security.py`
- `backend/app/models/user.py` (+ refresh-token model, e.g. `refresh_token.py`)
- `backend/app/api/deps.py`
- `backend/app/api/v1/auth.py`
- `backend/app/api/v1/users.py` (minimal, profile-scoped)
- `backend/app/repositories/base.py`
- `backend/app/repositories/users.py`
- `backend/app/services/auth_service.py`
- `backend/app/schemas/auth.py`
- `backend/app/schemas/user.py`
- `backend/alembic/versions/0002_auth_*.py`
- `backend/tests/test_auth.py` (+ any fixtures, e.g. `test_security.py`)
- possibly `backend/app/middleware/rate_limit.py` (MVP) and
  `backend/scripts/` helpers `(e.g., hash util)`

### Modified (expected)
- `backend/requirements.txt` (+ python-jose, passlib, bcrypt)
- `backend/.env.example` (+ JWT_* placeholders)
- `backend/app/core/config.py` (+ JWT_* settings)
- `backend/app/api/router.py` (mount auth/users routers)
- `backend/docs` — Task 3 report (additive)

### Explicitly NOT changed
- `frontend/**` source, `backend/ai/**`, existing services (chat/diagnosis/rag),
  existing schemas (chat/diagnosis/knowledge), baseline `0001` migration,
  `core/database.py` / `core/exceptions.py` / `core/logging.py` / `main.py`
  lifespan/health behavior (unless additive auth middleware approved).

---

## 14. Validation Performed

All read-only (no mods, no installs, no migrations, no DB changes):

| Check | Result |
|---|---|
| `git status --short` | clean |
| `git log --oneline -6` / HEAD vs origin/main | `b6eaa60` == `origin/main` ✅ |
| `alembic heads` | `0001 (head)` (baseline only) ✅ |
| `pytest tests/ -q` | **8 passed, 0 warnings** (0.11s) ✅ |
| Import `app.main` + `app.openapi()` | **PATH COUNT 6**: `/health`, 5 AI routes ✅ |
| `/health` via TestClient | HTTP 200, `database: not_configured` ✅ |
| `docs/CANONICAL_DOCUMENT_MAP.md` | canonical sources identified (Database.md, Authentication.md, API.md, Architecture.md) ✅ |
| `schema.sql` | 39 tables, users/role/auth columns absent — **documented gap** ✅ |
| Repo-wide auth grep | **no auth code/deps found** ✅ |

Note: app import loads the AI stack (FAISS AVX2 fallback + unauthenticated HF
HEAD requests observed) — documented pre-existing behavior; unchanged.

---

## 15. Final Recommendation

**CONFIRMED READY TO IMPLEMENT Task 3 (Authentication Foundation).**

- The Sprint-2 foundation is correct and verified; auth is a **green-field
  build** — nothing existing will be broken.
- **Blocking decisions to settle first (with the owner):** D1 (refresh-token
  store → Postgres recommended), D3 (auth columns on `users` incl. `role`,
  `is_active`, `is_verified`, lockout fields), D6/D7 (verification &
  password-reset mechanisms), D8/D9 (bcrypt cost, lockout policy), D10
  (whether to add `/auth/me` + `/auth/logout` beyond the 6 documented
  endpoints).
- Implementation order per §11; tests per §8/§11; schema changes via **new**
  Alembic revision only.

---

*Predecessors: `SPRINT2_ENVIRONMENT_REPORT.md`, `SPRINT2_DATABASE_FOUNDATION_REPORT.md`,
`PRE_TASK3_RECONCILIATION_REPORT.md`, `PRE_COMMIT_REVIEW_REPORT.md`,
`SPRINT_2_ANALYSIS.md`, `SPRINT_2_ROADMAP.md`. Sources: repository inspection +
canonical docs (`Database.md`, `Authentication.md`, `API.md`, `Architecture.md`,
`CODING_STANDARDS.md`, `SECURITY.md`, `CANONICAL_DOCUMENT_MAP.md`).*

*No code, migrations, dependency installs, commits, or pushes performed.*