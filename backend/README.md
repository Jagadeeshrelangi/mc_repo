# Mecha Connect — Backend (FastAPI)

FastAPI service for the Mecha Connect platform: chat, diagnosis, and
knowledge endpoints backed by a Gemini/RAG pipeline.

## Contents

- `app/` — FastAPI application (`main.py`, `api/`, `services/`, `schemas/`)
- `ai/` — FAISS index, XGBoost fault classifier, knowledge base
- `requirements.txt` — Python dependencies
- `.env.example` — environment template (copy to `.env`)

## Commands

```bash
python -m venv venv
pip install -r requirements.txt
uvicorn app.main:app --reload
```

See [docs/backend/](../docs/backend/) for API, database, and deployment
documentation.