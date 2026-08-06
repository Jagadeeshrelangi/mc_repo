# Cross-References — Mecha Connect

> Phase 7 · Folder-to-source mapping for the whole bundle. Every artifact traces to a canonical doc.

| Bundle folder | Canonical source(s) in `docs/` |
|---|---|
| `00_inventory/` | Repo scan + FRONTEND_ARCHITECTURE + API_CONTRACT + NAVIGATION_MAP |
| `01_knowledge_base/` | All (merged) |
| `02_diagrams/` | FRONTEND_ARCHITECTURE, NAVIGATION_MAP, DATABASE_BLUEPRINT, API_CONTRACT, UI_DESIGN_SYSTEM |
| `03_database/` | DATABASE_BLUEPRINT |
| `04_api/` | API_CONTRACT |
| `05_navigation/` | NAVIGATION_MAP |
| `06_workflows/` | FEATURE_SPECIFICATIONS, API_CONTRACT, NAVIGATION_MAP, SPRINT_1_7A/1_9/1_9A reports |
| `07_modules/` | FRONTEND_ARCHITECTURE §5.x, API_CONTRACT, sprint reports |
| `08_screenshots/` | NAVIGATION_MAP (flow order), screens_routes inventory |
| `09_figures/` | All diagrams + screenshot plan + TAB list |
| `10_assets/` | `assets/` dir + LICENSE_GUIDE |
| `11_metadata/` | All (glossary/cross-ref/version) |
| `12_exports/` | All (JSON serialization) |
| `13_claude_bundle/` | Self-contained subset |

## Reverse index (doc → bundle)
- `FRONTEND_ARCHITECTURE.md` → inventory, diagrams, modules, workflows
- `NAVIGATION_MAP.md` → navigation, diagrams, workflows
- `DATABASE_BLUEPRINT.md` → database, ER diagram, workflows
- `API_CONTRACT.md` → api, modules, workflows, diagrams
- `UI_DESIGN_SYSTEM.md` → inventory (flutter), modules (design constraints)
- `VERSION_HISTORY.md` / `CHANGELOG.md` → metadata/version_matrix
- `RISK_ANALYSIS.md` → workflows (failure/recovery), knowledge base §10
- `QA_CERTIFICATION_REPORT.md` + `FRONTEND_LOCK_REPORT.md` → knowledge base §8
