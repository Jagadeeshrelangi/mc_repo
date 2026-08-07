# Diagrams — Mecha Connect

> Phase 3 · Mermaid sources in `mermaid/`. SVG/PNG exported here when tooling is available.

## Inventory

| Diagram | File | Content |
|---|---|---|
| System architecture | `system_architecture.mmd` | Client ↔ mock boundary ↔ FastAPI (Sprint 2) ↔ on-device state |
| Frontend architecture | `frontend_architecture.mmd` | Entry → provider graph → splash → shell decision tree |
| Provider graph | `provider_graph.mmd` | 7 module providers + location/theme + repo/service dependencies |
| Repository layer | `repository_layer.mmd` | Repository seam + mock realism → Sprint 2 HTTP swap |
| Folder structure | `folder_structure.mmd` | `frontend/lib/` tree with per-module counts |
| Navigation shell | `navigation_shell.mmd` | 5-tab shell + mechanic/fuel/marketplace flows |
| AI flows | `ai_flows.mmd` | AiHome → chat/diagnosis/history + cross-module actions |
| Marketplace flows | `marketplace_flows.mmd` | Catalog → product → cart → checkout → orders tab |
| Mechanic flows | `mechanic_flows.mmd` | Browse → book → track → review lifecycle |
| Fuel flows | `fuel_flows.mmd` | Book → pay → confirm → track → complete + status sequence |
| Profile flows | `profile_flows.mmd` | All profile sub-routes + seeded data |
| Auth flow | `auth_flow.mmd` | Splash decision + login/signup/forgot + logout |
| ER diagram | `er_diagram.mmd` | PostgreSQL target schema entities + relations |
| API flow | `api_flow.mmd` | Mock repos → FastAPI endpoints → AI assets + stores |
| Orders tab | `orders_tab.mmd` | orderStore/ordersList single-source flow |

## Export status

- Mermaid sources: **15/15** authored.
- SVG export: **15/15** exported via `@mermaid-js/mermaid-cli`.
- PNG export: **15/15** exported (puppeteer screenshot).

> All diagrams grounded in `../Architecture.md`, `../Navigation.md`,
> `../Design_System.md`, `../Feature_Modules.md`, `../backend/Database.md`,
> `../backend/API.md` and the Phase 1 repo scan.
