# Backend Audit — Mecha Connect

> **Phase 0 · Complete Engineering Audit · 2026-08-05**
> Scope: FastAPI scaffold, AI pipeline, FAISS, Gemini, XGBoost, environment, dependencies, Sprint 2 readiness.

## 1. Current State

### 1.1 Backend structure
```
backend/
├── .env                    # GEMINI_API_KEY, FIREBASE_PROJECT_ID (gitignored)
├── requirements.txt         # 20 dependencies
├── ai/
│   ├── build_rag_index.py  # FAISS index builder
│   ├── metadata.py         # Diagnosis metadata (costs, safety advice)
│   ├── data/
│   │   ├── generate_data.py # Synthetic telemetry generator (1200 rows)
│   │   └── vehicle_telemetry.csv
│   ├── knowledge_base/
│   │   ├── faq/support_faq.txt
│   │   ├── manuals/bike_manual.txt, car_manual.txt
│   │   ├── obd_codes/obd_guide.txt
│   │   ├── dashboard_symbols/symbols_guide.txt
│   │   └── faiss_index/ (index.faiss, index.pkl)
│   └── models/
│       ├── train.py        # XGBoost + RandomForest training
│       └── fault_classifier.joblib
└── app/
    ├── main.py            # FastAPI app + CORS + exception handlers
    ├── api/
    │   ├── router.py     # Mounts diagnosis/knowledge/conversation
    │   └── v1/
    │       ├── diagnosis.py    # POST /diagnosis/diagnose
    │       ├── knowledge.py    # POST /knowledge/query
    │       └── conversation.py # POST /conversation/chat, /session, /history
    ├── core/
    │   ├── config.py     # Pydantic settings
    │   ├── exceptions.py # MechaException hierarchy
    │   └── logging.py   # StreamHandler logging
    ├── schemas/
    │   ├── chat.py      # ChatRequest/Response, SessionResponse, HistoryResponse
    │   ├── diagnosis.py # DiagnosisInput/Response
    │   └── knowledge.py # KnowledgeQuery/Response, SourceDoc
    └── services/
        ├── chat_service.py      # ChatService (intent classification + orchestration)
        ├── diagnosis_service.py # DiagnosisService (XGBoost + rule-based)
        └── rag_service.py      # RAGService (FAISS + Gemini)
```

### 1.2 Endpoints (scaffolded)
| Method | Path | Service | Status |
|---|---|---|---|
| POST | `/api/v1/diagnosis/diagnose` | DiagnosisService | Scaffolded |
| POST | `/api/v1/knowledge/query` | RAGService | Scaffolded |
| POST | `/api/v1/conversation/chat` | ChatService | Scaffolded |
| POST | `/api/v1/conversation/session` | ChatService | Scaffolded |
| GET | `/api/v1/conversation/history` | ChatService | Scaffolded |
| GET | `/health` | — | Scaffolded |

## 2. Strengths

| # | Finding | Detail |
|---|---|---|
| S1 | **Clean layered structure** | `api/` (routes) → `core/` (config/exceptions/logging) → `schemas/` (Pydantic) → `services/` (business logic) |
| S2 | **Pydantic v2 schemas** | All request/response models use `BaseModel` with `Field` descriptions + validation constraints (`ge`/`le`) |
| S3 | **Domain exception hierarchy** | `MechaException` base + `EntityNotFoundException`, `UnauthorizedException`, `InvalidInputException`, `InferenceException` |
| S4 | **Global exception handlers** | `main.py` maps MechaException → HTTP status; generic handler catches all |
| S5 | **Structured logging** | `logging.py` with configurable level; services log intent, latency, module usage |
| S6 | **AI pipeline complete** | XGBoost classifier + FAISS RAG + Gemini LLM + fallback responses |
| S7 | **Fallback mode** | `ENABLE_FALLBACK` flag — when Gemini key missing, returns local fallback responses |
| S8 | **Model training pipeline** | `train.py` trains RF + XGBoost, compares F1, selects champion, serializes joblib |
| S9 | **Synthetic data generator** | `generate_data.py` creates 1200-row telemetry CSV with 5 fault classes |
| S10 | **Session memory** | `SessionMemory` caps at 12 messages; session IDs are UUID-based |
| S11 | **API key masking** | `main.py` masks GEMINI_API_KEY in startup logs |

## 3. Weaknesses

| # | Finding | Severity | Detail |
|---|---|---|---|
| W1 | **No backend tests** | P0 | **Zero backend tests exist.** No `test/` or `tests/` in `backend/`. The FastAPI endpoints, services, and AI pipeline are completely untested. |
| W2 | **No database integration** | P1 | No SQLAlchemy/asyncpg/PostgreSQL connection. All services use in-memory dicts (`self.sessions`). Sprint 2 must add the DB layer. |
| W3 | **No auth** | P1 | No JWT, Firebase Auth, or any authentication middleware. `UnauthorizedException` exists but is never raised. |
| W4 | **No Dockerfile / docker-compose** | P1 | No containerization. No `Dockerfile`, no `docker-compose.yml`. Deployment is manual. |
| W5 | **No CI/CD** | P1 | No `.github/workflows/`. No automated backend test/lint pipeline. |
| W6 | **`SessionMemory` is in-memory only** | P1 | Sessions live in a dict — lost on restart. Sprint 2 needs Redis/PostgreSQL persistence. |
| W7 | **`ChatService` hardcodes `mileage=80000`** | P2 | `_orchestrate_diagnosis` hardcodes `mileage=80000` — not from user input. |
| W8 | **`rag_service.py` has duplicate comment** | P3 | Line 101-102 has a duplicated `# Execute inference` comment. Minor. |
| W9 | **`requirements.txt` has no pinned versions** | P2 | Uses `>=` ranges, not `==` pins. Non-reproducible builds. |
| W10 | **`build_rag_index.py` creates folders not in repo** | P3 | Creates `cars/`, `bikes/`, `maintenance/`, `repair_guides/` folders that don't exist in `knowledge_base/`. |
| W11 | **`fault_classifier.joblib` is a binary blob** | P2 | The XGBoost model is a committed binary. No model versioning, no MLflow, no experiment tracking. |
| W12 | **`vehicle_telemetry.csv` is synthetic** | P2 | Data is generated, not real. No real-world validation. |
| W13 | **`ENABLE_FALLBACK=False`** | P2 | When Gemini key is missing, chat/RAG raise `InferenceException`. Fallback is opt-in. Acceptable for scaffold. |
| W14 | **No rate limiting** | P2 | No rate limiting on any endpoint. DoS risk in production. |
| W15 | **No pagination** | P3 | No pagination on history/list endpoints. |

## 4. Backend Readiness for Sprint 2

| Sprint 2 Requirement | Status | Gap |
|---|---|---|
| FastAPI scaffold | ✅ | Core structure exists |
| PostgreSQL | ❌ | No DB layer |
| JWT/Firebase Auth | ❌ | No auth |
| Redis | ❌ | No Redis |
| Gemini | ✅ | ChatGoogleGenerativeAI wired |
| FAISS | ✅ | FAISS index built |
| XGBoost | ✅ | fault_classifier.joblib |
| Real APIs | ❌ | All mock |
| Repository migration | ❌ | Not started |
| Tests | ❌ | Zero backend tests |
| CI/CD | ❌ | No pipeline |
| Docker | ❌ | No Dockerfile |

## 5. Risks

| # | Risk | Severity | Mitigation |
|---|---|---|---|
| R1 | Zero backend tests | P0 | Add pytest + httpx TestClient tests in Sprint 2 |
| R2 | No auth | P1 | Add Firebase Auth + JWT in Sprint 2 |
| R3 | No DB | P1 | Add SQLAlchemy + asyncpg + Alembic in Sprint 2 |
| R4 | No CI/CD | P1 | Add GitHub Actions in Sprint 2 |
| R5 | In-memory sessions | P1 | Redis in Sprint 2 |
| R6 | Unpinned deps | P2 | Pin versions in requirements.txt |

## 6. Technical Debt

| # | Debt | Priority | Effort |
|---|---|---|---|
| TD1 | No backend tests | P0 | 1 day |
| TD2 | No DB layer | P1 | 2 days |
| TD3 | No auth | P1 | 1 day |
| TD4 | No CI/CD | P1 | 1 day |
| TD5 | Unpinned deps | P2 | 30 min |
| TD6 | No Dockerfile | P1 | 2 hr |

## 7. Recommendations

1. **P0 — Add backend tests** (highest priority): pytest + httpx TestClient for all 3 services + 5 endpoints.
2. **P1 — Add DB layer**: SQLAlchemy + asyncpg + Alembic migrations in Sprint 2.
3. **P1 — Add auth**: Firebase Auth + JWT middleware.
4. **P1 — Add Dockerfile + docker-compose.yml**.
5. **P1 — Add CI/CD** (`.github/workflows/ci.yml`).
6. **P2 — Pin dependencies** in `requirements.txt`.
7. **P2 — Add model versioning** for `fault_classifier.joblib`.
8. **P2 — Add rate limiting** (slowapi).

## 8. Priority Summary

| Priority | Count | Items |
|---|---|---|
| P0 | 1 | W1 (no backend tests) |
| P1 | 5 | W2, W3, W4, W5, W6, TD2, TD3, TD4, TD6 |
| P2 | 6 | W7, W9, W11, W12, W13, W14, TD5 |
| P3 | 2 | W8, W10, W15 |