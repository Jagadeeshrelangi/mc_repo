# AI Services — Mecha Connect (Backend)

> The backend AI stack. Services are implemented and production-quality; wiring
> into the app is Sprint 2 scope.

## 1. Services

| Service | Model / Technique | Status |
|---|---|---|
| `ChatService` (`app/services/chat_service.py`) | Gemini 2.5-flash, intent classification, fallback mode | Complete |
| `DiagnosisService` (`app/services/diagnosis_service.py`) | XGBoost `fault_classifier.joblib`, telemetry + symptom modes | Complete |
| `RAGService` (`app/services/rag_service.py`) | FAISS index + HuggingFace embeddings + Gemini | Complete |
| `build_rag_index.py` | Builds FAISS index from knowledge base | Complete |
| `ai/models/train.py` | XGBoost training script | Complete |
| `ai/data/generate_data.py` | Telemetry CSV generator | Complete |
| `ai/metadata.py` | Fault cost/time/advice lookup | Complete |

## 2. AI Endpoints

| Method | Path | Description |
|---|---|---|
| POST | `/api/v1/conversation/chat` | Chat with intent routing |
| POST | `/api/v1/conversation/session` | Create session (UUID) |
| GET | `/api/v1/conversation/history` | Retrieve session messages |
| POST | `/api/v1/diagnosis/diagnose` | Vehicle fault prediction |
| POST | `/api/v1/knowledge/query` | RAG-powered Q&A |
| GET | `/health` | Server health |

These mirror the frozen AI surface in `docs/backend/API.md` exactly.

## 3. Knowledge Base

`ai/knowledge_base/` categories: `dashboard_symbols`, `faq`, `manuals`,
`obd_codes`, plus the built `faiss_index`.

## 4. Frontend Mapping

The Flutter AI module (`AiProvider` owns ONE `AiRepository`) consumes chat,
diagnosis, and knowledge surfaces; `AiAction` deep-links
(`openDiagnosis | bookMechanic | searchParts | fuelRecommendation`) route into
mechanic/fuel/marketplace. Diagnosis payload shape (confidence, severity,
estimated cost, recommended action) is frozen in `docs/backend/API.md` §4.

## 5. Sprint 2 Integration

- Persist conversations/chat messages/diagnoses (tables in `docs/backend/Database.md` §8).
- Add user context to responses; keep existing services as-is (reuse strategy in
  `architecture/SPRINT_2_BACKEND_BLUEPRINT.md` §5).
