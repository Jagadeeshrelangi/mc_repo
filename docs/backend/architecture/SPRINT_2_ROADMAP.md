# Sprint 2 — Backend Implementation Roadmap & Final Report

> **Sprint 2 · Phase 1: Foundation · 2026-08-07**
> Companion to `SPRINT_2_ANALYSIS.md` (inspection) and the existing
> `SPRINT_2_BACKEND_BLUEPRINT.md` (kept for history/context). This document is
> the forward plan that reflects the **current** codebase state.

---

## 1. Modularization & Production Architecture (Tasks 2 & 3)

Remain a **modular monolith** (single deployable, shared DB — right for MVP).
Clean layering under `backend/app/`:

```
backend/app/
├── main.py                    app factory, middleware, /health
├── core/                     config, database (engine/session), security (JWT/bcrypt),
│                             exceptions, logging, dependencies (Depends helpers)
├── api/
│   ├── deps.py              get_db, get_current_user, role_required, rate_limit
│   └── v1/                  auth, users, vehicles, addresses, wallet, mechanics,
│                            fuel, marketplace, orders, ai (conversation/diag),
│                            admin
├── models/                  SQLAlchemy models (mirror schema.sql: 39 tables)
├── schemas/                 Pydantic request/response per domain
├── repositories/            data-access per domain (session-injected)
├── services/                business logic (reuse existing AI services)
└── middleware/              security headers, request logging, rate limit
```

**Guideline: only create genuinely-needed folders — do not scaffold empty
dummy dirs around every feature; build on demand per module.**

### Dependency order (module graph)
1. **Core** (config, database, exceptions, logging) — zero deps.
2. **Auth** (security.py, users, deps) — depends on Core + DB.
3. **Database/tools** (models, repositories, migrations, seed) — Core+Auth.
4. Business domains **Users→Vehicles→Wallets** then **Mechanics→Fuel→
   Marketplace→Orders** then **AI persistence** — each depends on DB + auth
   + repos.
5. **Ops** (Docker, CI, tests) — after foundations are stable.

---

## 2. Implementation order with estimated effort

| # | Module | Deliverable | Effort (est) | Depends on |
|---|---|---|---|---|
| 0 | **Dev env** | add SQLAlchemy+asyncpg+alembic+python-jose+passlib+bcrypt+pytest(+asyncio); `core/database.py` | 3–4h | None |
| 1 | **Core + DB** | engine/session (async), session DI; alembic scaffold + **one initial migration** (fresh 39 tables); seed loader | 6–8h | 0 |
| 2 | **Auth** | `security.py` (JWT,bcrypt), `users` repo, register/login/refresh/verify/forgot+reset, RBAC deps, rate-limit on auth | 8–10h | 1 |
| 3 | **Repositories** | base `BaseRepository` (get/list/create/update/delete + soft-delete) + per-domain impl | 6–8h | 1 |
| 4 | **Users & Profile APIs** | profile GET/PUT; vehicles CRUD+setDefault; addresses CRUD+setDefault; wallet/transactions/rewards; notification settings | 8–10h | 2,3 |
| 5 | **Mechanics** | mechanics list/detail, mechanic_services/categories, mechanic_reviews, bookings state machine | 8–10h | 2,3 |
| 6 | **Fuel** | stations/partners list, price estimate, fuel_orders create/advance/cancel/complete, tracking events, invoices | 8–10h | 2,3 |
| 7 | **Marketplace & Orders** | categories/brands/products (filters), offers/coupons, orders, **order_entries** feed (unify Orders tab) | 8–10h | 2,3 |
| 8 | **AI persistence + chat** | conversations/chat_messages/diagnoses repos; `/conversations` CRUD; wire existing chat/rag/diag to DB; streaming support | 8h | 1,3 |
| 9 | **Tests** | pytest fixtures (test DB), unit (repos/services), integration (crud), API tests; ≥80% new-code coverage | 10–12h | 0..8 |
| 10 | **Middleware & hardening** | security headers, request logging, rate-limit global, validation handler, session cleanup | 4h | 0 |
| 11 | **Ops** | backend Dockerfile, docker-compose, CI job (`backend.yml`) pytest+lint, healthcheck | 4–6h | 9 |

**Road order actually follow:** 0→1→2→3→4→…→11 sequential; 10 can fold into
Phase where modules land. **Total ≈ 73–98h (~2.5–3 weeks).**
Prioritized for foundation: **0,1,2,3 then 4,8** (business-critical), the rest
snapshot for the first slice.

---

## 3. Production architecture decisions (Task 3)

- **Async SQLAlchemy 2.0** + `asyncpg`; session per request via FastAPI Depends.
- **Repository pattern** capturing data access; services stay thin + reusable
  existing AI services unchanged.
- **UUID PKs**, soft-delete where noted, `created_at`/`updated_at` everywhere.
- **JWT access (15m) + refresh (7d)**; refresh token **hashed in Postgres
  `refresh_tokens` table** (no Redis per infra constraint; rate-limit counters
  also in a small Postgres `request_log`, or in-memory per process for MVP).
- **RBAC** roles: `customer`, `mechanic`, `admin`.
- **In-memory sliding-window rate limit** for MVP (process-local); upgradeable.
- **BackgroundTasks / streaming** for LLM; **no Celery** (constraint).
- Reuse in `Python 3.13.5`, pinned deps.

---

## 4. Technical debt built so far

| Debt | Where | Fix |
|---|---|---|
| In-memory sessions (lost on restart) | chat_service | persist to DB (± Phase6) |
| Sync inference in request path | services | async/stream/background |
| No tests | — | pytest (module 9) |
| Model names hardcoded | chat_service:45, rag_service:44 | config |
| FAISS load `allow_dangerous_deserialization` | rag_service:34 | policy + check |
| Exception/history w/ HTTPException | conversation.py | domain exc + validation handler |
| Objects decoupled from repos/DI | app/ | add repositories+Deps |
| Missing middleware (rate-limit, security headers, request logging) | main.py | module 10 |

---

## 5. Risks

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Python 3.13 wheel availability (asyncpg/faiss) | Medium | High | pin tested versions; verify installs early (module 0) |
| Getting 39-table migration right | High | Medium | review models vs schema.sql before autogen |
| Breaking frozen AI behavior when wiring to DB | Medium | High | add tests around services first; keep fallbacks |
| FastAPI sync/streaming refactor churn | Medium | Medium | incremental; keep old endpoint working during shimming |
| Wide unit API surface (Orders tab, fuel ID schemes) | Medium | High | hard-code ID schemes from API.md, contract tests |
| No Redis constraint | Low-Medium | Medium | DB-backed refresh tokens + in-memory rate limit |

---

## 6. Final recommendation (Task 8)

**1.**
- **Start with Modules 0–3** (dev env, core+database+migrate+seed, auth,
  repositories). This is the true foundation; everything else hangs off it.
- **Reuse** all three AI services + exception/logging/config as-is (no
  rewrite).
- **Do NOT run** any destructive DB action; first migration is a fresh install.
- After modules 0–3 are implemented **and** the CI/tests gate passes, we get
  to module 4+ (business APIs).

Approval to begin **Step 0 (dev env)** required.

---

*Report ends. Analysis: `SPRINT_2_ANALYSIS.md`. Historical blueprint:
`SPRINT_2_BACKEND_BLUEPRINT.md`.*