# Sprint 2 — Backend Analysis Report

> **Sprint 2 · Phase 1: Analysis & Foundation Audit · 2026-08-07**
> Based on direct inspection of `backend/` (code, AI layer, schemas, docs,
> `schema.sql`, `.env` keys, `requirements.txt`) in the frozen monorepo.

---

## 1. Current Architecture (Short Report — Task 1)

### 1.1 Folder structure (actual)

```
backend/
├── .env / .env.example          ENV (5 keys: PROJECT_NAME, LOG_LEVEL,
│                                GEMINI_API_KEY, FIREBASE_CREDENTIALS_PATH,
│                                ENABLE_FALLBACK)
├── requirements.txt             Pinned exact versions (no ">=")
├── README.md
├── ai/
│   ├── build_rag_index.py       RAG index builder (txt/md/pdf/docx → FAISS)
│   ├── metadata.py              Fault → cost/time/safety lookup
│   ├── data/
│   │   ├── generate_data.py     Synthetic telemetry CSV generator
│   │   └── vehicle_telemetry.csv
│   ├── knowledge_base/          faiss_index/, manuals/, faq/, obd_codes/,
│   │                            dashboard_symbols/ (category folders)
│   └── models/
│       ├── train.py             XGBoost vs RandomForest trainer → champion
│       └── fault_classifier.joblib
└── app/
    ├── main.py                  FastAPI app, CORS, exception handlers, /health
    ├── api/
    │   ├── router.py            Mounts 3 feature routers
    │   └── v1/ (conversation.py, diagnosis.py, knowledge.py)
    ├── core/ (config.py, exceptions.py, logging.py)
    ├── schemas/ (chat.py, diagnosis.py, knowledge.py)
    └── services/ (chat_service.py, diagnosis_service.py, rag_service.py)
```

**No `models/`, `repositories/`, `dependencies/`, `middleware/`, `db/`,
`tests/`, or `alembic/` directories exist.**

### 1.2 Services in flight (singletons)

| Service | Module | Runtime state | Persistence |
|---|---|---|---|
| `chat_service` | `chat_service.py` | ChatService(LLM) | **in-memory `sessions: dict`** — lost on restart |
| `diagnosis_service` | `diagnosis_service.py` | load XGBoost joblib | read-only model load per process |
| `rag_service` | `rag_service.py` | FAISS + embeddings + LLM | FAISS on disk; no write-back |

All three are module-level singletons (`chat_service = ChatService()`), so
they are constructed at import time and hold heavyweight resources
(embedding model, FAISS index, model data) for the process lifetime.

### 1.3 Live HTTP surface (Task 5 — API review)

| Method | Path | Auth | Response model | Notes |
|---|---|---|---|---|
| POST | `/api/v1/conversation/chat` | none | ChatResponse | intent → diagnosis/RAG/LLM |
| POST | `/api/v1/conversation/session` | none | SessionResponse | UUID session |
| GET | `/api/v1/conversation/history` | none | HistoryResponse | in-memory |
| POST | `/api/v1/diagnosis/diagnose` | none | DiagnosisResponse | telemetry or symptom mode |
| POST | `/api/v1/knowledge/query` | none | KnowledgeResponse | `k` 1..10 |
| GET | `/health` | none | dict | health |

All endpoints are currently **unauthenticated** and synchronous (`def`, not
`async def`).

### 1.4 Configuration (actual `config.py`)

Pydantic v2 `BaseSettings`, `.env` loaded, `extra="ignore"`. Present keys:
`PROJECT_NAME`, `API_V1_STR`, `LOG_LEVEL`, `GEMINI_API_KEY`, `GEMINI_MODEL`,
`FIREBASE_CREDENTIALS_PATH`, `ENABLE_FALLBACK`, `DEFAULT_VEHICLE_MILEAGE`,
`CORS_ORIGINS`. **Missing:** `DATABASE_URL`, `JWT_SECRET_KEY`,
`JWT_ALGORITHM`, `ACCESS_TOKEN_EXPIRE_MINUTES`, `REFRESH_TOKEN_EXPIRE_*`.

### 1.5 Strengths (to preserve)

1. **AI layer is production-quality** — intent routing, RAG grounding,
   symptom+telemetry diagnosis modes, deterministic local fallback when no
   API key, graceful degradation. Reuse as-is.
2. **Pydantic v2 schemas** with field validation (`ge`/`le`, examples,
   descriptions) — clear API contract.
3. **Structured exception hierarchy** (`MechaException` → NOT_FOUND /
   UNAUTHORIZED / BAD_REQUEST / INFERENCE_FAILED) with a FastAPI exception
   handler giving consistent JSON errors.
4. **Structured logging** (`mecha_connect` logger) incl. latency and
   per-request module audit lines.
5. **Config management** via Pydantic settings (typed, `.env` driven).
6. **Pinned `requirements.txt`** with a *verified dev environment* freeze
   note — deterministic installs.
7. **The 39-table PostgreSQL schema is fully designed** in docs and `schema.sql`
   (frozen, mirrors the client UI). The DB blueprint is done; only the DAL is.
8. **Frozen API contract** (`docs/backend/API.md` ID schemes, latency/failure
   conventions) — backend must match so the Flutter UI doesn't change.
9. **CORS is already an explicit allow-list** (not All-redirect fix aligns
   with the architecture doc).

### 1.6 Weaknesses

1. **No database layer** — zero SQLAlchemy models, no engine, no migrations,
   no connection. The largest gap (P0).
2. **No authentication** — every route open; no sessions isolation, no RBAC.
3. **No repository pattern / DI** — services are free singletons with no
   injected dependencies or DB session.
4. **In-memory session** — `sessions` dict is not persisted, not scalable,
   lost on restart.
5. **No tests** — no `pytest`, no test tree, no CI gate on the backend.
6. **Sync model inference in request path** — blocking; no background worker.
7. **No rate limiting, security headers, or request-ID tracing** middleware.
8. **Model/hardcoded names** in service code (`chat_service.py:45`,
   `rag_service.py:44`) vs centralized config.
9. **Heavy import-time cost** — initialization of `ChatGoogleGenerativeAI`,
   `HuggingFaceEmbeddings`, FAISS happens at import; slow cold start, and
   `allow_dangerous_deserialization=True` on FAISS load should be re-verified.
10. **Exception handler default status** — unknown domain codes return HTTP
    500 even for non-server errors; `INFERENCE_FAILED` → 422 (debatable).

### 1.7 Missing components (Task 1)

Core infrastructure (P0): DB engine/session, SQLAlchemy models, Alembic
migrations, repositories, FastAPI Depends (DB + auth), auth (JWT+bcrypt+RBAC),
middleware (auth, rate-limit, security headers, request logging), tests.
Business surface (P0): Users, Vehicles (Auth, Profiles), Wallet, Mechanics,
Fuel, Marketplace, Orders/order_entries, AI conversation/diagnosis persistence.
Ops (P1): Dockerfile, docker-compose, CI for backend, seed data loader.

Backend completion guess: **~20%** (AI done; core business + data almost none).

---

## 2. Database Inspection (Task 4)

Source of truth: `docs/backend/database/schema.sql` (39 tables) and
`Database.md` / `data_model.md`. Conventions: UUID PKs, TIMESTAMPTZ,
NUMERIC(12,2) INR, NUMERIC(5,2) %, VARCHAR statuses with CHECK, soft-delete
via `deleted_at` where noted, `created_at`/`updated_at` on mutable tables.

### 2.1 Table groups & count

| Group | Tables |
|---|---|
| Identity/Profile | users, vehicles, addresses, notification_settings |
| Wallet/Rewards | wallet, wallet_transactions, reward_ledger |
| Marketplace | categories, brands, products, product_specifications, product_vehicle_types, product_compatibility, product_reviews, offers, coupons |
| Orders | orders, order_items, order_entries |
| Mechanic | mechanics, mechanic_skills, mechanic_languages, mechanic_working_hours, mechanic_services, mechanic_service_offered, mechanic_categories, mechanic_reviews, mechanic_bookings, booking_events, ratings |
| Fuel | fuel_stations, fuel_partners, fuel_orders, price_estimates, tracking_events, invoices |
| AI | conversations, chat_messages, diagnoses |

### 2.2 Well designed (strengths)

- **Frozen external-ID schemes** (`veh-`, `addr-`, `MKP-`, `FUEL-`, `ORD-`,
  `diag-`, `m-`, `ai-`, `txn-`, `rew-`, `rv-`, `svc_`, `station_`, `partner_`)
  map to `external_id`/`id` columns — directly mirrored to the client.
- **`order_entries`** as single source for the Orders tab — good unification.
- Track separability between entity tables vs **event tables**
  (`order_items`, `tracking_events`, `booking_events`, `ratings`), which keeps
  historical snapshots stable.
- Status stored as VARCHAR + CHECK bound to **frozen client enums** — avoids
  breaking UI on rename.
- Correct money type (`NUMERIC(12,2)`), explicit FK, and defaults.

### 2.3 Missing / ML weakness identified (Task 4 gaps)

- **Auth/security columns**: `users` is missing `is_active`, `is_verified`,
  `last_login_at`, `failed_login_attempts`/`lockout_at` (needed for login
  throttling + account status). `password_hash` exists.
- **`refresh_token` / session table** — not present; refile JWT refresh
  needs a store. Since infrastructure constrains **no Redis in prod**, plan
  will store refresh tokens (hashed) & rate-limit counters in PostgreSQL
  (e.g., a `refresh_tokens` table + `request_log`), not Redis.
- **Soft-delete not uniform** — `deleted_at` mentioned in conventions but not
  applied to all tables (e.g., `products`, `vehicles` IIRC) — decide once.
- **No `updated_by`/`created_by`** (audit) — only timestamps.
- **Foreign keys OK for (address→user, vehicles→user, wallet→user, orders→
  user, order_items→order, product FKs) but order_entries** references only
  `user_id` + a textual `type`/`source`, no FK to origin order — fine for the
  Orders-tab feed but can orphan. Consider source key optionally.
- **`fuel_stations.distance`/`eta`, `mechanics.distance`/`eta`** marked
  "computed at request time" but stored — recompute policy must be defined
  (client currently shows distance; derive from lat/lng, not stock).
- **Locations not GIS-ready** — `latitude`/`longitude` NUMERIC(9,6) with no
  PostGIS; fine for MVP radius queries; note if spatial queries needed later.
- **`diagnoses`** has no FK to `vehicles` (only `user_id`; `vehicle_name`
  snapshot) — acceptable snapshot semantics.

### 2.4 Migration plan (analysis only — NO execution)

There is **no Alembic today** → Sprint 2 must introduce Alembic:

**Recommended approach (do not run yet):**
1. Add `alembic`, `SQLAlchemy`, `asyncpg` to requirements (Phase 2 gate).
2. Scaffold `alembic.ini` + `env.py` wired to `app.core.database` URL.
3. Autogenerate **one initial `0001` migration** from the SQLAlchemy models
   mirroring `schema.sql` (39 tables). Because no DB exists yet, this first
   migration is a fresh full install (no destructive change).
4. Future schema changes → additive Alembic revisions only. **No destructive
   running** per task rules; destructive ops allowed only with explicit
   approval.
5. Seed = separate `scripts/seed_db.py` (idempotent), not a migration.

**(Migration plan detail in §5 of FUND_ROADMAP once approved.)**

---

## 3. API Layer Inspection (Task 5)

### 3.1 REST conventions
- Versioned (`/api/v1`), JSON body/response, status codes mostly correct.
- **Inconsistent endpoint naming**: `conversation/chat` + `conversation/session`
  + `conversation/history` mix nouns + verbs; recommend `POST /conversations`,
  `POST /conversations/{id}/messages`, `GET /conversations/{id}`.

### 3.2 Validation
- Request schemas validated via Pydantic (with ge/le bounds). Response models
  applied. **Gaps:** no min-length on `message`/`session_id`; no trim/UTF-8
  normalization; `session_id` not constrained to created format (accepts any
  string → metadata injection risk on `history`).

### 3.3 Error handling
- Global `MechaException` handler + generic 500 handler. **Deficiencies:**
  - `history` raises raw `HTTPException` 404 instead of domain exception.
  - No `RequestValidationError` customization → default 422 shape differs
    from domain error shape (inconsistent client parsing).
  - `INFERENCE_FAILED` maps to 422 (post) — likely should be 502/503.

### 3.4 Response models
- Well-typed for the 3 AI features. Missing: envelope/conventions for list
  pagination, timestamps consistent, no `details` usage on success.

### 3.5 Rate limiting
- **None** — should be an in-memory (per process) sliding-window on
  auth + AI endpoints (e.g., 10/min auth, 30/min AI) with configurable keys;
  long-term postgres/redis-backed when distributed.

---

## 4. Auth & Security Inspection (Task 6 / Task 7)

### 4.1 Current security posture
- **JWT:** none. **Password storage:** none (no registration/login server).
- **Env vars:** loaded via pydantic-settings; `.env` gitignored (verified
  `git check-ignore` earlier in the freeze). `.env.example` is placeholder-safe.
- **CORS:** explicit allow-list via `settings.CORS_ORIGINS`
  (`http://localhost:3000`, `127.0.0.1:3000`) with `allow_credentials=True`
  — correctly **not star**. Frontend only needs update when moving off localhost
  (target origins in prod).
- **Input validation:** Pydantic bounds present at schema level.
- **Logging:** structured; but no per-request access log, no sanitizer
  for PII in logs.
- **API keys:** Gemini key masked at startup; never written to logs.

### 4.2 Gaps to fix in foundation
1. `python-jose` + `passlib[bcrypt]` for JWT & hash (add to requirements).
2. `security.py` (password hash/verify, create/verify access+refresh JWT).
3. RBAC: `customer`, `mechanic`, `admin` roles (column on `users`).
4. `Depends(get_current_user)` protected routes.
5. Rate limiting (in-memory) on auth (10/min) + AI endpoints.
6. Security headers middleware (nosniff, frame-denial, XSS, HSTS,CSP).
7. Global request/access logging middleware (no PII leakage).
8. A centralized `[ValidationError]` handler for uniform errors.

**No real secret in the repo** (confirmed); `.env` not tracked.

---

## 5. AI integration inspection (Task 6)

| Piece | File | Prod-ready? | Notes |
|---|---|---|---|
| Intent classifier | chat_service `_classify_intent` | Partially | rule-based keyword; returns to 
| RAG retrieval | rag_service | ✅ (offline pipeline) | FAISS + sentence-transformers |
| Gemini chat | chat_service / rag_service | ✅ with fallback | `gemini-2.5-flash` |
| FAISS build | `ai/build_rag_index.py` | ✅ | chunk 500/50, category metadata |
| XGBoost classifier | `ai/models/train.py` | ✅ | champion pick RF vs XGB |
| Metadata | `ai/metadata.py` | ✅ | cost/time/safety |
| Knowledge base content | `ai/knowledge_base/*` | partial | only manuals/faq/obd/symbols seeded; **categories exist but many empty** |

**What's production-ready:** the whole offline inference path (RAG retrieval /
XGBoost prediction / local fallback) works without a key and is solid.

**What remains to be built (for foundation, connected to DB):**
- **Persist AI state**: `conversations`, `chat_messages` (JSONB `response`)
  and `diagnoses` tables are defined but unused → chat history/diagnosis must
  read/write these (Task foundation: repositories + seed).
- **Conversation management endpoints** (list/persist) beyond ephemeral
  in-memory session.
- **Diagnoses & historical view** endpoints (client Profile lists diagnoses).
- **Async/streaming**: move Gemini invoke off the request thread; support
  streaming for chat UX.
- **Hardened init**: extract model names to config; verify `load_local`
  `allow_dangerous_deserialization` policy.
- **Prompt architecture**: single template source, add retry/timeouts,
  token budgeting, and structured output for `Diagnosis`.

---

## 6. SECURITY watch list (Task 7 recap)

All matches the docs (Architecture/Authentication). No secrets in tree;
`.env` ignored; keys masked. Once auth is added: store refresh tokens in a
Postgres table (not Redis) per infra constraint; enforce bcrypt cost; lockout
on failed login; never log raw token/secret; keep `CORS_ORIGINS` as allow-list
in prod.

---

## 7. Backend maturity summary

| Pillar | Status |
|---|---|
| AI (chat/rag/diagnosis) | ✅ ~ready (offline-capable) |
| Pydantic API schemas | ✅ |
| Ops-auth (config, logging, errors, CORS) | ✅ partial (errors/cors fine) |
| Core business APIs | ❌ missing |
| Persistence (SQLAlchemy + migrations) | **missing** |
| Auth (JWT/bcrypt/RBAC) | **missing** |
| Repos / DI / middleware (rate-limit, headers) | **missing** |
| Tests | **missing** |
| Deploy (Docker/CI) | **missing** |
| **Overall backend maturity** | **~20%** |

*Detailed implementation roadmap, estimated effort, and final recommendation
are in `SPRINT_2_ROADMAP.md`.*