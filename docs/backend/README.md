# Backend Documentation — Mecha Connect

> FastAPI · PostgreSQL 15 · Sprint 2 target. At RC1 the backend is a scaffold:
> AI services exist; core infrastructure is planned.

**Canonical documents:**
- `Architecture.md` — backend blueprint, layer/entity model, API surface, security, deployment
- `API.md` — frozen API contract the backend must implement
- `Database.md` — PostgreSQL schema blueprint (source of `schema.sql`)
- `Authentication.md` — JWT/bcrypt/RBAC plan
- `AI.md` — Gemini chat, XGBoost diagnosis, FAISS RAG services
- `Deployment.md` — build, release, CI/CD, version strategy
- `Testing.md` — pytest strategy and coverage gates
- `Infrastructure.md` — Docker, Redis, monitoring, environment

**Supporting reference content:**
- `architecture/SPRINT_2_BACKEND_BLUEPRINT.md` — full Sprint 2 audit + implementation roadmap
- `api/endpoint_catalog.md` — endpoint catalog
- `database/data_model.md` — data-model notes
- `database/schema.sql` — concrete DDL

**Rule:** backend docs are PUBLIC. All content must stay free of business,
financial, security-strategy, and internal-strategy information. See
`docs/README.md`.
