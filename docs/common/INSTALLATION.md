# Mecha Connect Local Installation Guide

Follow these steps to set up both the backend services and the Flutter mobile client in your local development environment.

---

## Prerequisites

Ensure you have the following software installed:
* **Python** ($\ge 3.10$)
* **Flutter SDK** ($\ge 3.19$)
* **Git**
* An active **Google Gemini API Key** (to enable RAG and chat features).

---

## 1. Backend Environment Setup

### A. Clone and Navigate
Open your terminal and clone the repository, then navigate to the backend directory:
```bash
cd mecha_connect/backend
```

### B. Virtual Environment
Create and activate a Python virtual environment:
```bash
# Windows
python -m venv venv
.\venv\Scripts\activate

# macOS / Linux
python3 -m venv venv
source venv/bin/activate
```

### C. Install Dependencies
Install all required libraries:
```bash
pip install -r requirements.txt
```

### D. Environment Variables Configuration
Create a `.env` file in the root of the `backend/` directory. Recognized
variables (see `backend/app/core/config.py`):
```env
GEMINI_API_KEY=your_gemini_api_key_here
ENABLE_FALLBACK=true
LOG_LEVEL=INFO
```
- `GEMINI_API_KEY` — optional; the Gemini LLM is only used when a key is set.
- `ENABLE_FALLBACK` — code default is `true` (local rule-based fallback when no
  valid key). Set `false` for strict mode: when `false` and no valid key is set,
  Gemini-dependent endpoints return HTTP 422.
- `LOG_LEVEL` — defaults to `INFO`.
- There is no database layer yet — the scaffold has no `DATABASE_URL` field.

---

## 2. ML Training & Index Generation

Before running the API server, you must generate the telemetry dataset, train the fault classification model, and compile the RAG vector index. All backend commands run from `backend/`:
```bash
cd backend
python ai/data/generate_data.py
python ai/models/train.py
```
This saves the best-performing model to `ai/models/fault_classifier.joblib`.

### B. RAG Index Compilation
Compile the FAISS vector store index:
```bash
python ai/build_rag_index.py
```
This chunks the manual text files and saves the index files under `ai/knowledge_base/faiss_index/`.

---

## 3. Run the Backend API

Start the FastAPI application using the Uvicorn server (from `backend/`):
```bash
uvicorn app.main:app --reload
```
The server will start at `http://127.0.0.1:8000`. You can inspect the interactive OpenAPI/Swagger dashboard at `http://127.0.0.1:8000/docs`.

---

## 4. Flutter Client Setup

Open a new terminal window and navigate to the Flutter project (`frontend/`):

### A. Fetch Packages
Resolve dependencies:
```bash
cd frontend
flutter pub get
```

### B. Configure Client Environment
Create a client configuration file or set your local IP in your network utilities configuration to point to `http://127.0.0.1:8000` (or `10.0.2.2` when running inside an Android Emulator).

### C. Run the Application
Start the mobile application:
```bash
flutter run
```
To run the Web preview (utilizes Device Preview layout):
```bash
flutter run -d chrome
```

---

## 5. Backend Scaffold — As-Built (verified 2026-08-06)

Independent engineering review evidence, verified against source, not copied
from documentation. The full report is archived internally (not part of the
public documentation tree).

### 5.1 Scope (verified)

- **28 tracked files, 18 `.py`** under `backend/` (app factory, 3 routers,
  3 services, 3 schemas, core config/exceptions/logging, AI assets/scripts).
- **6 endpoints**, all under `/api/v1` except `/health`:

| Method | Path | Handler |
|---|---|---|
| POST | `/api/v1/conversation/chat` | `chat_service.handle_chat` |
| POST | `/api/v1/conversation/session` | `chat_service.create_session` |
| GET | `/api/v1/conversation/history` | `chat_service.get_session_history` |
| POST | `/api/v1/diagnosis/diagnose` | `diagnosis_service.predict_fault` |
| POST | `/api/v1/knowledge/query` | `rag_service.query_rag` |
| GET | `/health` | health check |

### 5.2 Config defaults (`backend/app/core/config.py`)

| Field | Default | Notes |
|---|---|---|
| `GEMINI_API_KEY` | `None` | optional at import; read from `.env` |
| `ENABLE_FALLBACK` | `True` | code default (resilient); `backend/.env` sets `False` — strict ⇒ Gemini endpoints raise HTTP 422 without a valid key |
| `LOG_LEVEL` | `INFO` | — |
| `GEMINI_MODEL` | `gemini-2.5-flash` | single source of truth for all services |
| `DEFAULT_VEHICLE_MILEAGE` | `80000` | used when symptom-mode diagnosis has no odometer reading |
| `CORS_ORIGINS` | `localhost:3000`, `127.0.0.1:3000` | explicit allow-list (never `*` with credentials) |

### 5.3 Known as-built constraints (all verified)

- **No DB layer, no auth, no tests, no Alembic** — the backend is a prototype
  scaffold (~20% complete by its own Sprint 2 blueprint math).
- **CORS allow-list** — `app/main.py` uses `settings.CORS_ORIGINS` (explicit
  `localhost:3000` origins). The audit-time wildcard `allow_origins=["*"]` was
  fixed in the Pre-Sprint 2 Cleanup (2026-08-06).
- **`requirements.txt` pinned** to the verified venv freeze (2026-08-06); the
  audit-time `>=` unpinned file was fixed in the same cleanup.
- **Hardcoded values centralized** — `mileage=80000` and `gemini-2.5-flash` are
  now single-source in `config.py` (`DEFAULT_VEHICLE_MILEAGE`, `GEMINI_MODEL`);
  all services read them from `settings`.
- **In-memory session store** — `ChatService.sessions` is a plain dict;
  history lost on restart, no eviction.
- **FAISS `allow_dangerous_deserialization=True`**
  (`app/services/rag_service.py:34`) — necessary for pickle-based indexes;
  review before loading any untrusted index source.

### 5.4 AI assets (verified)

| Asset | Reality |
|---|---|
| Fault classifier | XGBoost champion (vs RandomForest), trained on **synthetic** telemetry; `fault_classifier.joblib` ≈ 378 KB |
| Training data | `generate_data.py` synthetic CSV — 1,200 rows |
| RAG index | FAISS (CPU) + `all-MiniLM-L6-v2`; index ≈ 34.5 KB |
| Knowledge base | 5 text files (car/bike manuals, FAQ, OBD guide, dashboard symbols) ≈ 7 KB total |
| LLM | Gemini 2.5 Flash |

> **Operational note:** `config.py` defaults `ENABLE_FALLBACK=true` (safe dev
> behavior), but `backend/.env` ships `ENABLE_FALLBACK=False` — with that file
> and an unverified key, `chat`, `diagnosis` and `knowledge` calls return
> HTTP 422. Set `true` in `.env` (or provide a valid key) for a zero-cost dev
> backend.
