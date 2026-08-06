# Sprint 2 Backend Blueprint — Mecha Connect

> **Sprint 2 Phase 1: Backend Audit & Architecture Freeze · 2026-08-05**
> Professional engineering report based on actual repository inspection.

## 1. Executive Summary

The Mecha Connect backend scaffold exists with **AI services fully implemented** but **core business infrastructure completely missing**. The existing AI code (ChatService, DiagnosisService, RAGService) is production-quality and should be reused as-is. Sprint 2 must build the foundation: database, authentication, repositories, and all business APIs.

**Backend Completion: ~20%** (AI services done, everything else missing)

---

## 2. Phase 1 — Repository Analysis

### 2.1 Existing Folder Structure

```
backend/
├── .env                          # Environment variables
├── requirements.txt              # Python dependencies
├── ai/
│   ├── build_rag_index.py        # RAG index builder script
│   ├── metadata.py               # Diagnosis metadata (cost, time, advice)
│   ├── data/
│   │   ├── generate_data.py      # Telemetry data generator
│   │   └── vehicle_telemetry.csv # Training dataset
│   ├── knowledge_base/
│   │   ├── dashboard_symbols/    # Knowledge base category
│   │   ├── faiss_index/          # Built FAISS vector index
│   │   ├── faq/                  # Knowledge base category
│   │   ├── manuals/              # Knowledge base category
│   │   └── obd_codes/            # Knowledge base category
│   └── models/
│       ├── fault_classifier.joblib # Trained XGBoost model
│       └── train.py              # Model training script
├── app/
│   ├── main.py                   # FastAPI app entry point
│   ├── api/
│   │   ├── router.py             # API router (3 endpoints)
│   │   └── v1/
│   │       ├── conversation.py   # Chat endpoints
│   │       ├── diagnosis.py      # Diagnosis endpoint
│   │       └── knowledge.py      # RAG query endpoint
│   ├── core/
│   │   ├── config.py             # Pydantic settings
│   │   ├── exceptions.py         # Exception hierarchy
│   │   └── logging.py            # Logging setup
│   ├── schemas/
│   │   ├── chat.py               # Chat Pydantic schemas
│   │   ├── diagnosis.py          # Diagnosis Pydantic schemas
│   │   └── knowledge.py          # Knowledge Pydantic schemas
│   └── services/
│       ├── chat_service.py       # ChatService (Gemini)
│       ├── diagnosis_service.py  # DiagnosisService (XGBoost)
│       └── rag_service.py        # RAGService (FAISS + Gemini)
```

### 2.2 Existing APIs

| Method | Path | Endpoint | Description |
|---|---|---|---|
| POST | `/api/v1/conversation/chat` | Chat | AI conversation with intent routing |
| POST | `/api/v1/conversation/session` | Create Session | Generate UUID session |
| GET | `/api/v1/conversation/history` | Get History | Retrieve session messages |
| POST | `/api/v1/diagnosis/diagnose` | Diagnose | Vehicle fault prediction |
| POST | `/api/v1/knowledge/query` | Knowledge Query | RAG-powered Q&A |
| GET | `/health` | Health Check | Server health |

**Total: 6 endpoints (3 AI + 1 health + 2 session management)**

### 2.3 Existing AI Modules

| Module | File | Status | Description |
|---|---|---|---|
| ChatService | `app/services/chat_service.py` | ✅ Complete | Intent classification, Gemini 2.5-flash, fallback mode |
| DiagnosisService | `app/services/diagnosis_service.py` | ✅ Complete | XGBoost model, telemetry + symptom modes |
| RAGService | `app/services/rag_service.py` | ✅ Complete | FAISS, HuggingFace embeddings, Gemini |
| RAG Index Builder | `ai/build_rag_index.py` | ✅ Complete | Builds FAISS index from knowledge base |
| Model Training | `ai/models/train.py` | ✅ Complete | XGBoost training script |
| Data Generator | `ai/data/generate_data.py` | ✅ Complete | Telemetry CSV generator |
| Metadata | `ai/metadata.py` | ✅ Complete | Fault cost/time/advice lookup |

### 2.4 Existing Services

| Service | File | Status | Description |
|---|---|---|---|
| ChatService | `app/services/chat_service.py` | ✅ Complete | Conversation orchestration |
| DiagnosisService | `app/services/diagnosis_service.py` | ✅ Complete | Vehicle fault prediction |
| RAGService | `app/services/rag_service.py` | ✅ Complete | Knowledge base Q&A |

### 2.5 Existing Schemas

| Schema | File | Status | Description |
|---|---|---|---|
| ChatRequest | `app/schemas/chat.py` | ✅ Complete | message, session_id |
| ChatResponse | `app/schemas/chat.py` | ✅ Complete | response, intent, latency |
| SessionResponse | `app/schemas/chat.py` | ✅ Complete | session_id |
| HistoryResponse | `app/schemas/chat.py` | ✅ Complete | session_id, history |
| DiagnosisInput | `app/schemas/diagnosis.py` | ✅ Complete | Telemetry + symptoms |
| DiagnosisResponse | `app/schemas/diagnosis.py` | ✅ Complete | Fault, confidence, cost |
| KnowledgeQuery | `app/schemas/knowledge.py` | ✅ Complete | query, k |
| KnowledgeResponse | `app/schemas/knowledge.py` | ✅ Complete | answer, sources |

### 2.6 Existing Models

**No SQLAlchemy models exist.** The backend has no database layer.

### 2.7 Existing Dependencies

```txt
fastapi>=0.110.0
uvicorn>=0.28.0
pydantic>=2.6.4
pydantic-settings>=2.2.1
pandas>=2.2.1
numpy>=1.26.4
scikit-learn>=1.4.1.post1
xgboost>=2.0.3
joblib>=1.3.2
python-multipart>=0.0.9
python-dotenv>=1.0.1
requests>=2.31.0
firebase-admin>=6.5.0
langchain>=0.1.11
langchain-community>=0.0.25
langchain-google-genai>=1.0.1
faiss-cpu>=1.8.0
sentence-transformers>=2.5.1
pypdf>=4.1.0
python-docx>=1.1.0
```

**Missing critical dependencies:**
- SQLAlchemy (database ORM)
- Alembic (migrations)
- asyncpg (PostgreSQL driver)
- python-jose (JWT)
- passlib[bcrypt] (password hashing)
- pytest (testing)

### 2.8 Existing Configuration

```python
# app/core/config.py
class Settings(BaseSettings):
    PROJECT_NAME: str = "Mecha Connect Backend"
    API_V1_STR: str = "/api/v1"
    LOG_LEVEL: str = "INFO"
    GEMINI_API_KEY: Optional[str] = None
    FIREBASE_CREDENTIALS_PATH: Optional[str] = None
    ENABLE_FALLBACK: bool = False
```

**Missing configuration:**
- DATABASE_URL
- JWT_SECRET_KEY
- JWT_ALGORITHM
- ACCESS_TOKEN_EXPIRE_MINUTES
- REDIS_URL (not needed per constraints)

### 2.9 Existing Reusable Components

| Component | Reusability | Notes |
|---|---|---|
| ChatService | ✅ High | Production-ready, reuse as-is |
| DiagnosisService | ✅ High | Production-ready, reuse as-is |
| RAGService | ✅ High | Production-ready, reuse as-is |
| Exception hierarchy | ✅ High | MechaException, EntityNotFound, etc. |
| Logging setup | ✅ High | Structured logging |
| Configuration | ✅ High | Pydantic settings |
| Pydantic schemas | ✅ High | Well-defined request/response models |
| AI assets | ✅ High | Trained model, FAISS index, knowledge base |

### 2.10 Missing Components

| Category | Missing | Severity |
|---|---|---|
| **Authentication** | JWT, bcrypt, auth middleware | P0 |
| **Database** | SQLAlchemy models, Alembic migrations | P0 |
| **Repository Pattern** | Repository layer | P0 |
| **Dependency Injection** | Auth dependencies, DB session | P0 |
| **Middleware** | Auth middleware, rate limiting | P0 |
| **Tests** | pytest framework, test files | P0 |
| **Business APIs** | Users, Vehicles, Mechanics, Orders, Fuel, Marketplace | P0 |
| **Dockerfile** | Container configuration | P1 |
| **CI/CD** | GitHub Actions | P1 |

---

## 3. Phase 2 — Architecture Review

### 3.1 Current Architecture

```
Flutter App
    │
    ▼
FastAPI API Gateway
    │
 ┌──┼──────────┐
 │  │          │
 ▼  ▼          ▼
Auth  Business   AI Engine
     Services

 │        │         │
 ▼        ▼         ▼
Repositories     RAG Engine

 │        │         │
 └────────┼─────────┘
          ▼
     PostgreSQL
```

### 3.2 Architecture Assessment

**Strengths:**
- ✅ Clean separation of AI services
- ✅ Well-structured exception hierarchy
- ✅ Pydantic v2 schemas with validation
- ✅ Structured logging
- ✅ Configuration management
- ✅ Modular service design

**Weaknesses:**
- ❌ No database layer
- ❌ No authentication
- ❌ No repository pattern
- ❌ No dependency injection
- ❌ No tests
- ❌ CORS allows all origins
- ❌ No rate limiting
- ❌ No security headers

### 3.3 Recommendations

#### 3.3.1 Keep as Modular Monolith

The backend should remain a **modular monolith** — not microservices. This is appropriate for an MVP with a small team.

**Reasoning:**
- Single deployable unit
- Shared database
- No network latency between services
- Simpler CI/CD
- Easier debugging

#### 3.3.2 Reuse Existing AI Services

The three AI services are production-quality and should be reused as-is. They already follow good patterns:
- Singleton instances
- Proper error handling
- Structured logging
- Fallback mechanisms

#### 3.3.3 Add Database Layer

Add SQLAlchemy 2.0 async engine with:
- Async session management
- Repository pattern
- Alembic migrations
- UUID primary keys
- Soft delete support
- Audit fields (created_at, updated_at)

#### 3.3.4 Add Authentication

Add JWT-based authentication with:
- Access tokens (15 min expiry)
- Refresh tokens (7 day expiry)
- bcrypt password hashing
- Role-based access control (customer, mechanic, admin)

#### 3.3.5 Fix CORS

Restrict CORS to known origins instead of `["*"]`.

#### 3.3.6 Add Security Headers

Add security headers middleware.

#### 3.3.7 Add Rate Limiting

Use in-memory rate limiting (no Redis per constraints).

---

## 4. Phase 3 — Sprint 2 Blueprint

### 4.1 Implementation Roadmap

```
Sprint 2

Phase 1: Backend Audit & Architecture Freeze  ← CURRENT
    ↓
Phase 2: Development Environment
    ↓
Phase 3: Database Foundation
    ↓
Phase 4: Authentication System
    ↓
Phase 5: Core Business APIs
    ↓
Phase 6: AI Integration
    ↓
Phase 7: Testing & Quality
    ↓
Phase 8: Production Preparation
```

### 4.2 Phase 2 — Development Environment

**Goal:** Set up development environment with all dependencies.

**Files to modify:**
- `requirements.txt` — Add missing dependencies
- `backend/.env` — Add database and JWT config

**Files to create:**
- `requirements-dev.txt` — Development dependencies
- `backend/app/core/database.py` — SQLAlchemy async engine
- `backend/alembic.ini` — Alembic configuration
- `backend/alembic/env.py` — Alembic environment

**Dependencies:**
- SQLAlchemy 2.0
- Alembic
- asyncpg
- python-jose
- passlib[bcrypt]
- pytest
- pytest-asyncio

**Risks:**
- Dependency conflicts with existing packages
- Python version compatibility

**Estimated effort:** 4-6 hours

### 4.3 Phase 3 — Database Foundation

**Goal:** Create database models and migrations.

**Files to create:**
- `backend/app/models/__init__.py`
- `backend/app/models/user.py`
- `backend/app/models/vehicle.py`
- `backend/app/models/mechanic.py`
- `backend/app/models/order.py`
- `backend/app/models/product.py`
- `backend/app/models/address.py`
- `backend/app/models/payment.py`
- `backend/app/models/conversation.py`
- `backend/alembic/versions/` — Migration files

**Dependencies:**
- Phase 2 complete

**Risks:**
- Schema design may need iteration
- Migration conflicts

**Estimated effort:** 8-12 hours

### 4.4 Phase 4 — Authentication System

**Goal:** Implement JWT-based authentication.

**Files to create:**
- `backend/app/core/security.py` — JWT, password hashing
- `backend/app/api/v1/auth.py` — Auth endpoints
- `backend/app/dependencies/auth.py` — Auth dependencies
- `backend/app/middleware/auth.py` — Auth middleware

**Files to modify:**
- `backend/app/core/config.py` — Add JWT settings
- `backend/app/main.py` — Add auth middleware

**Dependencies:**
- Phase 3 complete

**Risks:**
- JWT security best practices
- Token refresh logic

**Estimated effort:** 8-12 hours

### 4.5 Phase 5 — Core Business APIs

**Goal:** Implement all business APIs.

**Files to create:**
- `backend/app/api/v1/users.py`
- `backend/app/api/v1/vehicles.py`
- `backend/app/api/v1/mechanics.py`
- `backend/app/api/v1/fuel.py`
- `backend/app/api/v1/marketplace.py`
- `backend/app/api/v1/orders.py`
- `backend/app/repositories/` — Repository classes
- `backend/app/services/` — Business logic services

**Files to modify:**
- `backend/app/api/router.py` — Add new routers

**Dependencies:**
- Phase 4 complete

**Risks:**
- API design may need iteration
- Integration with frontend mock data

**Estimated effort:** 20-30 hours

### 4.6 Phase 6 — AI Integration

**Goal:** Connect existing AI services to database.

**Files to modify:**
- `backend/app/services/chat_service.py` — Add DB persistence
- `backend/app/services/diagnosis_service.py` — Add user context
- `backend/app/services/rag_service.py` — Add user context

**Files to create:**
- `backend/app/models/conversation.py` — Conversation history
- `backend/app/repositories/conversation.py` — Conversation repository

**Dependencies:**
- Phase 5 complete

**Risks:**
- AI service refactoring may break existing functionality
- Database performance with AI queries

**Estimated effort:** 6-8 hours

### 4.7 Phase 7 — Testing & Quality

**Goal:** Add comprehensive test coverage.

**Files to create:**
- `backend/tests/conftest.py`
- `backend/tests/unit/` — Unit tests
- `backend/tests/integration/` — Integration tests
- `backend/tests/api/` — API tests

**Dependencies:**
- All phases complete

**Risks:**
- Test coverage may be incomplete
- Test data management

**Estimated effort:** 12-16 hours

### 4.8 Phase 8 — Production Preparation

**Goal:** Prepare for production deployment.

**Files to create:**
- `backend/Dockerfile`
- `backend/docker-compose.yml`
- `.github/workflows/backend.yml` — CI/CD
- `backend/scripts/` — Utility scripts

**Dependencies:**
- Phase 7 complete

**Risks:**
- Docker configuration
- CI/CD pipeline setup

**Estimated effort:** 6-8 hours

---

## 5. Reuse Opportunities

| Component | Reuse Strategy | Effort Saved |
|---|---|---|
| ChatService | Reuse as-is | 8 hours |
| DiagnosisService | Reuse as-is | 6 hours |
| RAGService | Reuse as-is | 6 hours |
| Exception hierarchy | Reuse as-is | 2 hours |
| Logging setup | Reuse as-is | 1 hour |
| Configuration | Extend, don't replace | 1 hour |
| Pydantic schemas | Extend, don't replace | 2 hours |
| AI assets | Reuse as-is | 4 hours |
| **Total** | | **30 hours saved** |

---

## 6. Technical Debt

| Issue | Severity | Location | Fix |
|---|---|---|---|
| CORS allows all origins | P0 | `main.py:34-40` | Restrict to known origins |
| No auth middleware | P0 | `main.py` | Add JWT middleware |
| No database connection | P0 | `main.py` | Add SQLAlchemy |
| No repository pattern | P0 | `app/` | Create repositories/ |
| No tests | P0 | `backend/` | Add pytest |
| No migrations | P0 | `backend/` | Add Alembic |
| No Dockerfile | P1 | `backend/` | Add Docker |
| Duplicate comment | P3 | `rag_service.py:102` | Remove |
| Hardcoded model names | P2 | `chat_service.py:46`, `rag_service.py:44` | Move to config |
| No rate limiting | P1 | `main.py` | Add in-memory rate limiting |
| No security headers | P1 | `main.py` | Add security headers |
| No request logging | P1 | `main.py` | Add request logging |

---

## 7. Sprint 2 Implementation Order

| Phase | Goal | Effort | Dependencies |
|---|---|---|---|
| Phase 2 | Development Environment | 4-6h | None |
| Phase 3 | Database Foundation | 8-12h | Phase 2 |
| Phase 4 | Authentication | 8-12h | Phase 3 |
| Phase 5 | Core Business APIs | 20-30h | Phase 4 |
| Phase 6 | AI Integration | 6-8h | Phase 5 |
| Phase 7 | Testing | 12-16h | Phase 6 |
| Phase 8 | Production Prep | 6-8h | Phase 7 |
| **Total** | | **64-92h** | |

---

## 8. Risks

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Dependency conflicts | Medium | High | Pin versions, test early |
| Schema design iteration | High | Medium | Design review before implementation |
| AI service refactoring | Medium | High | Add tests before refactoring |
| Database performance | Medium | High | Add indexes, query optimization |
| JWT security | Low | High | Follow best practices, use established library |
| Test coverage gaps | High | Medium | Set minimum coverage threshold |
| Docker deployment | Medium | Medium | Test locally before deploying |

---

## 9. Recommendations

### 9.1 Immediate Actions

1. **Add missing dependencies** to `requirements.txt`
2. **Fix CORS** in `main.py`
3. **Add database layer** (SQLAlchemy + Alembic)
4. **Add authentication** (JWT + bcrypt)
5. **Add tests** (pytest framework)

### 9.2 Architecture Decisions

1. **Async SQLAlchemy** — Use async engine for performance
2. **Repository pattern** — Abstract database access
3. **Dependency injection** — FastAPI Depends for DI
4. **UUID primary keys** — As per database blueprint
5. **Soft deletes** — As per database blueprint
6. **Audit fields** — created_at, updated_at on all tables
7. **In-memory rate limiting** — No Redis per constraints
8. **FastAPI BackgroundTasks** — For background work, no Celery

### 9.3 Quality Standards

1. **80% test coverage** minimum
2. **Pydantic validation** on all endpoints
3. **Structured logging** on all services
4. **Error handling** with proper HTTP status codes
5. **API documentation** via OpenAPI/Swagger
6. **Security headers** on all responses

---

## 10. Conclusion

The backend scaffold has a **strong AI foundation** but is **missing all core infrastructure**. The existing AI services are production-quality and should be reused as-is. Sprint 2 must focus on building the foundation: database, authentication, repositories, and business APIs.

**Estimated total effort: 64-92 hours (2-3 weeks)**

**Status: Architecture FROZEN. Awaiting approval to begin Phase 2.**
</tool_call>