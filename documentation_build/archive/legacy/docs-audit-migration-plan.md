# Documentation Audit — Phase 10 — Documentation Migration Plan

> Pre-Sprint 2 Documentation Architecture Audit & Cleanup Sprint
> Date: 2026-08-05

Every document: **Current location** → **New location** → **Action**.

Legend: **Move** = `git mv` into new folder · **Rename** = new filename ·
**Archive** = move into `archive/` · **Keep** = unchanged location · **Rewrite**
= content regeneration · **Merge** = fold into another doc.

---

## 1. Handbook & Navigation

| Current | New | Action |
|---|---|---|
| `docs/07_rc1_certification/MECHA_CONNECT_MASTER_HANDBOOK.md` | `docs/MASTER_HANDBOOK.md` | Move + Rename |
| `docs/07_rc1_certification/MECHA_CONNECT_MASTER_HANDBOOK.pdf` | `docs/assets/master-handbook.pdf` | Move + Rename |
| `docs/07_rc1_certification/MECHA_CONNECT_MASTER_HANDBOOK.docx` | `docs/assets/master-handbook.docx` | Move + Rename |
| `docs/README.md` | `docs/README.md` | Keep + update (remove `design_reference/`, add new tree) |
| `docs/PROJECT_DOCUMENTATION_INDEX.md` | `docs/README.md` | Merge (absorb tables into README) |
| `README.md` (root) | `README.md` (root) | **Rewrite** (corrupted encoding, stale structure/versions) |

## 2. `01_product/` → `01_product/` (rename only)

| Current | New | Action |
|---|---|---|
| `PRODUCT_REQUIREMENTS_DOCUMENT.md` | `product-requirements.md` | Rename |
| `FEATURE_SPECIFICATIONS.md` | `feature-specifications.md` | Rename |
| `BUSINESS_MODEL.md` | `business-model.md` | Rename |
| `PROJECT_STATUS.md` | `product-status.md` | Rename (disambiguate) |
| `ROADMAP.md` | `roadmap.md` | Rename |
| `RISK_ANALYSIS.md` | `risk-analysis.md` | Rename + repoint archive link |

## 3. `07_rc1_certification/` architecture half → new `02_architecture/`

| Current | New | Action |
|---|---|---|
| `FRONTEND_ARCHITECTURE.md` | `02_architecture/frontend-architecture.md` | Move + Rename |
| `NAVIGATION_MAP.md` | `02_architecture/navigation-map.md` | Move + Rename |
| `UI_DESIGN_SYSTEM.md` | `02_architecture/ui-design-system.md` | Move + Rename |
| `DATABASE_BLUEPRINT.md` | `02_architecture/database-blueprint.md` | Move + Rename |
| `API_CONTRACT.md` | `02_architecture/api-contract.md` | Move + Rename |

## 4. `07_rc1_certification/` release half → new `04_release/`

| Current | New | Action |
|---|---|---|
| `FRONTEND_LOCK_REPORT.md` | `04_release/frontend-lock-report.md` | Move + Rename |
| `QA_CERTIFICATION_REPORT.md` | `04_release/qa-certification-report.md` | Move + Rename |
| `PROJECT_STATUS_REPORT.md` | `04_release/release-status.md` | Move + Rename + trim §3 (link Handbook ch17) |
| `RELEASE_NOTES_RC1.md` | `04_release/release-notes-rc1.md` | Move + Rename |
| `RC1_CHECKLIST.md` | `04_release/rc1-checklist.md` | Move + Rename |
| `VERSION_HISTORY.md` | `04_release/version-history.md` | Move + Rename + link CHANGELOG |
| `LICENSE_GUIDE.md` | `04_release/license-guide.md` | Move + Rename |
| `COPYRIGHT_NOTICE.md` | `04_release/copyright-notice.md` | Move + Rename |
| `RC1_RELEASE_REPORT.md` | `04_release/rc1-release-report.md` | Move + Rename |

## 5. `03_development/` (rename only)

| Current | New | Action |
|---|---|---|
| `INSTALLATION.md` | `installation.md` | Rename |
| `CONTRIBUTING.md` | `contributing.md` | Rename + repoint archive link + add archive rules |
| `DEPLOYMENT.md` | `deployment.md` | Rename + repoint archive link |
| `TEST_PLAN.md` | `test-plan.md` | Rename |
| `CHANGELOG.md` | `changelog.md` | Rename (log entries referencing old paths stay) |

## 6. `05_reports/` → archive (5 moves) + this audit's reports

| Current | New | Action |
|---|---|---|
| `DOCUMENTATION_SPRINT_REPORT.md` | `archive/DOCUMENTATION_SPRINT_REPORT.md` | Archive |
| `SPRINT_1_7A_REPORT.md` | `archive/SPRINT_1_7A_REPORT.md` | Archive |
| `SPRINT_1_9_AI_ASSISTANT_REPORT.md` | `archive/SPRINT_1_9_AI_ASSISTANT_REPORT.md` | Archive |
| `SPRINT_1_9A_PROFILE_REPORT.md` | `archive/SPRINT_1_9A_PROFILE_REPORT.md` | Archive |
| `SPRINT_1_9B_FINAL_REVIEW_REPORT.md` | `archive/SPRINT_1_9B_FINAL_REVIEW_REPORT.md` | Archive |
| *(new)* 7 audit reports | `docs/05_reports/docs-audit-*.md` | **Keep** (this sprint's current report set) |

## 7. `source/` → `assets/` (12 files)

| Current | New | Action |
|---|---|---|
| `docs/source/*` | `docs/assets/*` | Move (folder rename; contents unchanged) |

## 8. `archive/` (43 files)

| Action | Detail |
|---|---|
| Keep | All 43 remain; no deletions |
| Optional | Subfolders `blueprints/`, `audits/`, `sprints/`, `notes/` for navigability |

---

## 9. Link Repair (executed during migration)

| # | Repair |
|---|---|
| 1 | Repoint 4 active→archive links (RISK_ANALYSIS, ROADMAP, CONTRIBUTING, DEPLOYMENT) |
| 2 | Remove `design_reference/` mention from `docs/README.md` |
| 3 | Convert all plain-text `docs/...` paths to relative markdown links across active docs |
| 4 | Update paths in `PROJECT_STATUS_REPORT.md` (§6) and `CHANGELOG.md` current-path mentions |
| 5 | Add Handbook ch refs to headers of `02_architecture` + `04_release` docs |
| 6 | Add `Canonical overview → MASTER_HANDBOOK.md ch X` cross-links |

## 10. Post-Migration Verification

1. Re-run link audit → **0 broken, 0 active→archive** links.
2. `flutter analyze` + `flutter test` unchanged (no code touched) — 162/162.
3. Regenerate handbook PDF/DOCX only if the Markdown source changed (it does
   not in this migration).
4. Update `docs/README.md` folder tree + metrics; update root `README.md`.
5. Commit sequence (separate, reviewable commits):
   - `docs: reorganize doc tree (product/architecture/release/assets)`
   - `docs: archive completed sprint reports`
   - `docs: rename docs to kebab-case convention`
   - `docs: rewrite root README and merge doc index`
   - `docs: repoint cross-references and add handbook links`

---

## 11. Explicitly NOT Included (deferred / out of scope)

| Item | Why |
|---|---|
| Handbook dedupe edit pass (ch8–15 vs detail docs) | Content change; separate maintenance sprint |
| Content rewrites of product/dev docs | Audit is organizational, not editorial |
| Delete any document | Rules forbid information loss |
| Backend docs | No backend documentation exists yet — Sprint 2 will add it |

---

# Phase 11 — Approval Gate

**STOP. No files have been moved, renamed, deleted, or rewritten.**

This migration plan is awaiting approval. After approval, the executor will:
move/rename files (`git mv`), archive the 5 sprint reports, repoint links,
merge the index, rewrite the root README, regenerate the folder tree, update
metrics, and commit in the sequence above.

**Requested decision:** approve the migration as scoped, or request changes
(e.g. keep numbered-named files, different folder names, keep
`PROJECT_DOCUMENTATION_INDEX.md` separate, or defer the root-README rewrite).
