# CANONICAL DOCUMENT MAP — Mecha Connect

> **Documentation Restructure · 2026-08-06**
> Single source of truth for every documentation topic.

## Purpose

This map identifies exactly ONE canonical document for every topic in the Mecha Connect
documentation system. It eliminates confusion about which document to reference, update,
or trust.

## How to Use

1. Find your topic in the table below
2. Use ONLY the canonical document listed
3. Supporting documents provide additional context but are not the source of truth
4. Archived documents are historical only — do not reference in current work

## Canonical Documents

### Common (`docs/common/`)

| Topic | Canonical Document | Supporting Documents | Archived Documents |
|---|---|---|---|
| **Project Overview** | PROJECT_OVERVIEW.md | AI_PROJECT_MEMORY.md, PROJECT_STATUS.md, PROJECT_TIMELINE.md | N/A |
| **Architecture Overview** | ARCHITECTURE_OVERVIEW.md | `frontend/Architecture.md`, `backend/Architecture.md` | N/A |
| **Roadmap (public)** | ROADMAP_PUBLIC.md | PROJECT_TIMELINE.md, `handbook/CHANGELOG.md` | N/A |
| **Development Workflow** | DEVELOPMENT_WORKFLOW.md | INSTALLATION.md, CONTRIBUTING.md | N/A |
| **Contributing** | CONTRIBUTING.md | DEVELOPMENT_WORKFLOW.md | N/A |
| **Coding Standards** | CODING_STANDARDS.md | DEVELOPMENT_WORKFLOW.md | N/A |
| **Glossary** | GLOSSARY.md | N/A | N/A |
| **FAQ** | FAQ.md | N/A | N/A |
| **Product Requirements** | PRODUCT_REQUIREMENTS_DOCUMENT.md | FEATURE_SPECIFICATIONS.md | N/A |
| **Feature Specifications** | FEATURE_SPECIFICATIONS.md | PRODUCT_REQUIREMENTS_DOCUMENT.md | N/A |
| **Project Status** | PROJECT_STATUS.md | N/A | archive/sprint_history/PROJECT_STATUS_REPORT.md |
| **Project Timeline** | PROJECT_TIMELINE.md | `handbook/CHANGELOG.md` | N/A |
| **Installation** | INSTALLATION.md | DEVELOPMENT_WORKFLOW.md | N/A |
| **Copyright** | COPYRIGHT_NOTICE.md | LICENSE_GUIDE.md | N/A |
| **Licensing** | LICENSE_GUIDE.md | COPYRIGHT_NOTICE.md | N/A |
| **Technical Knowledge** | MASTER_PROJECT_KNOWLEDGE_BASE.md | KNOWLEDGE_GRAPH.md, AI_PROJECT_MEMORY.md | archive/legacy/01_inventory/ |
| **Knowledge Graph** | KNOWLEDGE_GRAPH.md | MASTER_PROJECT_KNOWLEDGE_BASE.md | N/A |
| **AI Memory** | AI_PROJECT_MEMORY.md | PROJECT_OVERVIEW.md | N/A |

### Frontend (`docs/frontend/`)

| Topic | Canonical Document | Supporting Documents | Archived Documents |
|---|---|---|---|
| **Frontend Architecture** | Architecture.md | `architecture/diagrams/`, MASTER_PROJECT_KNOWLEDGE_BASE.md | archive/legacy/SYSTEM_ARCHITECTURE.md, PROJECT_ARCHITECTURE.md, AI_ARCHITECTURE.md |
| **UI/UX** | UI_UX.md | `workflows/`, Design_System.md | N/A |
| **Navigation** | Navigation.md | `navigation/route_maps.md` | N/A |
| **State Management** | State_Management.md | Architecture.md, Provider_Graph.md | N/A |
| **Provider Graph** | Provider_Graph.md | State_Management.md | N/A |
| **Repository Layer** | Repository_Layer.md | `backend/API.md` | N/A |
| **Feature Modules** | Feature_Modules.md | `modules/` | N/A |
| **Design System** | Design_System.md | UI_UX.md | archive/legacy/DESIGN_SYSTEM.md |
| **Testing** | Testing.md | QA_CERTIFICATION_REPORT.md (record) | N/A |
| **Assets** | Assets.md | `assets/` (manifests) | N/A |
| **Version Matrix** | version_matrix.md (`reference/`) | N/A | N/A |
| **Diagrams** | Mermaid sources (.mmd) (`architecture/diagrams/`) | SVG, PNG renders | N/A |
| **Workflows** | Individual workflow files (`workflows/`) | README.md | N/A |
| **Modules** | Individual module files (`modules/`) | Feature_Modules.md | N/A |

### Backend (`docs/backend/`)

| Topic | Canonical Document | Supporting Documents | Archived Documents |
|---|---|---|---|
| **Backend Architecture** | Architecture.md | `architecture/SPRINT_2_BACKEND_BLUEPRINT.md` | N/A |
| **API** | API.md | `api/endpoint_catalog.md` | archive/legacy/API_SPEC.md |
| **Database** | Database.md | `database/schema.sql`, `database/data_model.md` | archive/legacy/DATABASE_SCHEMA.md |
| **Authentication** | Authentication.md | Architecture.md (§6) | N/A |
| **AI Services** | AI.md | Architecture.md (§4.8) | N/A |
| **Deployment** | Deployment.md | N/A | N/A |
| **Testing** | Testing.md | Architecture.md (§9) | N/A |
| **Infrastructure** | Infrastructure.md | Architecture.md (§7, §10, §11) | N/A |

### Handbook (`docs/handbook/`)

| Topic | Canonical Document | Supporting Documents | Archived Documents |
|---|---|---|---|
| **Engineering Handbook** | ENGINEERING_HANDBOOK.md | KNOWLEDGE_GRAPH.md, MASTER_PROJECT_KNOWLEDGE_BASE.md | archive/legacy/MASTER_ENGINEERING_HANDBOOK_v1.0.md |
| **Changelog** | CHANGELOG.md | ROADMAP_PUBLIC.md | archive/legacy/VERSION_HISTORY.md |

### Exports (`docs/exports/`)

| Topic | Canonical Document | Supporting Documents |
|---|---|---|
| **JSON Exports** | MASTER_PROJECT_DATA.json | knowledge_graph.json |

## Archive Taxonomy

- `archive/sprint_history/` — per-sprint records and RC1 release/certification records
- `archive/legacy/` — superseded specs, process reports, stale indexes, obsolete inventories
- `archive/source/` — raw source materials used to build the documentation

## Confidentiality

- Confidential documents (business model, financials, risk register,
  product strategy, security, operations, internal roadmap, decision logs,
  internal audits, handover notes) are kept outside the public documentation
  set. They are **never** referenced by public documentation, the handbook, or
  generated bundles, and are excluded from the repository via `.gitignore`.

## Rules

1. **ONE canonical document per topic** — never reference multiple documents as sources of truth
2. **Update canonical documents** — when information changes, update the canonical document first
3. **Supporting documents** — provide context but do not override canonical documents
4. **Archived documents** — historical only, never reference in current work
5. **Cross-references** — always point to canonical documents, not supporting or archived docs
6. **Generated artifacts** — the Claude bundle is regenerable via `tools/generate_bundle.py`;
   it must never include confidential files; do not maintain it by hand

## Maintenance

- **When to update:** When a topic's source of truth changes
- **Who updates:** Documentation owner (see folder READMEs)
- **Review frequency:** At each phase gate
