# Sprint 2 — Next Task Reconnaissance Report

**Scope:** READ-ONLY reconnaissance of the CURRENT repository (commit
`22f19e1` on `main`) to determine the correct next Sprint 2 task.
**Date:** 2026-08-15
**Method:** Documents used as context only; every claim below was re-checked
against the actual working tree, code, OpenAPI schema, migrations, and tests.

---

## 1. Current repository state

- Branch `main` at `22f19e1` (`feat(backend): add authentication and
  conversation ownership`), in sync with `origin/main`.
- Working tree clean EXCEPT one untracked file:
  `docs/backend/architecture/TASK3_TASK4_COMMIT_REPORT.md` (the commit/push
  report from the previous gate — documentation only, no code).
- Python 3.13.5 (system and `backend/venv`).

## 2. Completed work (verified, not assumed)

| Task | Status | Evidence |
|---|---|---|
| Task 1 — Backend foundation/package cleanup | ✅ committed (prior) | — |
| Task 2 — Database foundation | ✅ `core/database.py`, `alembic` scaffold, migration `0001_baseline` | files present |
| Task 3 — Authentication foundation | ✅ commit `22f19e1` | `security.py`, `deps.py`, `auth.py`, `auth_service.py`, `rate_limit.py`, migration `0002` |
| Task 4 — Conversation ownership/persistence | ✅ commit `22f19e1` | `conversation.py`+`chat_message.py` models, migration `0003`, repos, ChatService refactor |

## 3. Actual implementation audit (Phase 2)

### 3.1 Implemented (real code, opened/checked this session)

**Models (`app/models/`):** `User`, `RefreshToken`, `Conversation`,
`ChatMessage` — registered in `models/__init__.py` on `Base.metadata`.
This is **3 of the 39 schema.sql tables** (`users`, `conversations`,
`chat_messages`) plus the Task 3 addition `refresh_tokens`.

**Repositories (`app/repositories/`):** `BaseRepository` (base), `users`,
`conversations`, `chat_messages`.

**Services (`app/services/`):** `auth_service`, `chat_service`
(request-scoped, owner-guarded), plus pre-existing `diagnosis_service`,
`rag_service`.

**Schemas:** `auth.py`, `user.py`, `chat.py`, `diagnosis.py`, `knowledge.py`.

**Routes (`app/api/v1/`):** `auth.py`, `conversation.py`, `diagnosis.py`,
`knowledge.py`.

**Core:** `config.py` (JWT + DB settings), `security.py`, `deps.py`
(`get_current_user`, `role_required`, `get_auth_rate_limit`), `database.py`,
`rate_limit.py`, `exceptions.py`, `logging.py`.

### 3.2 Endpoints that currently exist (14 total — from real `app.openapi()`)

| Method | Path | Auth |
|---|---|---|
| POST | `/api/v1/auth/register` | none |
| POST | `/api/v1/auth/login` | none |
| POST | `/api/v1/auth/refresh` | none |
| POST | `/api/v1/auth/verify` | none |
| POST | `/api/v1/auth/forgot-password` | none |
| POST | `/api/v1/auth/reset-password` | none |
| POST | `/api/v1/auth/logout` | none |
| GET | `/api/v1/auth/me` | HTTPBearer |
| POST | `/api/v1/conversation/session` | HTTPBearer |
| POST | `/api/v1/conversation/chat` | HTTPBearer |
| GET | `/api/v1/conversation/history` | HTTPBearer |
| POST | `/api/v1/diagnosis/diagnose` | HTTPBearer |
| POST | `/api/v1/knowledge/query` | HTTPBearer |
| GET | `/health` | none |

### 3.3 What is DOCUMENTED ONLY (not implemented)

- **All business modules:** Marketplace (categories/brands/products/offers/
  coupons/orders), Mechanic (mechanics/services/bookings), Fuel (stations/
  orders/tracking/invoices), Profile (vehicles/addresses/wallet/rewards/
  notification settings), Home — **no models, repos, or routes exist** beyond
  the roadmap/API docs.
- **`diagnoses` table** (schema.sql) — defined in schema but **no model, no
  migration, no endpoints**. Diagnosis today is stateless
  (`diagnosis_service.predict_fault` → response), nothing persisted.
- **Conversation LIST endpoint** — the frontend AI contract requires
  `fetchConversations()` (list, pinned-first, newest `updatedAt`); the backend
  only has `session`/`chat`/`history`. **No `GET /conversations`.**
- **Migration `0004`+** — none exist (head is `0003`).
- Frontend HTTP repositories — all frontend repositories (`auth_repository`,
  `ai_repository`, `profile_repository`, `marketplace_repository`, …) are
  **in-memory mocks**; no Dart HTTP layer exists yet.

### 3.4 Migration state (real output this session)

- Alembic history: `<base> → 0001 → 0002 → 0003 (head)`; `heads` = `0003`.
- `alembic upgrade head --sql` (offline, deterministic):
  - `0001` baseline (no tables).
  - `0002` creates `users` + `refresh_tokens` (with CHECKs, unique indexes,
    cascade FK for refresh_tokens.user_id).
  - `0003` creates `conversations` + `chat_messages` (CHECK role, cascade FKs,
    indexes). Matches `schema.sql` §conversations/chat_messages.
- `alembic current` requires a live DB → **NOT VERIFIED** (see §8).

### 3.5 schema.sql vs ORM/migrations mismatch check

- No regressions/mismatches found in the implemented 3 tables; Task 3 added
  auth columns (`role`, `is_active`, `is_verified`, `last_login_at`,
  `failed_login_attempts`, `lockout_at`) to `users` — an **approved additive
  change** beyond schema.sql (documented in Task 3 reports).
- **Gap (not a mismatch):** 36 of 39 schema tables are not yet modeled.

### 3.6 Frontend/backend contracts already in force

- AI: `fetchConversations()` / `sendMessage(conversationId, message)` /
  `diagnoseVehicle(...)` (API.md §4). Backend partially covers this (chat
  works owner-bound) but **no list-conversations endpoint** and **no
  diagnosis persistence**.
- Profile: `fetchProfile/saveProfile`, vehicle CRUD + setDefault, address CRUD
  + setDefault, `fetchWallet`, `fetchRewards`, `fetchStats`, `fetchOrders`,
  notification settings (API.md §8) — **entirely unimplemented on the backend.**
- Marketplace/Mechanic/Fuel/Home — **entirely unimplemented** (API.md §5–7).

## 4. Test / runtime verification (Phase 3, actually run this session)

| Check | Result |
|---|---|
| `git status` / `git log -3` / `git branch -vv` | ✅ main @ 22f19e1, synced; 1 untracked doc |
| Python version | ✅ 3.13.5 |
| `venv python -m pytest tests/ -q` | ✅ **273 passed** (19.05s, 77 warnings) |
| Import real app (`app.main`) | ✅ imports (RAG/FAISS/embedding load on import) |
| `app.openapi()` | ✅ **14 paths**; security on auth.me + all conversation + diagnosis + knowledge; `/health` + auth public |
| Alembic history / heads | ✅ 0001→0002→0003, head=0003 |
| `alembic upgrade head --sql` | ✅ offline SQL correct, matches schema.sql |
| `alembic current` | ❌ NOT VERIFIED — needs live DB (URL unset) |
| Live `/health` probe | ✅ 200 (via TestClient, `database: not_configured`) |
| Accidental changes/secrets/generated | ✅ none tracked; only 1 untracked doc; `__pycache__` ignored |

## 5. PostgreSQL / environment limitations

- `DATABASE_URL` is **unset** in `backend/.env` (existing repo state). No live
  PostgreSQL exists/connects: `alembic current`, real migration application,
  real FK/CASCADE/transaction behavior, and real multi-request durability are
  **NOT VERIFIED** (documented pre-existing Stage 7/8 posture).
- No live Gemini call; LLM paths are exercised through fakes in tests.

## 6. Remaining Sprint 2 work (roadmap reference)

Per `SPRINT_2_ROADMAP.md` module order (0→1→2→3→4→…), modules 0–3 are complete
(dev env, core+DB, auth, repositories). Task 4 already delivered the
conversation half of module 8. Remaining:

| Module | Work | Status |
|---|---|---|
| **4 — Users & Profile APIs** | profile GET/PUT; vehicles CRUD+setDefault; addresses CRUD+setDefault; wallet/transactions/rewards; notification settings | **NEXT** |
| 5 — Mechanics | list/detail, services/categories, reviews, bookings state machine | pending |
| 6 — Fuel | stations/partners, price estimate, orders lifecycle, tracking, invoices | pending |
| 7 — Marketplace & Orders | catalog, offers/coupons, orders + order_entries feed | pending |
| 8 — AI (remainder) | `diagnoses` persistence + list-conversations endpoint | partial |
| 9 — Tests | ongoing (273 green) | ongoing |
| 10 — Middleware & hardening | security headers, request logging, validation handler | pending |
| 11 — Ops | Docker, docker-compose, CI | pending |

## 7. Recommended next task (Phase 4)

### **Task 5 — Users & Profile APIs (Roadmap Module 4)**

**Why it is next:**
1. Roadmap order: modules 0–3 complete; module 4 is the next sequential
   business module ("then 4,8" per the roadmap's business-critical priority).
2. **Dependency readiness:** it depends on Core+DB (Task 2), Auth + repos
   (Task 3) — all present and green. The `users` table, `get_current_user`,
   and `BaseRepository` already exist to build on.
3. **Frontend contract is frozen and entirely unserved:** the Flutter Profile
   feature (vehicles, addresses, wallet, rewards, notification settings) is
   fully built against mock data (API.md §8). Wiring it to real endpoints is
   the largest remaining business surface and unlocks the whole Profile tab.
4. Module 8 remainder (diagnoses persistence) is smaller and does not block
   module 4; it can follow.

**What it depends on:** Task 2 (DB), Task 3 (auth/`get_current_user`,
repos), `BaseRepository`; `schema.sql` tables `vehicles`, `addresses`,
`wallet`, `wallet_transactions`, `reward_ledger`, `notification_settings`;
frozen ID schemes (`veh-`, `addr-`, `txn-`, `rew-`, `pay-`); API.md §8
ordering guarantees (default-first vehicles/addresses).

**Files/tables/routes likely involved:**
- Models: `vehicle.py`, `address.py`, `wallet.py` (or wallet +
  wallet_transaction + reward_ledger), `notification_settings.py` + register
  in `models/__init__.py`.
- Migration `0004_profile` (additive, mirrors schema.sql).
- Repos: `vehicles`, `addresses`, `wallet`, `reward`, `notification_settings`.
- Schemas: profile, vehicle, address, wallet, reward, notification.
- Service: `profile_service` (or per-domain services).
- Routes: `app/api/v1/users.py` / `profile.py` (mounted under `/api/v1`),
  e.g. `GET/PUT /users/me`, `GET/POST/PUT/DELETE /vehicles`,
  `GET/POST/PUT/DELETE /addresses`, `GET /wallet`, `GET /rewards`,
  `GET/PUT /notification-settings` — exact REST shape to align with API.md §8
  method surface.

**Explicitly OUT OF SCOPE:**
- Marketplace, Mechanic, Fuel, Home modules (roadmap 5, 6, 7).
- `diagnoses` persistence / AI list endpoint (module 8 remainder).
- Frontend Dart HTTP layer, middleware hardening (module 10), ops (module 11),
  seeding of marketplace/mechanic/fuel mock data.

**Risks:**
- Wallet/reward money types (`NUMERIC(12,2)`) must serialize correctly to the
  frontend's `double` INR contract.
- Ordering guarantees (default-first vehicles/addresses, home→office→other)
  are frozen; tests must assert them.
- Profile edit must not let a client change `role`/`membership_tier`/`email`
  arbitrarily (ownership + role safety).
- `deleted_at` soft-delete convention is not uniform in schema.sql — decide
  once for vehicles/addresses.

**Required architecture decisions:**
- REST shape vs API.md method surface (additive, backward-compatible).
- Soft-delete policy for vehicles/addresses.
- Whether wallet/rewards are read-only endpoints (likely) vs mutation.
- Route dependency pattern: reuse `Depends(get_current_user)` + request-scoped
  service (mirror Task 3/4 wiring).

**Required manual verification:** open every new file; run pytest; run
`alembic upgrade head --sql` and confirm `0004` is additive; import real app +
inspect OpenAPI (new paths + security); git hygiene.

**Expected test strategy:** fake-session pattern (mirror
`test_conversation_ownership.py` / `test_auth_*`) + real `get_current_user`;
ownership + ordering + validation + auth-required tests; OpenAPI path-count
update (14 → expected new count).

**PostgreSQL required?** No for tests (fake sessions). Live-DB checks remain
**NOT VERIFIED** until a database is provisioned.

**Frontend changes required?** No (frozen contract; mock repos stay until a
later wiring task).

**Estimated complexity:** Medium (~8–10h per roadmap module 4 estimate).

**Alternative considered (rejected for now):** Complete module 8 (AI
`diagnoses` persistence + `GET /conversations`). Smaller and low-risk, but
the roadmap's sequential order and the business-critical Profile surface make
module 4 the stronger next step; module 8 remainder can be Task 6.

## 8. Manual verification results (summary)

| Item | Status |
|---|---|
| Git clean (except 1 untracked doc) | ✅ MANUALLY VERIFIED |
| 273 tests pass | ✅ MANUALLY VERIFIED |
| App imports + OpenAPI 14 paths | ✅ MANUALLY VERIFIED |
| Alembic history/heads + offline SQL | ✅ MANUALLY VERIFIED |
| Migration 0004 required (none exists) | ✅ MANUALLY VERIFIED (absence) |
| Live PostgreSQL behaviors | ❌ NOT VERIFIED (DATABASE_URL unset) |
| Diagnoses/other 36 tables implemented | ❌ DOCUMENTED ONLY (not implemented) |

## 9. Exact proposed implementation stages (for Task 5, to be approved)

1. **Stage 1 — Models & migration:** add the 6 models + register; author
   `0004_profile` migration (additive, mirrors schema.sql); verify offline SQL.
2. **Stage 2 — Repositories:** per-domain repos extending `BaseRepository`
   (owner-scoped where user-bound; default-first ordering).
3. **Stage 3 — Schemas:** Pydantic request/response (frontend contract, money
   as INR-compatible numbers, additive fields).
4. **Stage 4 — Service:** `profile_service` wiring (mirror AuthService/
   ChatService request-scoped pattern).
5. **Stage 5 — Routes:** `users.py`/`profile.py` with `Depends(get_current_user)`;
   mount in `api/router.py`; update OpenAPI path-count expectations.
6. **Stage 6 — Tests:** ownership, ordering, validation, auth-required,
   OpenAPI; full suite green.
7. **Stage 7 — Reports + manual review gate** (implementation + verification).

---

*Reconnaissance ends. No files modified, no DB touched, no commits/pushes
performed during this recon.*