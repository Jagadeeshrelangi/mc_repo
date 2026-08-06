# Documentation Inventory — Mecha Connect

> Phase 1 · 97 files under `docs/`. Canonical map for the compiler bundle.
> Note: audit sprint already verified 0 broken links; 4 active docs link into `archive/` (accepted at RC1).

## 1. Folder Map

| Folder / file | Contents | Reuse status |
|---|---|---|
| `docs/README.md` + `docs/PROJECT_DOCUMENTATION_INDEX.md` | Index + root (root README has known mojibake in parts; index is authoritative) | index, don't copy prose |
| `docs/01_product/` (6) | PRD, feature specs, business model, project status, risk analysis, roadmap | source for `01_knowledge_base` product section |
| `docs/03_development/` | Dev guides (FAULT_INJECTION etc.), roadmap/architecture | source for dev workflows |
| `docs/05_reports/` (12) | 7 audit reports + 5 completed-sprint reports (1_7A, 1_9, 1_9A, 1_9B, DOCUMENTATION_SPRINT) | audit reports = canonical; sprint reports = module/workflow knowledge |
| `docs/07_rc1_certification/` (17) | Handbook (md/docx/pdf), FRONTEND_ARCHITECTURE, NAVIGATION_MAP, UI_DESIGN_SYSTEM, DATABASE_BLUEPRINT, API_CONTRACT, QA_CERTIFICATION_REPORT, FRONTEND_LOCK_REPORT, VERSION_HISTORY, PROJECT_STATUS_REPORT, RC1 release set | **primary extraction source** |
| `docs/archive/` (43) | Historical sprint docs, old roadmaps, deprecated specs | cite-only, never regenerate |
| `docs/source/` | Legacy image source folder (audit proposes rename → `assets/`) | not code-relevant |

## 2. Canonical Source Docs (used across Phases 2–9)

| Topic | Canonical doc | Handbook chapter |
|---|---|---|
| Product | `01_product/PRODUCT_REQUIREMENTS_DOCUMENT.md`, `FEATURE_SPECIFICATIONS.md` | ch1–ch4 |
| Frontend architecture | `07_rc1_certification/FRONTEND_ARCHITECTURE.md` | ch10 |
| Navigation | `07_rc1_certification/NAVIGATION_MAP.md` | ch12 |
| UI/Design system | `07_rc1_certification/UI_DESIGN_SYSTEM.md` | ch13 |
| Database | `07_rc1_certification/DATABASE_BLUEPRINT.md` | ch14 |
| API contract | `07_rc1_certification/API_CONTRACT.md` | ch15 |
| Testing/QA | `07_rc1_certification/QA_CERTIFICATION_REPORT.md` | ch16 |
| Releases | `07_rc1_certification/VERSION_HISTORY.md` | ch17 |
| Risks | `01_product/RISK_ANALYSIS.md` | ch20 |
| Duplication watch | `docs/05_reports/docs-audit-duplication.md` (ch9 tech stack + ch17 sprint history = biggest clusters) | — |

## 3. Handbook (single source of truth for narrative)
- `docs/07_rc1_certification/MECHA_CONNECT_MASTER_HANDBOOK.md` — 21-chapter book.
- PDF (39 pp) + DOCX (TOC field, 21 chapters) generated from this markdown.

## 4. Inventory-to-Source Traceability
Every inventory file in `00_inventory/` lists "Canonical source" so the Claude bundle
can cite rather than duplicate. Cross-checked against `docs-audit-inventory.md`
(full 97-file line-by-line map).
