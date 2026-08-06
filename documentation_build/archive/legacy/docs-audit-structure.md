# Documentation Audit — Phase 4 & 5 — Folder Architecture & Naming Proposals

> Pre-Sprint 2 Documentation Architecture Audit & Cleanup Sprint
> Date: 2026-08-05

---

## 1. Current State

```
docs/
├── README.md
├── PROJECT_DOCUMENTATION_INDEX.md
├── 01_product/           6 md
├── 03_development/       5 md
├── 05_reports/           5 md  (all completed-sprint reports)
├── 07_rc1_certification/ 15 md + 2 generated renders
├── archive/              43 md
└── source/               12 assets
```

### Problems with the current structure

1. **`07_rc1_certification/` mixes two concerns** — frozen *architecture
   reference* docs sit beside *release/certification* docs. The folder name is
   sprint-specific (`rc1`) and will be misleading for Sprint 2, Sprint 3, etc.
2. **Two navigation docs** (`README.md` + `PROJECT_DOCUMENTATION_INDEX.md`)
   overlap heavily.
3. **`05_reports/` contains only historical, completed-sprint reports.**
4. **`source/` is a vague name** for assets; it also hosts generated renders.
5. **The Master Handbook is buried one folder deep** instead of being the
   top-level single source of truth.
6. **`docs/design_reference/` is referenced in `README.md` but does not exist.**

---

## 2. Proposed Target Structure

```
docs/
├── README.md                 # single landing + navigation index (merged)
├── MASTER_HANDBOOK.md        # THE single source of truth (21-chapter book)
│
├── 01_product/               # what & why — product
│   ├── product-requirements.md
│   ├── feature-specifications.md
│   ├── business-model.md
│   ├── roadmap.md
│   ├── risk-analysis.md
│   └── product-status.md
│
├── 02_architecture/          # frozen technical reference
│   ├── frontend-architecture.md
│   ├── navigation-map.md
│   ├── ui-design-system.md
│   ├── database-blueprint.md
│   └── api-contract.md
│
├── 03_development/           # how to work here
│   ├── installation.md
│   ├── contributing.md
│   ├── deployment.md
│   ├── test-plan.md
│   └── changelog.md
│
├── 04_release/               # releases & certification (RC1, later S2…)
│   ├── frontend-lock-report.md
│   ├── qa-certification-report.md
│   ├── release-status.md
│   ├── release-notes-rc1.md
│   ├── rc1-checklist.md
│   ├── version-history.md
│   ├── license-guide.md
│   ├── copyright-notice.md
│   └── rc1-release-report.md
│
├── 05_reports/               # ACTIVE sprint reports only (empty after archive)
│
├── assets/                   # (renamed from source/) + handbook PDF/DOCX
└── archive/                  # historical (unchanged)
```

**Rationale**

| Change | Why |
|---|---|
| `MASTER_HANDBOOK.md` at docs root | It is the single source of truth; elevation signals that |
| `01_product` | Kept — product concerns are distinct |
| New `02_architecture` | Frozen architecture refs leave `rc1` folder; sprint-agnostic name |
| `03_development` | Kept — operational docs |
| New `04_release` | Certification + release docs; future-proof for Sprint 2 releases |
| `05_reports` | Only current-sprint reports live here; completed ones go to archive |
| `source/` → `assets/` | Standard name; holds source assets AND generated renders |
| `README.md` absorbs index | One entry point |

---

## 3. Naming Convention Proposal

**Convention:** lowercase, kebab-case filenames. No all-caps, no sprint
prefixes on *active* documents. Sprint numbers only on *historical* reports in
`archive/`.

| Current | Proposed | Rule applied |
|---|---|---|
| `PRODUCT_REQUIREMENTS_DOCUMENT.md` | `product-requirements.md` | drop `_DOCUMENT`, kebab |
| `FEATURE_SPECIFICATIONS.md` | `feature-specifications.md` | lowercase |
| `BUSINESS_MODEL.md` | `business-model.md` | lowercase |
| `PROJECT_STATUS.md` | `product-status.md` | disambiguate from release status |
| `ROADMAP.md` | `roadmap.md` | lowercase |
| `RISK_ANALYSIS.md` | `risk-analysis.md` | lowercase |
| `INSTALLATION.md` | `installation.md` | lowercase |
| `CONTRIBUTING.md` | `contributing.md` | lowercase |
| `DEPLOYMENT.md` | `deployment.md` | lowercase |
| `TEST_PLAN.md` | `test-plan.md` | lowercase |
| `CHANGELOG.md` | `changelog.md` | lowercase |
| `MECHA_CONNECT_MASTER_HANDBOOK.md` | `MASTER_HANDBOOK.md` | short, top-level brand |
| `FRONTEND_ARCHITECTURE.md` | `frontend-architecture.md` | kebab |
| `NAVIGATION_MAP.md` | `navigation-map.md` | kebab |
| `UI_DESIGN_SYSTEM.md` | `ui-design-system.md` | kebab |
| `DATABASE_BLUEPRINT.md` | `database-blueprint.md` | kebab |
| `API_CONTRACT.md` | `api-contract.md` | kebab |
| `FRONTEND_LOCK_REPORT.md` | `frontend-lock-report.md` | kebab |
| `QA_CERTIFICATION_REPORT.md` | `qa-certification-report.md` | kebab |
| `PROJECT_STATUS_REPORT.md` | `release-status.md` | semantic name |
| `RELEASE_NOTES_RC1.md` | `release-notes-rc1.md` | kebab |
| `RC1_CHECKLIST.md` | `rc1-checklist.md` | kebab |
| `VERSION_HISTORY.md` | `version-history.md` | kebab |
| `LICENSE_GUIDE.md` | `license-guide.md` | kebab |
| `COPYRIGHT_NOTICE.md` | `copyright-notice.md` | kebab |
| `RC1_RELEASE_REPORT.md` | `rc1-release-report.md` | kebab |

**Archive convention (keep as-is):** sprint reports may keep their readable
sprint names (`SPRINT_1_7A_REPORT.md` → optionally
`sprint-1.7a-report.md`). Lowercase kebab recommended for consistency but
archive renames are low priority (see migration plan options).

**Document header convention (recommended):** every active document carries a
front-matter block — `Title · Version · Status · Owner · Last Updated ·
Related docs`. Enforce via a lint script (optional, Sprint 2 hygiene).

---

## 4. Effort Estimate

| Change | Effort |
|---|---|
| Create `02_architecture`, `04_release`, `assets`; move files | Low (git mv) |
| Rename 26 active files | Low (git mv) |
| Rewrite `README.md` (root, corrupted) | Medium |
| Merge `PROJECT_DOCUMENTATION_INDEX.md` → `README.md` | Low |
| Repoint 4 archive links + plain-text `docs/...` paths | Medium |
| Handbook duplicate-trim (ch9/ch17 vs others) | Medium (optional, later pass) |

No Flutter, backend, or UI code is touched.
