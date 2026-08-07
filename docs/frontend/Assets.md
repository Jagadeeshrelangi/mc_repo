# Assets — Mecha Connect

> Visual asset inventory: app images, figures, diagrams, and screenshots.

## 1. App Assets (`assets/`)

18 product/service images used by the marketplace and service screens:
battery, bike tyre, brake pads, car jack, chain kit, clutch lever, dashboard
camera, engine oil, fuel tank cap, gear knob, gps tracker, helmet lock,
`no_bg.png` (transparent placeholder), radiator, side mirror, spark plugs,
tool kit, wipers.

Full list with typical-use mapping: `assets/diagrams/asset_manifest.md`.

## 2. Diagram Assets

15 architecture diagrams exported with `@mermaid-js/mermaid-cli`
(Mermaid → SVG → PNG), all validated: system_architecture,
frontend_architecture, provider_graph, repository_layer, folder_structure,
navigation_shell, ai_flows, marketplace_flows, mechanic_flows, fuel_flows,
profile_flows, auth_flow, er_diagram, api_flow, orders_tab.

Mermaid sources live in `architecture/diagrams/mermaid/`; exported SVG/PNG in
`architecture/diagrams/{svg,png}/`. Each diagram cites its source document
(FRONTEND_ARCHITECTURE, NAVIGATION_MAP, DATABASE_BLUEPRINT, API_CONTRACT,
sprint reports).

## 3. Figures & Tables

- `assets/figures/figures_manifest.md` — figure inventory
- `assets/figures/tables_manifest.md` — tables inventory
- `assets/figures/diagrams_manifest.md` — export status (15 diagrams)

## 4. Screenshots

- `assets/screenshots/screenshot_manifest.md` — planned capture list
- `assets/screenshots/placeholders/` — placeholder assets
- **Status:** no real screenshots captured at RC1 (0/54 plan) — do not fabricate.

## 5. Archival

Raw source materials (blueprints, PRDs, walkthrough media) live under
`docs/archive/source/`. Asset metadata (dimensions, DPI, license/origin) is
completed during the screenshot/asset phase; license guidance in
`docs/common/LICENSE_GUIDE.md`.
