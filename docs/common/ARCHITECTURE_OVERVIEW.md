# Architecture Overview — Mecha Connect

> Canonical high-level view of the system architecture. Detailed sources live in
> `frontend/architecture/` and `backend/architecture/`.

## System at a Glance

```
┌───────────────────────────────┐
│   Flutter Frontend (RC1)      │  frontend/lib/ · Provider state · mock repositories
│   Frontend Lock Candidate     │  (UI never bypasses the repository layer)
└──────────────┬────────────────┘
               │ HTTPS / JSON
               ▼
┌───────────────────────────────┐
│   FastAPI Backend (Sprint 2)  │  app/api v1 · Pydantic schemas
│   API gateway + services      │  dependency-injected auth · rate limiting
└───────┬──────────────┬────────┘
        │              │
        ▼              ▼
  Business services  AI Engine
        │          (Gemini + RAG)
        ▼              │
  Repositories         │
        │              │
        └──────┬───────┘
               ▼
        PostgreSQL + Redis
```

## Frontend (frozen)

- Flutter 3.29.2 / Dart ^3.7.2, Provider (6.x) state management, 5-tab
  `google_nav_bar` shell.
- Feature folders: `auth`, `home`, `ai`, `marketplace`, `mechanic`,
  `fuel_delivery`, `profile`, `vehicle_location`.
- Data layer is mock (in-memory repositories) at RC1; Sprint 2 swaps
  repository internals for the real backend without touching the UI.
- **Canonical reference:** `frontend/Architecture.md` (plus
  `frontend/architecture/diagrams/`).

## Backend (Sprint 2 blueprint)

- FastAPI API gateway; layered API → service → repository design.
- Persistence: PostgreSQL (SQLAlchemy async) with Redis caching.
- AI services (ChatService, DiagnosisService, RAGService) exist and are
  production-quality; core business infrastructure (database, auth,
  repositories, business APIs) is the Sprint 2 build target.
- **Canonical reference:** `backend/Architecture.md`.

## Data & APIs

- **Database:** `backend/Database.md`, `backend/database/schema.sql`,
  `backend/database/data_model.md`.
- **API contract (frozen):** `backend/API.md`,
  `backend/api/endpoint_catalog.md` — the contract Sprint 2 must implement.

## Navigation, Workflows, Modules

- `frontend/navigation/` — route maps and navigation shell.
- `frontend/workflows/` — business flows (auth, fuel delivery, mechanic
  booking, marketplace checkout, orders, profile/vehicle, AI diagnosis).
- `frontend/modules/` — per-feature module documentation.

## Diagram Sources

Mermaid sources and PNG/SVG renders live in
`frontend/architecture/diagrams/` (system, frontend, AI, navigation, ER).
