# Sprint 2 — Database Foundation Report

> **Sprint 2 · Task 2: Database / Development Environment Foundation · 2026-08-07**
> Reconciliation with the Cline handover session plus implementation of the
> SQLAlchemy 2.x async + Alembic database foundation. Companion to
> `SPRINT2_ENVIRONMENT_REPORT.md` (Task 1) and the pre-interruption
> `SPRINT_2_ANALYSIS.md` / `SPRINT_2_ROADMAP.md`.

---

## 1. Executive Summary

| Metric | Value |
|---|---|
| **Overall backend health** | GOOD — boots, all 6 routes live, health 200 with `database: not_configured` |
| **Backend readiness** | **35%** (AI layer + database foundation in place; auth/models/repos/tests still building) |
| **Database stack** | SQLAlchemy 2.0.51 async + asyncpg 0.31.0 + Alembic 1.19.1 (PostgreSQL target) |
| **Live DB test** | **NOT AVAILABLE** — no PostgreSQL process/Docker daemon on this machine |

The Sprint 2 Task 2 database foundation is **installed and validated**: async
engine, session factory, `AsyncSession` dependency, declarative `Base`,
lazy configure-on-startup, health probe, Alembic async migration
infrastructure, and a connectivity check script. No business models were
created (per the task rule — those belong to later tasks).

---

## 2. Cline Handover / Reconciliation

### 2.1 What was inspected
- `git status` / `git log --oneline -30` / `git diff` / `git diff --cached`
- Working tree under `backend/`, `docs/backend/`, `.github/`, `scripts/`
- venv package list; requirements files; `.env` / `.env.example`
- New reports in `docs/backend/architecture/`

### 2.2 Cline state detected

**No Cline commits exist.** The only commit created during the outage window
is `c801688 feat(repo): freeze monorepo architecture and prepare Sprint 2`
authored by the repository owner at 10:26 on the freeze date — this matches
the pre-interruption monorepo freeze, not new Cline work.

Cline's **uncommitted** contributions (all PRESENT and VALIDATED):

| Item | Status |
|---|---|
| 7 × `__init__.py` (app, api, api/v1, core, schemas, services, ai) | ✅ correct, docstring-only markers |
| `docs/backend/architecture/SPRINT2_ENVIRONMENT_REPORT.md` | ✅ complete Task 1 report (matches observed state) |
| `SQLAlchemy 2.0.51` + `greenlet 3.5.3` installed in `backend/venv` | ⚠️ **partial** — installed but NOT added to `requirements.txt` |

### 2.3 Tagged findings

| ID | Finding | Resolution |
|---|---|---|
| C1 | `SQLAlchemy`/`greenlet` in venv but not pinned | **Corrected** in Task 2 — pinned to `requirements.txt` |
| C2 | venv import of `sqlalchemy` works; system python also has it | Documented; venv is the source of truth |
| C3 | Task 1 report uses `PASS/FAIL` and matches reality | Reused unchanged |
| C4 | No Task 2 work existed | Implemented from scratch in this report |

---

## 3. Files Created (this task)

| File | Why |
|---|---|
| `backend/app/core/database.py` | Async engine + session factory + `AsyncSession` dependency + `check_database()` + lifecycle helpers |
| `backend/alembic.ini` | Alembic config (URL intentionally empty; read from settings) |
| `backend/alembic/env.py` | Async Alembic environment importing app `Base` + settings DATABASE_URL |
| `backend/alembic/script.py.mako` | Migration template |
| `backend/alembic/versions/0001_baseline.py` | Empty root revision — establishes the chain without business tables |
| `backend/requirements-dev.txt` | Dev/test pins (`pytest`, `pytest-asyncio`) |
| `backend/scripts/db_check.py` | Standalone connectivity/readiness check (LIVE vs NOT AVAILABLE) |
| `backend/tests/conftest.py` | Test fixtures (session loop, state isolation) |
| `backend/tests/test_database_foundation.py` | 8 tests covering config/engine/factory/DI/readiness |

## 4. Files Modified (this task)

| File | Reason | Change summary |
|---|---|---|
| `backend/app/core/config.py` | Database support | Added `DATABASE_URL: Optional[str] = None` |
| `backend/app/main.py` | Lifecycle + health | Added `lifespan` (configure/dispose engine); `/health` now reports `database` status; import of DB helpers |
| `backend/requirements.txt` | Pin Cline-installed DB deps | Added `sqlalchemy==2.0.51`, `greenlet==3.5.3`, `asyncpg==0.31.0`, `alembic==1.19.1` |
| `backend/.env.example` | Document DB config | Added documented `DATABASE_URL=` placeholder + `CHANGE_ME` example |

## 5. Files Deleted

**None.** No files deleted (git rule respected).

---

## 6. Dependencies

**Added (pinned):**
| Package | Version | Reason |
|---|---|---|
| sqlalchemy | 2.0.51 | Async ORM |
| greenlet | 3.5.3 | SQLAlchemy asyncio requirement (already in venv, now pinned) |
| asyncpg | 0.31.0 | PostgreSQL async driver |
| alembic | 1.19.1 | Migrations |
| pytest | 9.1.1 | (dev) test runner |
| pytest-asyncio | 1.4.0 | (dev) async tests |

**Removed:** none.

## 7. Environment Variables

| Variable | Default | Purpose |
|---|---|---|
| `DATABASE_URL` | unset | Async Postgres URL `postgresql+asyncpg://user:pass@host:port/db`. Unset → app boots, DB features disabled. |
| Existing keys unchanged | — | `GEMINI_API_KEY`, `CORS_ORIGINS`, `LOG_LEVEL`, etc. |

**Security:** credentials must live only in `backend/.env` (gitignored,
verified via `git check-ignore`). No real credentials appear in any file;
`.env.example` uses `CHANGE_ME` placeholders.

---

## 8. SQLAlchemy Design

`app/core/database.py`:
- `Base(DeclarativeBase)` — single metadata root for all future models.
- `configure_database(url=None)` — idempotent; disposes prior engine; warns on
  non-Postgres scheme; leaves state unconfigured when URL empty.
- `engine = create_async_engine(url, pool_pre_ping=True, pool_size=5, max_overflow=10)`.
- `AsyncSessionFactory = async_sessionmaker(engine, expire_on_commit=False)`.
- `get_db()` — FastAPI `Depends` yielding an `AsyncSession`, rollback on error.
- `check_database()` — `SELECT 1` probe (no business tables required).
- `dispose_engine()` — teardown for tests/lifecycle shutdown.

**Design choices:** lazy configuration at app lifespan startup (never at
import); graceful no-DB boot; no second DB introduced (tests validate the
stack without connecting); sessions injected via `Depends`.

## 9. Alembic Design

- `alembic.ini` — `script_location = alembic`, `prepend_sys_path = .`,
  `sqlalchemy.url` intentionally blank (never hardcodes credentials).
- `alembic/env.py` — async engine runner (`async_engine_from_config`), reads
  `settings.DATABASE_URL` first, falls back to `.ini`; offline mode defaults to
  postgresql dialect so `upgrade head --sql` renders DDL without a live DB;
  `target_metadata = Base.metadata` for autogenerate.
- `versions/0001_baseline.py` — empty root revision (chain base).
- Verified: `alembic heads` → `0001 (head)`; `alembic upgrade head --sql` →
  `BEGIN; COMMIT;` (clean, offline).

## 10. Database Dependency

`get_db()` is exported from `app.core.database` and is the single injection
point for `AsyncSession` in future API routers. Currently no route consumes it
(no business models/routes yet — correct per task scope). The `get_db` path is
unit-tested (`test_get_db_raises_when_unconfigured`).

## 11. Health / Readiness

- `/health` now returns `{"status":"healthy", ..., "database": "<status>"}`.
  Statuses: `not_configured` (no URL), `ok`, `unreachable`, `error`.
  This is non-failing — the server stays healthy regardless of DB state.
- Standalone probe: `python scripts/db_check.py` → exit 0 (OK) / 1 (unset) /
  2 (failure).

## 12. Tests

Run: `pytest` in `backend/` (venv). **Results: 8 passed, 0 warnings**.
The earlier `RuntimeWarning: coroutine 'AsyncSession.close' was never
awaited` (from the async-session-factory test) was fixed by awaiting
`AsyncSession.close()` (a coroutine in SQLAlchemy 2.x) via `asyncio.run` in
the test. Verified clean both with plain `pytest` and with
`pytest -W error::RuntimeWarning`. Coverage topics: Base is declarative;
unconfigured state; engine creation (Postgres/asyncpg scheme); async session
factory; reconfiguration disposes old engine; dispose clears state; `get_db`
raises when unconfigured; `check_database()` false when unconfigured.

## 13. Live PostgreSQL Result

**LIVE DATABASE TEST: NOT AVAILABLE.**
- No `psql`, no Postgres service, port 5432 closed, Docker installed but
  daemon **not running**.
- The foundation is fully validated for configuration/wiring, but a real
  `SELECT 1` against live PostgreSQL could not be executed.
- **Manual action required:** start PostgreSQL (or Docker desktop), create DB
  `mecha_connect`, set `DATABASE_URL` in `backend/.env`, run
  `python scripts/db_check.py` (expect exit 0), then `alembic upgrade head`.

## 14. Security Review

- No real credentials anywhere; `.env.example` uses `CHANGE_ME`.
- `backend/.env` and `backend/venv` confirmed `git check-ignore`-protected.
- Alembic `.ini` contains no URL.
- DB check output masks the URL user part (`url.split("@")[-1]`).

## 15. Backward Compatibility

- All previously working behavior preserved: `/health` (still 200, now with an
  extra `database` field), `/docs`, `/redoc`, and the 6 API routes
  (`/api/v1/...`) verified live through TestClient (session 201, others 422 =
  expected validation on empty payloads, meaning routes are mounted).
- No AI service file modified. Gemini/RAG/Diagnosis behavior untouched.
- `DATABASE_URL` absence does not break boot (verified via lifespan TestClient).

## 16. Git Diff Summary

- Modified: `backend/app/core/config.py`, `backend/app/main.py`,
  `backend/requirements.txt`, `backend/.env.example`.
- Created (untracked): `backend/app/core/database.py`, `backend/alembic.ini`,
  `backend/alembic/` (env.py, script.py.mako, versions/0001_baseline.py),
  `backend/requirements-dev.txt`, `backend/scripts/db_check.py`,
  `backend/tests/` (conftest.py + test_database_foundation.py).
- Cline work preserved (7 `__init__.py`, Task 1 report, sqlalchemy/greenlet in
  venv — now pinned).
- `frontend/build/cache.dill.track.dill` was already staged in the working tree
  from the earlier freeze exercise; **not touched** by this task.

## 17. Breaking Changes

None. The `/health` response gained a `database` key (additive, backward
compatible). No route signatures or data models changed.

## 18. Manual Actions

1. Start PostgreSQL (Docker `docker compose up -d db` or a local instance).
2. `cp backend/.env.example backend/.env` (already present); set
   `DATABASE_URL=postgresql+asyncpg://user:pass@localhost:5432/mecha_connect`.
3. `cd backend && .\venv\Scripts\python.exe scripts\db_check.py` → expect exit 0.
4. `cd backend && .\venv\Scripts\python.exe -m alembic upgrade head`
   (applies baseline; future tasks add real migrations).
5. `cd backend && .\venv\Scripts\python.exe -m pytest` → 8 passed.
6. Review + commit (OpenCode does not commit without approval).

## 19. Remaining Technical Debt

| Area | Debt | Priority |
|---|---|---|
| Business models/repositories/auth | None yet — by design (later Task 3+) | Critical |
| Live DB verification | Not performed (no Postgres available) | High |
| `frontend/build/` tracked artifacts | Build output committed in freeze; hygiene cleanup | Low |
| LangChain deprecation | `HuggingFaceEmbeddings` from `langchain_community` warns | Medium |
| FAISS AVX2 fallback | Uses standard build under Windows wheel | Low |

## 20. Sprint 2 Readiness

**READY TO CONTINUE** within Task 2 scope:
- Database foundation implemented, pinned, tested (8/8), documented.
- Alembic offline verified; online live test deferred to postgres availability.
- No destructive operations executed; no unsolicited commits.

**Next task** (per stop condition): **Task 3 — Auth** (JWT/bcrypt/RBAC) once
approved.

---

*Report ends. Predecessors: `SPRINT2_ENVIRONMENT_REPORT.md`,
`SPRINT_2_ANALYSIS.md`, `SPRINT_2_ROADMAP.md`.*