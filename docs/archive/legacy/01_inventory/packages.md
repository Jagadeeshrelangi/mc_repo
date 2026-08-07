# Packages Inventory — Mecha Connect

> Phase 1 · from `pubspec.yaml` (version 1.0.0+1)

## 1. Direct Dependencies

| Package | Version | Purpose |
|---|---|---|
| `provider` | 6.1.5 | State management (7 module providers + Theme + Location) |
| `google_nav_bar` | 5.0.7 | 5-tab bottom navigation shell |
| `device_preview` | 1.2.0 | Debug-only device preview (DevicePreview wrapper) |
| `shared_preferences` | 2.5.3 | Local persistence (theme mode, auth session, orders) |
| `flutter_dotenv` | 5.2.1 | `.env` config loading at startup |
| `latlong2` | 0.9.1 | LatLng model + distance math (fuel delivery, nearby) |
| `geolocator` | 13.0.4 | Device location services |
| `permission_handler` | 11.4.0 | Runtime location permission flow |
| `flutter_map` | 7.0.2 | Map rendering (fuel delivery, mechanic nearby) |
| `http` | 1.6.0 | HTTP client (future backend integration; not used at RC1) |

## 2. Dev Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_lints` | 5.0.0 | Lint ruleset |
| `flutter_test` | (SDK) | Test framework |
| `integration_test` | (SDK) | Integration tests (`test/integration/`) |

## 3. Backend Dependencies (Python — `backend/requirements.txt`)

| Package | Version | Purpose |
|---|---|---|
| `fastapi` | >=0.110.0 | API framework |
| `uvicorn` | >=0.28.0 | ASGI server |
| `pydantic` / `pydantic-settings` | >=2.x | Schemas/config |
| `scikit-learn`, `xgboost`, `pandas`, `numpy`, `joblib` | — | Fault classifier pipeline |
| `faiss-cpu`, `sentence-transformers` | — | RAG index (knowledge base) |
| `langchain`, `langchain-community`, `langchain-google-genai` | — | Gemini chat / RAG orchestration |
| `firebase-admin` | >=6.5.0 | Auth/firestore (scaffolded) |
| `pypdf`, `python-docx` | — | Manual/document ingestion |
| `requests`, `python-dotenv`, `python-multipart` | — | Utility |

> Note: backend deps are for the Sprint 2 FastAPI target, not the current Flutter client.
