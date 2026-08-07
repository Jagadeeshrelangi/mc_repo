# Documentation Audit — Phase 2 — Duplication Analysis

> Pre-Sprint 2 Documentation Architecture Audit & Cleanup Sprint
> Date: 2026-08-05

For each duplication cluster: **Source** → **Better canonical document** →
**Action**.

---

## Cluster 1 — System Architecture

| Source | Canonical | Action |
|---|---|---|
| `archive/SYSTEM_ARCHITECTURE.md` (layer diagrams, mock layer) | `MECHA_CONNECT_MASTER_HANDBOOK.md` ch8 + `FRONTEND_ARCHITECTURE.md` | Already archived — keep |
| `archive/PROJECT_ARCHITECTURE.md` (vision, architecture, standards) | Handbook ch1–13 | Already archived — keep |
| `CONTRIBUTING.md` §"Architecture Overview" (mini-architecture) | Handbook ch8 + `FRONTEND_ARCHITECTURE.md` | Trim to 3 bullet principles + link |
| `DEPLOYMENT.md` §4 config-service mermaid diagram | (unique config wiring) | **Keep** — only place config flow is described; add link to handbook ch9 |
| `SPRINT_1_7A/1_9/1_9A_REPORT` embedded module trees | Handbook ch10 + `FRONTEND_ARCHITECTURE.md` | Keep as historical snapshots (they are archived after Phase 9) |

## Cluster 2 — Testing

| Source | Canonical | Action |
|---|---|---|
| `TEST_PLAN.md` coverage *targets* (90/85/70/100%) | `TEST_PLAN.md` (strategy) | Keep — no change |
| `QA_CERTIFICATION_REPORT.md` executed evidence (162/162) | `QA_CERTIFICATION_REPORT.md` | **Canonical evidence** — keep |
| Handbook ch16 (testing summary) | Handbook ch16 | Link to `TEST_PLAN.md` + `QA_CERTIFICATION_REPORT.md` |
| `CHANGELOG.md` test counts per release | `CHANGELOG.md` (log) | Keep — historical log entries; do not remove |
| `SPRINT_1_9/1_9A/1_9B` reports test counts (25/25, 30/30, 159, 162) | `QA_CERTIFICATION_REPORT.md` | Historical snapshots — keep archived |

## Cluster 3 — Sprint History

| Source | Canonical | Action |
|---|---|---|
| Handbook ch17 (Sprint History) | Handbook ch17 | **Canonical history** — single source |
| `CHANGELOG.md` version-by-version history | `CHANGELOG.md` (chronological log) | Keep — log is a record, not a narrative |
| `ROADMAP.md` Sprint 1 module table | Handbook ch17 | Replace table with link to ch17; keep Sprint 2–5 future tables |
| `PROJECT_STATUS.md` "Overall Progress" + module completion | Handbook ch17 | Replace narrative with link to ch17 + keep module status |
| `PROJECT_STATUS_REPORT.md` §3 sprint table | Handbook ch17 | Replace with link to ch17 (keep RC1 release rows) |
| `SPRINT_1_7A/1_9/1_9A` reports | Handbook ch17 | Historical — keep archived |

## Cluster 4 — API Contract

| Source | Canonical | Action |
|---|---|---|
| `archive/API_SPEC.md` (draft REST endpoints) | `API_CONTRACT.md` + Handbook ch15 | Already archived — keep |
| Handbook ch15 (API Contract) | Handbook ch15 | Summarize + link to `API_CONTRACT.md` |
| `FEATURE_SPECIFICATIONS.md` §10 Backend Integration (FastAPI/PostgreSQL/Redis) | `API_CONTRACT.md` + `DATABASE_BLUEPRINT.md` | Trim to 2 lines + link |
| `ROADMAP.md` Sprint 2 (FastAPI, PostgreSQL, Firebase Auth) | Handbook ch9/ch15 | Trim to 2 lines + link |

## Cluster 5 — Database

| Source | Canonical | Action |
|---|---|---|
| `archive/DATABASE_SCHEMA.md` (ER, indexes, migrations) | `DATABASE_BLUEPRINT.md` + Handbook ch14 | Already archived — keep |
| Handbook ch14 (DB Blueprint) | Handbook ch14 | Summarize + link to `DATABASE_BLUEPRINT.md` |

## Cluster 6 — Tech Stack / Dependencies

| Source | Canonical | Action |
|---|---|---|
| Handbook ch9 (Technology Stack) | Handbook ch9 | **Canonical stack list** (exact dependency versions) |
| `BUSINESS_MODEL.md` cost-table stack | Handbook ch9 | Remove stack names from cost table; keep only cost logic |
| `RISK_ANALYSIS.md` §4 Dependency Risks | Handbook ch9 + `LICENSE_GUIDE.md` | Keep risk framing, drop re-listing of stack |
| `CONTRIBUTING.md` prerequisites | Handbook ch9 | Keep minimal (Flutter/Dart/Python/Git) |
| `DEPLOYMENT.md` §1 build requirements | Handbook ch9 | Keep build-specific constraints (minSdk, SDK targets) |
| `INSTALLATION.md` prerequisites | Handbook ch9 | Keep — installation is operational |
| `FEATURE_SPECIFICATIONS.md` §10 | Handbook ch9 | Trim + link |

## Cluster 7 — App Overview / Pitch

| Source | Canonical | Action |
|---|---|---|
| `PRODUCT_REQUIREMENTS_DOCUMENT.md` §1 Product Vision | `PRODUCT_REQUIREMENTS_DOCUMENT.md` | **Only place** the full pitch exists — keep single |
| Handbook ch1–5 (exec summary, vision, solution) | Handbook ch1–5 | Book-level narrative; link to PRD, do not expand |
| Root `README.md` pitch (corrupted) | PRD + Handbook ch1 | Rewrite README to 4-line summary + links |

## Cluster 8 — Release Information

| Source | Canonical | Action |
|---|---|---|
| `CHANGELOG.md` (full dev history) | `CHANGELOG.md` | **Canonical detailed log** |
| `VERSION_HISTORY.md` (release-level summary) | `CHANGELOG.md` | Keep as recruiters/investors summary; add link to CHANGELOG |
| `RELEASE_NOTES_RC1.md` (what's in RC1 + how to run) | `RELEASE_NOTES_RC1.md` | Keep — release snapshot |
| `RC1_CHECKLIST.md` (gates + tag commands) | `RC1_CHECKLIST.md` | Keep — operational |
| `RC1_RELEASE_REPORT.md` | `RC1_RELEASE_REPORT.md` | Keep — release record |
| `QA_CERTIFICATION_REPORT.md` + `FRONTEND_LOCK_REPORT.md` | These | Keep — certification evidence pair |
| `PROJECT_STATUS_REPORT.md` (status/next-steps/risks) | `PROJECT_STATUS_REPORT.md` | Keep — release status |

## Cluster 9 — Status Dashboards (two docs)

| Source | Canonical | Action |
|---|---|---|
| `01_product/PROJECT_STATUS.md` (product progress, per-module) | `PROJECT_STATUS_REPORT.md` (release status) | Distinct roles: **product** vs **release**. Keep both; each links to Handbook ch17 instead of duplicating sprint tables |

## Cluster 10 — Design System

| Source | Canonical | Action |
|---|---|---|
| `archive/DESIGN_SYSTEM.md` (original tokens) | `UI_DESIGN_SYSTEM.md` + Handbook ch13 | Already archived — keep |
| `FEATURE_SPECIFICATIONS.md` acceptance referencing UI | `UI_DESIGN_SYSTEM.md` | Keep — cross-reference is correct |

---

## Summary

| Cluster | Duplication severity | Primary action |
|---|---|---|
| Architecture | Medium | Repoint CONTRIBUTING/DEPLOYMENT to handbook |
| Testing | Low | Canonical evidence already exists |
| Sprint history | **High** | Centralize in Handbook ch17; link others |
| API | Medium | Trim FEATURE_SPEC/ROADMAP repetitions |
| Database | Low | Handbook links to blueprint |
| Tech stack | **High** | Centralize in Handbook ch9 |
| App overview | Low | Already single (PRD) |
| Release info | Low | Roles already distinct |
| Status dashboards | Medium | Keep both, dedupe sprint tables |
| Design system | Low | Already canonical |

**Biggest cleanup wins:** Handbook ch9 (tech stack) and ch17 (sprint history)
as single sources, plus trimming the 4 active docs that still point into
`archive/`.
