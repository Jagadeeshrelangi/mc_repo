# Mecha Connect — Documentation

**Purpose:** Canonical engineering workspace for Mecha Connect documentation.

## Structure

```
docs/
├── README.md (this file)
├── CANONICAL_DOCUMENT_MAP.md (single source of truth per topic)
├── common/       (project overview, architecture overview, public roadmap,
│                  development workflow, contributing, coding standards,
│                  glossary, FAQ + supporting knowledge/PRD/installation docs)
├── frontend/     (README, Architecture, UI_UX, Navigation, State_Management,
│                  Provider_Graph, Repository_Layer, Feature_Modules,
│                  Design_System, Testing, Assets + modules/workflows/diagrams)
├── backend/      (README, Architecture, API, Database, Authentication, AI,
│                  Deployment, Testing, Infrastructure + schema.sql/blueprints)
├── handbook/     (ENGINEERING_HANDBOOK.md + CHANGELOG.md)
├── exports/      (machine-readable JSON indexes)
├── tools/        (bundle generation scripts)
├── archive/      (historical records: sprint_history, legacy, source)
```
Confidential documents (business model, financials, risk register, security,
operations, internal roadmap) are kept outside the public documentation set,
excluded from bundles, and not tracked in the repository.

## Reading Order

**For AI:**
1. `common/PROJECT_OVERVIEW.md` — project identity
2. `common/KNOWLEDGE_GRAPH.md` — relationships
3. `common/MASTER_PROJECT_KNOWLEDGE_BASE.md` — deep knowledge
4. `exports/MASTER_PROJECT_DATA.json` — machine-readable facts
5. `common/DEVELOPMENT_WORKFLOW.md` — build, test, and architecture rules

**For Humans:**
1. `common/PROJECT_OVERVIEW.md` — start here
2. `common/ARCHITECTURE_OVERVIEW.md` — high-level system view
3. `frontend/architecture/diagrams/` — visual architecture
4. `frontend/workflows/` — business flows
5. `frontend/modules/` — feature details

## Rules

- **This tree is canonical** — one source of truth per topic (see CANONICAL_DOCUMENT_MAP.md)
- **archive/** is read-only — historical records (sprint_history, legacy, source)
- **Confidential docs are excluded** — never referenced by this README, the
  handbook, or any public index; excluded from generated bundles and the repository
- **handbook/** must consume only public documentation
- **Public docs never contain** business, financial, security, or internal-strategy
  content; that content is kept outside the public documentation set
- All other folders are permanent engineering knowledge
