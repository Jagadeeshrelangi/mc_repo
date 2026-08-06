# Documentation Audit — Phase 9 — Archive Strategy

> Pre-Sprint 2 Documentation Architecture Audit & Cleanup Sprint
> Date: 2026-08-05

---

## 1. Principle

Historical documentation must remain available but must not clutter active
documentation. **Nothing is deleted.** The archive is the project's history
shelf; active docs are the working set.

## 2. What Belongs in `archive/`

### 2.1 Already archived (43 files) — **keep as-is**

All stay. Sub-grouping for readability (optional improvement, not required):

| Group | Files | Notes |
|---|---|---|
| A. Legacy blueprints (7) | `AI_ARCHITECTURE`, `API_SPEC`, `DATABASE_SCHEMA`, `DESIGN_SYSTEM`, `PROJECT_ARCHITECTURE`, `SYSTEM_ARCHITECTURE`, `THIRD_PARTY_SERVICES` | Superseded by handbook + `02_architecture`; retain for history |
| B. Audit/hygiene/investigation (12) | `AUDIT_REPORT`, `MIGRATION_SUMMARY`, `OLDER_REPO_*`, `ONBOARDING_*`, `REPOSITORY_HEALTH_REPORT`, `VERIFICATION_REPORT`, `STARTUP_NAVIGATION_FIX_REPORT`, `MARKETPLACE_P0_RUNTIME_AUDIT_REPORT`, `SPRINT_D4_DELIVERABLES`, `SPRINT_D5_HYGIENE_*` | Evidence shelf |
| C. Sprint reports (8) | `SPRINT_1_1` … `SPRINT_1_7`, `SPRINT_1_UX_BLUEPRINT` | Historical snapshots |
| D. Sprint engineering notes (15) | `sprint-1.3-login` … `sprint-1.8.3-*`, `fuel-booking-*` | File:line traceability |
| E. Old handbook (1) | `MASTER_ENGINEERING_HANDBOOK_v1.0` | Superseded; contains reusable boilerplate — keep |

**Optional (not required):** create `archive/blueprints/`,
`archive/audits/`, `archive/sprints/`, `archive/notes/` subfolders so the
archive is navigable. Low risk, purely organizational.

### 2.2 New to archive (5 files from `05_reports/`)

| File | Why |
|---|---|
| `DOCUMENTATION_SPRINT_REPORT.md` | Records the *previous* docs reorg; superseded by this audit's reports |
| `SPRINT_1_7A_REPORT.md` | Completed sprint (Fuel Delivery foundation) |
| `SPRINT_1_9_AI_ASSISTANT_REPORT.md` | Completed sprint (AI Assistant) |
| `SPRINT_1_9A_PROFILE_REPORT.md` | Completed sprint (Profile) |
| `SPRINT_1_9B_FINAL_REVIEW_REPORT.md` | Completed review before RC1 |

These stay fully readable in `archive/` — nothing is lost.

## 3. What Stays Active (and why)

| Folder | Docs | Why active |
|---|---|---|
| `01_product/` | 6 docs | Living product/roadmap/risk docs |
| `02_architecture/` (new) | 5 frozen refs | Frozen technical reference for Sprint 2 implementation |
| `03_development/` | 5 docs | Operational: install/contribute/deploy/test/changelog |
| `04_release/` (new) | 9 docs | RC1 + future release/certification evidence |
| `05_reports/` | (empty after archive) | Reserved for current-sprint reports |
| `docs/README.md` + `MASTER_HANDBOOK.md` | landing + source of truth | Always active |

## 4. Rules Going Forward (add to `CONTRIBUTING.md`)

1. A completed sprint's report is **archived** within one sprint.
2. `05_reports/` holds only reports for the current/ongoing sprint.
3. No active document links into `archive/` (exceptions: CHANGELOG history
   entries, which are a log).
4. Never delete history; supersede, then archive.

## 5. Migration Safety

- All 5 moves are `git mv` (history preserved).
- Links to these 5 reports exist as plain text in `PROJECT_STATUS_REPORT.md`
  and `CHANGELOG.md` → update those paths (or leave CHANGELOG as a log record).
- The link-audit script is re-run after migration to confirm 0 broken links.
