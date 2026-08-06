# MERGE SUMMARY — Independent Engineering Review (2026-08-06)

> Outcome of processing `ENGINEERING_REVIEW_REPORT.md`:
> verified findings extracted → long-term knowledge merged → report archived.

## Merged items

| # | Item | Source finding | Target |
|---|---|---|---|
| M1 | Backend as-built scope (28 tracked files, 18 `.py`, 6 endpoints) | Report §7.1 | `docs/03_development/INSTALLATION.md` §5.1 |
| M2 | Config defaults (`ENABLE_FALLBACK=false`, `GEMINI_API_KEY=None`) + 422 behavior | Report §7.1, §9 | `INSTALLATION.md` §1D, §5.2 |
| M3 | Backend constraints (no DB/auth/tests/Alembic, CORS wildcard, unpinned reqs, hardcoded `mileage=80000`, in-memory sessions, FAISS flag) | Report §7.3 | `INSTALLATION.md` §5.3 |
| M4 | AI asset inventory (XGBoost synthetic 1,200 rows, FAISS 34.5 KB, ~7 KB KB, Gemini 2.5 Flash) | Report §8.1 | `INSTALLATION.md` §5.4 |

**Principle applied:** merged ONLY verified, long-term architectural knowledge;
frontend architecture claims (9 providers, 5-tab shell, 7 modules, 7 repos,
timeline) were re-verified TRUE and are already canonical in
`docs/07_rc1_certification/` — no duplication added.

## Ignored items (not merged)

| # | Item | Reason |
|---|---|---|
| I1 | Frontend verified facts (analyze 0, 162/162, 9 providers, 5-tab shell) | Already canonical in `docs/07_rc1_certification/` |
| I2 | Timeline (2026-07-20 → 2026-08-05) | `CHANGELOG.md` + `VERSION_HISTORY.md` already correct; no merge needed |
| I3 | Health scores / verdicts / executive summary | Subjective assessment, belongs to the archived report only |
| I4 | All 6 P0 findings | Already tracked in Phase 0 audit (`AUDIT_SUMMARY.md`) and are follow-up work, not documentation |
| I5 | Count-drift observations (schema 392 vs 430, backend 17 vs 18 `.py`, bundle 77 vs 78, docs 97 vs 85) | Point-in-time measurements, already superseded by the corrected as-built facts above |
| I6 | Individual broken cross-references and leaked tool artifacts | Repairs, listed as follow-up tasks below |

## Archived items

| # | Item | Location |
|---|---|---|
| A1 | Full engineering review report (656 lines) | `documentation_build/archive/process_reports/ENGINEERING_REVIEW_REPORT.md` (copy verified via SHA-256 before removal) |
| A2 | Temp copy at repo root | Deleted after archive hash match (`E5C4B86E…`) |

## Follow-up tasks

| # | Task | Source | Priority |
|---|---|---|---|
| F1 | Correct `documentation_build/00_core/PROJECT_TIMELINE.md` (fabricated 12-month history) to match `CHANGELOG.md`/git | Report §4.1 | High |
| F2 | Remove leaked `</arg_value>/<task_progress>` tool artifacts from `AI_PROJECT_MEMORY.md`, `PROJECT_TIMELINE.md`, `GAP_ANALYSIS.md`, `SPRINT_2_BACKEND_BLUEPRINT.md` | Report §5.2.4 | High |
| F3 | Repair broken refs (≥8 docs → `12_exports/`, `13_claude_bundle/`, `02_diagrams/`, `00_engineering_audit/`) + fix `CLAUDE_PROMPT.md` + `generate_bundle.py` | Report §5.2.2 | High |
| F4 | Fix false "validation PASS" claims vs `CLEANUP_REPORT.md`'s honest "manual verification required" | Report §5.2.3 | Medium |
| F5 | Resolve staged `docs/05_reports/` deletion consciously; commit `documentation_build/` or delete it | Report §3.2 | High |
| F6 | Refresh stale `docs/README.md` + `docs/PROJECT_DOCUMENTATION_INDEX.md` (dead 05_reports links, `design_reference/`) | Report §5.2.6, §14.10 | Medium |
| F7 | Backend: pytest harness, verify/rotate Gemini key or default `ENABLE_FALLBACK=true`, fix CORS, add Alembic, pin requirements | Report §15 | High (Sprint 2 gate) |
| F8 | Frontend: auth tests, remove plaintext password path, type `ordersList`, bundle fonts | Report §14 | High |
| F9 | Move `backend/venv/` out of the tree; add Docker/CI (free GitHub Actions) | Report §15 | Medium |
| F10 | Reconcile dual sources of truth (`docs/07_rc1_certification/` vs `documentation_build/`) | Report §15.4 | Medium |
