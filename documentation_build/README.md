# Documentation Build — Mecha Connect

**Purpose:** Canonical engineering workspace for Mecha Connect documentation.

## Structure

```
documentation_build/
├── README.md (this file)
├── NEXT_SESSION_HANDOVER.md (AI handover)
├── CANONICAL_DOCUMENT_MAP.md (source of truth)
├── 00_core/ (project identity, product docs, changelog, manual)
├── 01_knowledge/ (technical knowledge base, master handbook)
├── 02_architecture/ (architecture, diagrams, design system, glossary)
├── 03_database/ (schema, data model)
├── 04_api/ (API contract)
├── 05_navigation/ (route maps)
├── 06_workflows/ (business workflows)
├── 07_modules/ (feature modules)
├── 08_assets/ (figures, diagrams, screenshots, source assets)
├── 09_exports/ (JSON exports)
├── tools/ (generation scripts)
└── archive/ (historical records)
    ├── engineering_review/
    ├── sprint_history/
    └── legacy/
```

## Reading Order

**For AI:**
1. `NEXT_SESSION_HANDOVER.md` — current state
2. `00_core/PROJECT_CONTEXT.md` — project identity
3. `01_knowledge/KNOWLEDGE_GRAPH.md` — relationships
4. `01_knowledge/MASTER_PROJECT_KNOWLEDGE_BASE.md` — deep knowledge
5. `09_exports/MASTER_PROJECT_DATA.json` — machine-readable facts

**For Humans:**
1. `00_core/PROJECT_CONTEXT.md` — start here
2. `01_knowledge/MASTER_PROJECT_KNOWLEDGE_BASE.md` — deep dive
3. `02_architecture/diagrams/` — visual architecture
4. `06_workflows/` — business flows
5. `07_modules/` — feature details

## Rules

- **This tree is canonical** — one source of truth per topic (see CANONICAL_DOCUMENT_MAP.md)
- **archive/** is read-only — historical records (engineering_review, sprint_history, legacy)
- **10_claude_bundle/** is auto-generated — regenerate via `tools/generate_bundle.py`, never edit by hand
- All other folders are permanent engineering knowledge
