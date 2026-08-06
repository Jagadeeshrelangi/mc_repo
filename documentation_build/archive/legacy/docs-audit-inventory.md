# Documentation Audit — Phase 1 & 3 — Inventory & Classification

> Pre-Sprint 2 Documentation Architecture Audit & Cleanup Sprint
> Date: 2026-08-05 · Scope: entire `docs/` tree + root `README.md`
> Method: full file walk, per-file content read, mechanical link scan

---

## 1. Scope

All **77** Markdown documents in the repository:

| Area | Count |
|---|---|
| Active docs (`docs/01_product`, `03_development`, `05_reports`, `07_rc1_certification`) | 32 |
| Docs navigation (`docs/README.md`, `docs/PROJECT_DOCUMENTATION_INDEX.md`) | 2 |
| Root `README.md` | 1 |
| `docs/archive/` | 43 |
| **Total** | **78 markdown files** (77 inside `docs/` + root README) |

Plus non-Markdown assets in `docs/source/` (12 files) and generated renders
(`MECHA_CONNECT_MASTER_HANDBOOK.pdf` / `.docx`).

---

## 2. Classification Labels (Phase 3)

| Label | Meaning |
|---|---|
| **Canonical** | Official, maintained document. Lives in active documentation. |
| **Supporting** | Useful but secondary. Referenced by canonical docs. |
| **Historical** | Old sprint reports, audits, investigations. Move to archive. |
| **Generated** | Auto-generated output (e.g. PDF/DOCX renders). Regenerable. |
| **Obsolete** | No unique information. Safe to remove AFTER approval. |

No document was deleted during this audit. **Nothing has been moved.**

---

## 3. Active Documents — Inventory

| File | Purpose | Status header | Class | Recommendation |
|---|---|------|---|---|
| `01_product/PRODUCT_REQUIREMENTS_DOCUMENT.md` | Vision, problem, personas, market, MVP scope, success metrics | Draft | **Canonical** | Keep → rename `product-requirements.md` |
| `01_product/FEATURE_SPECIFICATIONS.md` | Per-feature spec: priority, states, files, acceptance | Locked | **Canonical** | Keep → rename `feature-specifications.md` |
| `01_product/BUSINESS_MODEL.md` | Revenue, cost, unit economics, growth, KPIs | Draft | **Canonical** | Keep → rename `business-model.md` |
| `01_product/PROJECT_STATUS.md` | Product-level module progress + quality metrics | none | **Supporting** | Keep; dedupe sprint history → handbook ch17 |
| `01_product/ROADMAP.md` | Sprint-by-sprint roadmap + milestones | Living | **Canonical** | Keep → rename `roadmap.md` |
| `01_product/RISK_ANALYSIS.md` | Risk matrix, risk/TD registers, dependency risks | Draft | **Canonical** | Keep → rename `risk-analysis.md`; repoint link |
| `03_development/INSTALLATION.md` | Backend + Flutter local setup | none | **Canonical** | Keep → rename `installation.md` |
| `03_development/CONTRIBUTING.md` | Setup, standards, sprint workflow, quality gates | Active | **Canonical** | Keep → rename `contributing.md`; repoint link |
| `03_development/DEPLOYMENT.md` | Build, release checklist, env config, CI/CD, versioning | Draft | **Canonical** | Keep → rename `deployment.md`; repoint link |
| `03_development/TEST_PLAN.md` | Testing strategy, coverage targets, acceptance | Draft | **Canonical** | Keep → rename `test-plan.md` |
| `03_development/CHANGELOG.md` | Version history 0.0.1 → 1.9.3 | none | **Canonical** | Keep → rename `changelog.md` |
| `05_reports/DOCUMENTATION_SPRINT_REPORT.md` | Prior docs-reorg sprint report (now superseded by this audit) | none | **Historical** | Archive |
| `05_reports/SPRINT_1_7A_REPORT.md` | Fuel Delivery foundation + GPS fix report | Complete | **Historical** | Archive |
| `05_reports/SPRINT_1_9_AI_ASSISTANT_REPORT.md` | AI Assistant module report | Complete | **Historical** | Archive |
| `05_reports/SPRINT_1_9A_PROFILE_REPORT.md` | Profile module report | Complete | **Historical** | Archive |
| `05_reports/SPRINT_1_9B_FINAL_REVIEW_REPORT.md` | Final frontend review report | Complete | **Historical** | Archive |
| `07_rc1_certification/MECHA_CONNECT_MASTER_HANDBOOK.md` | Master handbook — the 21-chapter book (single source of truth) | frozen | **Canonical** | Move to `docs/` root → `MASTER_HANDBOOK.md` |
| `07_rc1_certification/FRONTEND_ARCHITECTURE.md` | Provider graph, module tree, seams | frozen | **Canonical** | Move → `02_architecture/` |
| `07_rc1_certification/NAVIGATION_MAP.md` | 5-tab shell + flow maps | frozen | **Canonical** | Move → `02_architecture/` |
| `07_rc1_certification/UI_DESIGN_SYSTEM.md` | Frozen design tokens & patterns | frozen | **Canonical** | Move → `02_architecture/` |
| `07_rc1_certification/DATABASE_BLUEPRINT.md` | PostgreSQL schema blueprint | frozen | **Canonical** | Move → `02_architecture/` |
| `07_rc1_certification/API_CONTRACT.md` | Frozen mock API contract | frozen | **Canonical** | Move → `02_architecture/` |
| `07_rc1_certification/FRONTEND_LOCK_REPORT.md` | Freeze list + governance | frozen | **Canonical** | Move → `04_release/` |
| `07_rc1_certification/QA_CERTIFICATION_REPORT.md` | Certification evidence (162/162) | frozen | **Canonical** | Move → `04_release/` |
| `07_rc1_certification/PROJECT_STATUS_REPORT.md` | Release status, next steps, risks | frozen | **Canonical** | Move → `04_release/` |
| `07_rc1_certification/RELEASE_NOTES_RC1.md` | RC1 release notes | frozen | **Canonical** | Move → `04_release/` |
| `07_rc1_certification/RC1_CHECKLIST.md` | Release gates + tag commands | frozen | **Canonical** | Move → `04_release/` |
| `07_rc1_certification/VERSION_HISTORY.md` | Release-level version summary | frozen | **Canonical** | Move → `04_release/` |
| `07_rc1_certification/LICENSE_GUIDE.md` | Project + dependency licensing | frozen | **Canonical** | Move → `04_release/` |
| `07_rc1_certification/COPYRIGHT_NOTICE.md` | Copyright & confidentiality | frozen | **Canonical** | Move → `04_release/` |
| `07_rc1_certification/RC1_RELEASE_REPORT.md` | Full RC1 release report | frozen | **Canonical** | Move → `04_release/` |
| `docs/README.md` | Docs landing page | — | **Canonical** | Keep; remove stale `design_reference/` ref |
| `docs/PROJECT_DOCUMENTATION_INDEX.md` | Master navigation index | — | **Supporting** | Merge into `README.md` (one entry point) |
| `README.md` (repo root) | Repo landing page | — | **Supporting** | **Rewrite** — corrupted encoding + stale structure |
| `07_rc1_certification/MECHA_CONNECT_MASTER_HANDBOOK.pdf` | Handbook PDF render | generated | **Generated** | Move → `assets/` |
| `07_rc1_certification/MECHA_CONNECT_MASTER_HANDBOOK.docx` | Handbook DOCX render | generated | **Generated** | Move → `assets/` |

---

## 4. Archived Documents — Inventory (grouped)

All **43** files in `docs/archive/` are classified **Historical** (superseded or
historical evidence) and **none are proposed for deletion** — history is
preserved. Rows show the unique value that justifies keeping them.

### 4A. Legacy blueprints (7)

| File | Unique value | Superseded by |
|---|---|---|
| `AI_ARCHITECTURE.md` | Intent→endpoint mapping; local-inference plan | Handbook ch10; `SPRINT_1_9_AI_ASSISTANT_REPORT` |
| `API_SPEC.md` | Draft Sprint-2 endpoint set (pre-implementation) | `API_CONTRACT.md` |
| `DATABASE_SCHEMA.md` | Original ER design + migration plan | `DATABASE_BLUEPRINT.md` |
| `DESIGN_SYSTEM.md` | Original brand tokens + component inventory | `UI_DESIGN_SYSTEM.md` |
| `PROJECT_ARCHITECTURE.md` | Former "single source of truth"; full nav tree | Handbook; `NAVIGATION_MAP.md` |
| `SYSTEM_ARCHITECTURE.md` | Original layer diagrams incl. mock layer | Handbook ch8; `FRONTEND_ARCHITECTURE.md` |
| `THIRD_PARTY_SERVICES.md` | Service/API-key/quota inventory (draft) | `LICENSE_GUIDE.md`; Handbook |

### 4B. Audit & hygiene reports (12)

| File | Unique value |
|---|---|
| `AUDIT_REPORT.md` | Pre-RC1 repo audit matrices + verdict |
| `MIGRATION_SUMMARY.md` | Docs restructure decisions (CM1–CM9) |
| `OLDER_REPO_INVESTIGATION_REPORT.md` | Fork comparison conclusion (no recoverable onboarding code) |
| `ONBOARDING_INVESTIGATION_REPORT.md` | Commit-by-commit onboarding search |
| `ONBOARDING_RECOVERY_REPORT.md` | Definitive closure: premium onboarding never existed |
| `REPOSITORY_HEALTH_REPORT.md` | 10-dimension health scorecard baseline |
| `VERIFICATION_REPORT.md` | Doc-vs-code verification evidence (82/100) |
| `STARTUP_NAVIGATION_FIX_REPORT.md` | Startup nav fix before/after |
| `MARKETPLACE_P0_RUNTIME_AUDIT_REPORT.md` | BoxConstraints root-cause evidence |
| `SPRINT_D4_DELIVERABLES.md` | Docs-split deleted-file list |
| `SPRINT_D5_HYGIENE_AUDIT.md` | Pre-hygiene file-action matrix |
| `SPRINT_D5_HYGIENE_REPORT.md` | Hygiene cleanup execution evidence |

### 4C. Sprint reports (8)

`SPRINT_1_1` … `SPRINT_1_7` (splash, onboarding, auth, home, polish, mechanic,
fuel), `SPRINT_1_UX_BLUEPRINT` (81-screen UX plan). Each is a historical
snapshot with per-sprint QA numbers and root-cause details.

### 4D. Sprint engineering notes (15)

`sprint-1.3-login` … `sprint-1.8.3-production-stabilization` +
`fuel-booking-step3-cta-regression-fix`. File:line traceability, state-machine
designs, bug root causes, per-module test results.

### 4E. Old handbook (1)

`MASTER_ENGINEERING_HANDBOOK_v1.0.md` (8,902 lines) — superseded by the new
21-chapter handbook. Contains reusable boilerplate (templates, checklists,
mermaid diagram library) — keep archived; do not delete.

---

## 5. Generated Assets (docs/source)

| File | Class | Recommendation |
|---|---|---|
| 4 onboarding PNGs, video, PRD PDF, deck PPTX, abstract PDF, workflow DOCX, UI blueprint HTML | **Generated / Source** | Keep → rename folder `source/` → `assets/` |

---

## 6. Summary Counts

| Class | Count |
|---|---|
| Canonical (active, to keep) | 24 |
| Supporting (to keep/merge) | 3 |
| Historical (in `05_reports`, to archive) | 5 |
| Historical (already archived) | 43 |
| Generated (PDF/DOCX + source assets) | 14 |
| Obsolete (deletion proposed) | **0** |

**Key findings**
1. Zero documents proposed for deletion — history is fully preserved.
2. The five `05_reports/` files are all completed-sprint reports → historical.
3. `07_rc1_certification/` mixes two concerns (architecture vs release) → split.
4. Root `README.md` is corrupted and stale → rewrite required.

*See companion reports: `docs-audit-duplication.md`, `docs-audit-structure.md`,
`docs-audit-crosslinks.md`, `docs-audit-handbook.md`, `docs-audit-archive-plan.md`,
`docs-audit-migration-plan.md`.*
