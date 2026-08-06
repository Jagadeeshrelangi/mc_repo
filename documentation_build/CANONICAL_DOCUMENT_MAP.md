# CANONICAL DOCUMENT MAP — Mecha Connect

> **Final Documentation Consolidation · 2026-08-06**
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

| Topic | Canonical Document | Location | Supporting Documents | Archived Documents |
|---|---|---|---|---|
| **Project Identity** | PROJECT_CONTEXT.md | `00_core/` | AI_PROJECT_MEMORY.md, PROJECT_TIMELINE.md | N/A |
| **AI Memory** | AI_PROJECT_MEMORY.md | `00_core/` | PROJECT_CONTEXT.md | N/A |
| **Operating Manual** | PROJECT_OPERATING_MANUAL.md | `00_core/` | N/A | N/A |
| **Business Model** | BUSINESS_MODEL.md | `00_core/` | PRODUCT_REQUIREMENTS_DOCUMENT.md | N/A |
| **Product Requirements** | PRODUCT_REQUIREMENTS_DOCUMENT.md | `00_core/` | FEATURE_SPECIFICATIONS.md | N/A |
| **Feature Specifications** | FEATURE_SPECIFICATIONS.md | `00_core/` | PRODUCT_REQUIREMENTS_DOCUMENT.md | N/A |
| **Roadmap** | ROADMAP.md | `00_core/` | PROJECT_TIMELINE.md | N/A |
| **Risk Analysis** | RISK_ANALYSIS.md | `00_core/` | N/A | N/A |
| **Project Status** | PROJECT_STATUS.md | `00_core/` | N/A | archive/sprint_history/PROJECT_STATUS_REPORT.md |
| **Changelog** | CHANGELOG.md | `00_core/` | N/A | archive/legacy/VERSION_HISTORY.md |
| **Project Timeline** | PROJECT_TIMELINE.md | `00_core/` | CHANGELOG.md | N/A |
| **Installation** | INSTALLATION.md | `00_core/` | N/A | N/A |
| **Deployment** | DEPLOYMENT.md | `00_core/` | N/A | N/A |
| **Contributing** | CONTRIBUTING.md | `00_core/` | N/A | N/A |
| **Testing** | TEST_PLAN.md | `00_core/` | QA_CERTIFICATION_REPORT.md (record) | N/A |
| **Copyright** | COPYRIGHT_NOTICE.md | `00_core/` | LICENSE_GUIDE.md | N/A |
| **Licensing** | LICENSE_GUIDE.md | `00_core/` | COPYRIGHT_NOTICE.md | N/A |
| **Architecture** | FRONTEND_ARCHITECTURE.md | `02_architecture/` | MASTER_PROJECT_KNOWLEDGE_BASE.md, diagrams/ | archive/legacy/SYSTEM_ARCHITECTURE.md, PROJECT_ARCHITECTURE.md, AI_ARCHITECTURE.md |
| **UI Design System** | UI_DESIGN_SYSTEM.md | `02_architecture/` | N/A | archive/legacy/DESIGN_SYSTEM.md |
| **Glossary** | glossary.md | `02_architecture/` | N/A | N/A |
| **Version Matrix** | version_matrix.md | `02_architecture/` | N/A | N/A |
| **Diagrams** | Mermaid sources (.mmd) | `02_architecture/diagrams/` | SVG, PNG renders | N/A |
| **Database** | DATABASE_BLUEPRINT.md | `03_database/` | schema.sql, data_model.md | archive/legacy/DATABASE_SCHEMA.md |
| **API** | API_CONTRACT.md | `04_api/` | endpoint_catalog.md | archive/legacy/API_SPEC.md |
| **Navigation** | NAVIGATION_MAP.md | `05_navigation/` | route_maps.md | N/A |
| **Workflows** | Individual workflow files | `06_workflows/` | README.md | N/A |
| **Modules** | Individual module files | `07_modules/` | overview.md | N/A |
| **Master Handbook** | MECHA_CONNECT_MASTER_HANDBOOK.md | `01_knowledge/` | KNOWLEDGE_GRAPH.md, MASTER_PROJECT_KNOWLEDGE_BASE.md | archive/legacy/MASTER_ENGINEERING_HANDBOOK_v1.0.md |
| **Technical Knowledge** | MASTER_PROJECT_KNOWLEDGE_BASE.md | `01_knowledge/` | KNOWLEDGE_GRAPH.md | archive/legacy/01_inventory/ |
| **Knowledge Graph** | KNOWLEDGE_GRAPH.md | `01_knowledge/` | MASTER_PROJECT_KNOWLEDGE_BASE.md | N/A |
| **JSON Exports** | MASTER_PROJECT_DATA.json | `09_exports/` | knowledge_graph.json | archive/legacy/documentation_index.json |
| **RC1 Release Records** | QA_CERTIFICATION_REPORT.md | `archive/sprint_history/` | FRONTEND_LOCK_REPORT.md, RC1_CHECKLIST.md, RC1_RELEASE_REPORT.md, RELEASE_NOTES_RC1.md | N/A |
| **Engineering Audit (Sprint 2 baseline)** | AUDIT_SUMMARY.md | `archive/engineering_review/` | Individual audit reports | N/A |
| **Engineering Review (Sprint 2 baseline)** | ENGINEERING_REVIEW_REPORT.md | `archive/engineering_review/` | PRESPRINT2_ENGINEERING_CLEANUP_REPORT.md (cleanup deliverable) | N/A |

## Archive Taxonomy

- `archive/engineering_review/` — engineering audits, gap analysis, merge summary, sprint 2 blueprint, cleanup deliverable
- `archive/sprint_history/` — per-sprint records and RC1 release/certification records
- `archive/legacy/` — superseded specs, process reports, stale indexes, obsolete inventories

## Rules

1. **ONE canonical document per topic** — never reference multiple documents as sources of truth
2. **Update canonical documents** — when information changes, update the canonical document first
3. **Supporting documents** — provide context but do not override canonical documents
4. **Archived documents** — historical only, never reference in current work
5. **Cross-references** — always point to canonical documents, not supporting or archived docs
6. **Generated artifacts** — `10_claude_bundle/` is regenerable via `tools/generate_bundle.py`; do not maintain by hand

## Maintenance

- **When to update:** When a topic's source of truth changes
- **Who updates:** Documentation owner (see folder READMEs)
- **Review frequency:** At each phase gate
