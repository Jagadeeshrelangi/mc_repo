# Mecha Connect — Head-to-Toe Application Audit Report

**Date**: 2026-08-19  
**Auditor**: Antigravity AI Engineering Team  
**Evaluation Scope**: Full-Stack Monorepo Audit (Frontend Flutter, Backend FastAPI, AI/ML Services, Database Models, Security, Performance, UX, and Contract Alignment)

---

# 1. Environment

- **Host OS**: Windows 11 (AMD64)
- **Backend Stack**: Python 3.13.5, FastAPI 0.115.0+, SQLAlchemy 2.0.38, Uvicorn, Alembic, XGBoost, Scikit-learn, LangChain, FAISS (CPU), sentence-transformers (`all-MiniLM-L6-v2`), Google Generative AI (Gemini Flash/Pro).
- **Frontend Stack**: Flutter 3.29.2 (channel stable, Dart 3.7.2, DevTools 2.42.3), Provider state management, Shared Preferences.
- **Database Status**: Local/Production PostgreSQL unavailable (`DATABASE_URL` absent from `.env`).

---

# 2. Backend Runtime

- **Status**: **IMPLEMENTED AND WORKING (In-Memory / Fake Session Isolation)**
- **Startup & Initialization**:
  - FastAPI boots cleanly and registers all 28 REST routes under `/api/v1` and `/health`.
  - Logging subsystem initializes without error.
  - XGBoost fault classifier model (`ai/models/fault_classifier.joblib`) loads successfully during startup.
  - HuggingFace sentence transformer embeddings and local FAISS vector store initialize cleanly on CPU.
  - Gemini Pro RAG connector initializes cleanly when `GEMINI_API_KEY` is present.
- **Test Suite**:
  - `python -m pytest ...` executed across 5 test suites: **150/150 passed** in 22.09s.
  - Bytecode compilation (`python -m compileall app tests -q`): **0 errors**.

---

# 3. Frontend Runtime

- **Status**: **IMPLEMENTED AND WORKING (Offline Mock Engine)**
- **Flutter Analyzer**: `flutter analyze` completed with **0 issues found** across all screens and widgets.
- **Flutter Test Suite**: `flutter test` completed with **162/162 passed** across unit, widget, and screen tests.
- **UI State**: The Flutter application is fully navigable using Sprint 1 mock in-memory data repositories.

---

# 4. Authentication Flow

- **Backend (Real JWT Auth)**:
  - Endpoints: `/api/v1/auth/register`, `/api/v1/auth/login`, `/api/v1/auth/refresh`, `/api/v1/auth/me`, `/api/v1/auth/logout`.
  - Uses `bcrypt` password hashing, short-lived JWT access tokens (15m), and tracked refresh tokens (7d).
  - Multi-tenancy guard: `get_current_user` dependency enforces token validity, active account checks, and extracts `user.id`.
- **Frontend (Mock Auth)**:
  - Frontend `features/auth/` currently uses a mock in-memory provider and repository.
  - State transitions (Logged out → Splash → Phone/Email Login → Home) work smoothly inside the Flutter app.
- **Integration Status**: **DISCONNECTED (P0 Blocker)**. The Flutter app has not yet been connected to the backend `/api/v1/auth` endpoints.

---

# 5. AI Flow

- **Backend Conversational AI**:
  - Endpoints: `POST /api/v1/conversation/chat`, `POST /api/v1/conversation/session`, `GET /api/v1/conversation/history`.
  - Backed by Gemini Pro with fallback logic. Conversations and chat messages are bound to `user.id` with a 12-turn prompt cap and session ownership verification.
- **Frontend AI Board**:
  - The Flutter UI features an AI assistant chatboard with structured UI blocks (`AiBlockType.warning`, `bulletList`, `checklist`, `costEstimate`, `recommendation`).
- **Integration Mismatch**:
  - Backend `/api/v1/conversation/chat` returns a flat string `reply` and `disclaimer`.
  - Frontend `AiRepository` expects structured `AiResponse` with nested blocks and quick-action buttons (`openDiagnosis`, `bookMechanic`, `searchParts`).
  - Current backend response does not produce structured blocks for the frontend UI.

---

# 6. Diagnosis Flow

- **Backend Inference & Persistence**:
  - Endpoint: `POST /api/v1/diagnosis/diagnose`.
  - Telemetry Mode: Uses XGBoost fault classifier on sensor parameters (engine temp, vibration, battery voltage, oil pressure, mileage, OBD trouble codes).
  - Symptom Mode: Uses rule-based mapping on natural language symptom strings and vehicle make.
  - Persistence: Asynchronously stores diagnosis records to `diagnoses` table with ownership, JSONB symptoms, vehicle name, and scaled percentage confidence.
- **Frontend Guided Diagnosis**:
  - Multi-step guided UI captures vehicle type, symptoms, and problem descriptions.
- **Integration Mismatch**:
  - Frontend `DiagnosisService.parseDiagnosis` expects `possible_causes` (throws `FormatException` if empty), `severity`, `should_drive`, and `recommended_service`.
  - Backend `DiagnosisResponse` returns `predicted_fault`, `confidence`, `estimated_cost`, `repair_time`, `safety_advice`, `diagnosis_mode`.

---

# 7. Mechanic Flow

- **Backend Mechanics Module**:
  - Endpoints: `GET /api/v1/mechanic/mechanics`, `/featured`, `/{id}`, `/{id}/services`, `/{id}/reviews`, `/services`, `/categories`.
  - Full relational schema with skills, languages, working hours, and rating aggregations.
- **Frontend Discovery**:
  - Mechanics catalog, search by specialty, interactive map, ratings, and profile cards exist in Flutter.
- **Integration Status**: Frontend uses local mock mechanic profiles; not wired to backend REST API.

---

# 8. Booking Flow

- **Backend Booking State Machine**:
  - Endpoints: `POST /api/v1/mechanic/bookings`, `GET /bookings`, `/{id}`, `/{id}/cancel`, `/{id}/complete`, `/{id}/events`, `/{id}/rating`.
  - Lifecycle: `requested` → `confirmed` → `in_progress` → `completed` / `cancelled`.
  - Prevents overlapping bookings, validates working hours, and enforces ownership isolation on event history and reviews.
- **Frontend Booking UI**:
  - Step-by-step appointment scheduler, address picker, vehicle selector, and live tracking UI exist in Flutter.
- **Integration Status**: Frontend runs locally against `FuelRepository` and `MechanicProvider` mock stores.

---

# 9. Frontend ↔ Backend Integration Audit

| Module | Backend Endpoint | Frontend Consumer | Status / Discrepancy |
|---|---|---|---|
| **Authentication** | `POST /api/v1/auth/login` | Mock `AuthRepository` | **Disconnected** — Flutter does not make HTTP requests to backend auth. |
| **User Profile** | `GET /api/v1/users/me` | Mock `ProfileProvider` | **Disconnected** — User profile state is stored in-memory in Flutter. |
| **AI Diagnosis** | `POST /api/v1/diagnosis/diagnose` | Mock `AiRepository.diagnoseVehicle` | **Schema Mismatch** — Frontend expects `possible_causes`, `severity`; backend returns `predicted_fault`, `safety_advice`. |
| **AI Chat** | `POST /api/v1/conversation/chat` | Mock `AiRepository.sendMessage` | **Format Mismatch** — Backend returns raw text; Flutter expects structured UI blocks. |
| **Mechanics** | `GET /api/v1/mechanic/mechanics` | Mock `MechanicRepository` | **Disconnected** — Mechanic listings are not fetched from FastAPI. |
| **Bookings** | `POST /api/v1/mechanic/bookings` | Mock `MechanicBooking` | **Disconnected** — Bookings are not persisted to backend database. |
| **Geocoding** | N/A (External OSM) | `GeocodingService` (HTTP) | **Connected** — Only active HTTP client in the Flutter codebase. |

---

# 10. Database

- **Status**: **LIVE POSTGRESQL: NOT VERIFIED — DATABASE_URL unavailable**
- **Schema Analysis**:
  - `schema.sql` defines 12 core tables (`users`, `refresh_tokens`, `mechanics`, `mechanic_skills`, `mechanic_languages`, `mechanic_working_hours`, `mechanic_services`, `mechanic_categories`, `mechanic_reviews`, `mechanic_bookings`, `booking_events`, `ratings`, `conversations`, `chat_messages`, `diagnoses`).
  - SQLAlchemy 2.0 declarative models and Alembic migrations `0001` through `0004` accurately reflect the database schema.
  - Foreign key cascades (`ondelete="CASCADE"`) and composite indexes match architectural specifications.

---

# 11. Security

- **Multi-Tenancy & Authorization**:
  - Authenticated dependencies enforce that `user_id` is always derived from the verified JWT, eliminating client-forged IDOR risks.
  - Missing or foreign user resources return identical 404 responses to prevent entity existence enumeration.
- **Secrets Management**:
  - JWT secrets and API keys are read from environment variables; `.env` is ignored by `.gitignore`.
  - Gemini API key is logged in masked format (`AQ.A...fKCQ`).
- **CORS Configuration**:
  - Configured with explicit origin allowlist (`http://localhost:3000`, `http://127.0.0.1:3000`), avoiding wildcard origins when credentials are enabled.

---

# 12. Performance

- **Model Loading**:
  - XGBoost model and RAG embeddings are loaded at module/lifespan initialization rather than per-request.
- **RAG & HuggingFace Network Overhead**:
  - On startup, `rag_service.py` issues HTTP HEAD checks to HuggingFace Hub to verify model versions. In offline environments or under high load, this introduces startup latency.
- **Async Execution**:
  - Diagnosis persistence and chat history operations are asynchronous with flush-only transactions. Synchronous ML inference calls are fast CPU operations.

---

# 13. UX / Runtime Problems

- **Offline / Mock Disconnection**: Users interacting with the Flutter frontend will experience a polished UI, but changes do not persist to the backend database. Logging in on one device will not synchronize to another.
- **Shared Preferences Warning**: During Flutter test execution, mock storage warnings (`MissingPluginException`) occur for unit tests without channel mocking, although all widget tests pass.

---

# 14. Bugs Found

1. **Diagnosis Persistence Data Loss & Field Mismatch (RESOLVED in Stage 3)**:
   - Fixed `symptoms=None`, `confidence` truncation (`0.95` → `0`), `safety_advice` mapping, and `brand`+`model` synthesis.
2. **Diagnosis Response Schema Incompatibility with Flutter Parser (ACTIVE)**:
   - Flutter `DiagnosisService.parseDiagnosis` throws a `FormatException` if `possible_causes` is empty or missing, but backend `DiagnosisResponse` does not supply `possible_causes`.
3. **AI Chat Response Structure Mismatch (ACTIVE)**:
   - Backend Gemini response is plain text, whereas Flutter UI expects structured JSON blocks (`warning`, `bulletList`, `checklist`).
4. **HuggingFace Embeddings Deprecation Warning (ACTIVE)**:
   - `langchain_community.embeddings.HuggingFaceEmbeddings` is deprecated; should migrate to `langchain_huggingface.HuggingFaceEmbeddings`.

---

# 15. Critical Blockers

1. **Live PostgreSQL Database Missing**: `DATABASE_URL` is absent from `.env`, preventing end-to-end live database testing and live backend execution.
2. **Frontend HTTP Client Missing**: Flutter client lacks an HTTP API service layer connecting UI providers to the FastAPI backend endpoints.

---

# 16. Recommended Improvements

### P0 — Critical (Immediate Roadblock)
1. **Provision PostgreSQL Database**: Supply `DATABASE_URL` in `backend/.env` and execute `alembic upgrade head`.
2. **Implement Flutter HTTP Client Layer**: Create an `ApiClient` with interceptors (JWT auth injection, 401 refresh token retry, error normalization) in `frontend/lib/services/api/`.

### P1 — High (Core Functionality Alignment)
3. **Align Diagnosis Contract**: Update Flutter `DiagnosisService` to consume backend `DiagnosisResponse` (handling `predicted_fault`, `safety_advice`, `repair_time`, and optional causes gracefully without throwing).
4. **Structured AI Chat Responses**: Format backend chat responses to support structured blocks for frontend rendering, or enhance frontend parser to render markdown into UI blocks.

### P2 — Medium (Architecture & Maintenance)
5. **Migrate HuggingFace Embeddings**: Update import to `langchain_huggingface` in `backend/app/services/rag_service.py`.
6. **Add Root `pytest.ini`**: Include `pythonpath = ["backend"]` in repo root for developer convenience when running tests.

### P3 — Low (Polish & Optimization)
7. **Offline Embeddings Cache**: Pre-cache sentence transformer weights locally to eliminate HuggingFace Hub network checks during startup.

---

# 17. What Is Actually Working

- Full backend REST API suite (150/150 passing tests).
- JWT Authentication, password hashing, and token refresh logic on backend.
- Conversation and message ownership isolation with transaction commit boundaries.
- User profile CRUD APIs with role validation.
- Complete mechanics scheduling, booking state machine, and review audit logging.
- AI telemetry fault classification (XGBoost) and symptom-based diagnosis.
- Complete Flutter frontend UI with 162/162 passing widget and flow tests.

---

# 18. What Is NOT Working

- End-to-end integration between Flutter UI and FastAPI backend (frontend is currently running on mock data stores).
- Live PostgreSQL persistence verification (no live database server configured).
- Structured UI block generation in backend chat service.

---

# 19. What Cannot Be Verified

- Real PostgreSQL concurrent connection pooling, trigger execution, and live JSONB index performance (due to lack of `DATABASE_URL`).
- Real-time mobile device push notifications (Firebase credentials unset).
- Live mobile device Bluetooth/OBD-II hardware telemetry streaming (physical hardware required).
