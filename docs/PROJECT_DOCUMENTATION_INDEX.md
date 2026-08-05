# Mecha Connect — Project Documentation Index

> Master navigation for the Mecha Connect documentation set.
> Version: 1.9.1 (Frontend Lock Candidate) · Last updated: 2026-08-05

---

## Product

| Document | Description |
|---|---|
| [01_product/PRODUCT_REQUIREMENTS_DOCUMENT.md](01_product/PRODUCT_REQUIREMENTS_DOCUMENT.md) | Vision, personas, market analysis, MVP scope |
| [01_product/FEATURE_SPECIFICATIONS.md](01_product/FEATURE_SPECIFICATIONS.md) | Per-feature spec with states, priorities, files |
| [01_product/BUSINESS_MODEL.md](01_product/BUSINESS_MODEL.md) | Revenue model, unit economics, growth strategy |
| [01_product/PROJECT_STATUS.md](01_product/PROJECT_STATUS.md) | Overall progress dashboard, quality metrics |
| [01_product/ROADMAP.md](01_product/ROADMAP.md) | Sprint-by-sprint timeline, milestones |
| [01_product/RISK_ANALYSIS.md](01_product/RISK_ANALYSIS.md) | Risk register, tech debt, dependency risks |

## Architecture (frontend canonical)

| Document | Description |
|---|---|
| [07_rc1_certification/MECHA_CONNECT_MASTER_HANDBOOK.md](07_rc1_certification/MECHA_CONNECT_MASTER_HANDBOOK.md) | Master engineering handbook (v2.0.0) — architecture, standards, governance |
| [07_rc1_certification/FRONTEND_ARCHITECTURE.md](07_rc1_certification/FRONTEND_ARCHITECTURE.md) | Provider graph, module tree, integration seams |
| [07_rc1_certification/NAVIGATION_MAP.md](07_rc1_certification/NAVIGATION_MAP.md) | 5-tab shell + all flow maps |
| [07_rc1_certification/UI_DESIGN_SYSTEM.md](07_rc1_certification/UI_DESIGN_SYSTEM.md) | Frozen design tokens & patterns |
| [07_rc1_certification/DATABASE_BLUEPRINT.md](07_rc1_certification/DATABASE_BLUEPRINT.md) | PostgreSQL schema blueprint |

## Development

| Document | Description |
|---|---|
| [03_development/INSTALLATION.md](03_development/INSTALLATION.md) | Local dev setup for backend + Flutter |
| [03_development/CONTRIBUTING.md](03_development/CONTRIBUTING.md) | Git workflow, coding standards, PR process |
| [03_development/TEST_PLAN.md](03_development/TEST_PLAN.md) | Test strategy, coverage targets, acceptance criteria |
| [03_development/DEPLOYMENT.md](03_development/DEPLOYMENT.md) | Build pipelines, CI/CD, release checklist |
| [03_development/CHANGELOG.md](03_development/CHANGELOG.md) | Version history |

## Frontend Certification

| Document | Description |
|---|---|
| [07_rc1_certification/FRONTEND_LOCK_REPORT.md](07_rc1_certification/FRONTEND_LOCK_REPORT.md) | Freeze list, governance, change log |
| [07_rc1_certification/QA_CERTIFICATION_REPORT.md](07_rc1_certification/QA_CERTIFICATION_REPORT.md) | Certification evidence (162/162 tests) |
| [07_rc1_certification/PROJECT_STATUS_REPORT.md](07_rc1_certification/PROJECT_STATUS_REPORT.md) | Frontend Lock status, next steps, risks |
| [07_rc1_certification/API_CONTRACT.md](07_rc1_certification/API_CONTRACT.md) | Frozen API contract (Sprint 2 spec) |

## Reports (active)

| Document | Description |
|---|---|
| [05_reports/SPRINT_1_7A_REPORT.md](05_reports/SPRINT_1_7A_REPORT.md) | Sprint 1.7A — Fuel Delivery foundation |
| [05_reports/SPRINT_1_9_AI_ASSISTANT_REPORT.md](05_reports/SPRINT_1_9_AI_ASSISTANT_REPORT.md) | Sprint 1.9 — AI Assistant |
| [05_reports/SPRINT_1_9A_PROFILE_REPORT.md](05_reports/SPRINT_1_9A_PROFILE_REPORT.md) | Sprint 1.9A — Profile module |
| [05_reports/DOCUMENTATION_SPRINT_REPORT.md](05_reports/DOCUMENTATION_SPRINT_REPORT.md) | This documentation reorganization sprint |

## Archive

Historical documents preserved for reference:

- **Legacy architecture:** AI_ARCHITECTURE, DATABASE_SCHEMA, DESIGN_SYSTEM,
  PROJECT_ARCHITECTURE, SYSTEM_ARCHITECTURE
- **Legacy API draft:** API_SPEC
- **Sprint reports:** SPRINT_1_1 → SPRINT_1_7
- **Legacy QA/hygiene reports:** AUDIT_REPORT, VERIFICATION_REPORT,
  MIGRATION_SUMMARY, REPOSITORY_HEALTH_REPORT, SPRINT_D4_DELIVERABLES,
  SPRINT_D5_HYGIENE_AUDIT, SPRINT_D5_HYGIENE_REPORT,
  OLDER_REPO_INVESTIGATION_REPORT, ONBOARDING_INVESTIGATION_REPORT,
  ONBOARDING_RECOVERY_REPORT, STARTUP_NAVIGATION_FIX_REPORT,
  MARKETPLACE_P0_RUNTIME_AUDIT_REPORT, SPRINT_1_UX_BLUEPRINT,
  THIRD_PARTY_SERVICES, MASTER_ENGINEERING_HANDBOOK_v1.0
- **Engineering notes:** sprint-1.3-login → sprint-1.8.3-production-stabilization
  and fuel-booking-step3-cta-regression-fix

All archived items: [`archive/`](archive/)

## Source Assets

| Folder | Contents |
|---|---|
| [`source/`](source/) | PRD PDFs, presentation deck, development workflow, demo video, onboarding images, UI blueprint (HTML) |

---

## Reading Order

For a new developer, QA engineer, backend engineer, or investor:

1. README → `README.md`
2. Master handbook → `07_rc1_certification/MECHA_CONNECT_MASTER_HANDBOOK.md`
3. Lock report → `07_rc1_certification/FRONTEND_LOCK_REPORT.md`
4. Architecture → `07_rc1_certification/FRONTEND_ARCHITECTURE.md`
5. API contract → `07_rc1_certification/API_CONTRACT.md`
6. QA evidence → `07_rc1_certification/QA_CERTIFICATION_REPORT.md`
7. Run locally → `03_development/INSTALLATION.md`

---

## Metrics (2026-08-05)

| Metric | Count |
|---|---|
| Active Markdown documents | 26 |
| Archived Markdown documents | 43 |
| Source assets (non-MD) | 12 |
| Folders created | 1 (`07_rc1_certification/`) |
| Folders removed | 4 (`02_architecture`, `04_sprints`, `06_reference`, `engineering`) |
