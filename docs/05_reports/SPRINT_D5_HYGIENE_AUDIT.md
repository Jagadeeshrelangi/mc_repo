# Sprint D5 — Repository Hygiene & Governance Audit

**Date:** 2026-07-29
**Scope:** Entire repository (docs, lib, backend, assets, test, root)

---

## Deliverables Index

1. [Repository Inventory](#1-repository-inventory)
2. [Documentation Classification Matrix](#2-documentation-classification-matrix)
3. [Duplicate Detection Report](#3-duplicate-detection-report)
4. [File Action Matrix](#4-file-action-matrix)
5. [Obsolete Files Report](#5-obsolete-files-report)
6. [Folder Structure Recommendation](#6-folder-structure-recommendation)
7. [Broken References Report](#7-broken-references-report)
8. [Naming Convention Report](#8-naming-convention-report)
9. [Repository Standards Compliance Report](#9-repository-standards-compliance-report)
10. [Cleanup Execution Plan](#10-cleanup-execution-plan)
11. [Final Repository Hygiene Score](#11-final-repository-hygiene-score)

---

## 1. Repository Inventory

### docs/ (31 markdown files, 7 source files)

| Directory | Files | Category |
|-----------|:-----:|----------|
| `01_product/` | 6 | Product documentation |
| `02_architecture/` | 5 | Architecture documentation |
| `03_development/` | 5 | Development documentation |
| `04_sprints/` | 6 | Sprint reports |
| `05_reports/` | 5 | Audit/review reports |
| `06_reference/` | 4 | Reference documentation |
| `07_templates/` | 0 | Placeholder |
| `source/` | 7 | Raw source materials |

### lib/ (111 Dart files, ~593 KB)

| Directory | Files | Purpose |
|-----------|:-----:|---------|
| `lib/auth/` | 7 | Login, registration, password screens |
| `lib/bottom_bar/` | 5 | Bottom navigation + sub-pages |
| `lib/home/` | 14 | Home dashboard + widgets |
| `lib/homescreen/` | 3 | Petrol/map, mechanic, drawer screens |
| `lib/mechanic/` | 19 | Mechanic booking module (screens + widgets) |
| `lib/parts/` | 3 | Spare parts marketplace (UI scaffold) |
| `lib/services/` | 3 | AI repository, API client, location provider |
| `lib/Starting_screen/` | 3 | Legacy splash/auth entry |
| `lib/theme/` | 6 | Design tokens (colors, typography, spacing, etc.) |
| `lib/widgets/` | 11 | Shared reusable widgets |
| `lib/` (root) | 3 | main.dart, bottom_navigation.dart, chat_screen.dart |
| `lib/theme/providers/` | 1 | Theme provider |

### backend/ (30 files excluding venv, ~593 KB source)

| Directory | Files | Purpose |
|-----------|:-----:|---------|
| `backend/app/` | 14 | FastAPI application (routes, core, schemas, services) |
| `backend/ai/` | 7 | ML pipeline (data, model, RAG index) |
| `backend/` (root) | 3 | .env, requirements.txt, .gitkeep |

### assets/ (23 files, 43.3 MB)

23 images (14 PNG, 5 JPG), all part images, background images, logo.

### test/ (3 files, 6.5 KB)

| File | Type | Status |
|------|------|--------|
| `widget_test.dart` | Default counter test | **Stale** — unrelated to current app |
| `verify_e2e_network.dart` | Integration test | Active — requires running backend |
| `verify_chatbot_widget.dart` | Widget test | Active — requires running backend + Gemini API |

### Root files (10)

| File | Purpose |
|------|---------|
| `README.md` | Project overview |
| `pubspec.yaml` | Flutter manifest |
| `pubspec.lock` | Dependency lockfile |
| `analysis_options.yaml` | Dart analyzer config |
| `.env` | Environment secrets (gitignored) |
| `.metadata` | Flutter project metadata |
| `.flutter-plugins` | Plugin paths (auto-generated) |
| `.flutter-plugins-dependencies` | Plugin metadata (auto-generated) |
| `ui_blueprint.html` | Standalone interactive UI prototype |
| `.vscode/settings.json` | VS Code config |

### Legacy folders (28 files total)

| Directory | Files | Status |
|-----------|:-----:|--------|
| `documentation/` | 3 | Superseded by docs/ |
| `reports/sprint_*/` | 15 | Superseded by docs/04_sprints/ |
| `reports/reference/` | 13 | Superseded by docs/ |

---

## 2. Documentation Classification Matrix

### docs/ — Already Clean (from Sprint D4)

All 31 files in docs/ are correctly classified. No changes needed.

### documentation/ — Legacy (root level)

| File | Category | Purpose | Action |
|------|----------|---------|--------|
| `module_03_report.md` | Report | Module 3 completion (AI Orchestrator) | **Delete** — superseded by docs/04_sprints/ and docs/05_reports/ |
| `module_04_report.md` | Report | Module 4 completion (Flutter AI Integration) | **Delete** — superseded |
| `ui_verification_report.md` | Report | UI verification audit | **Delete** — superseded by docs/05_reports/VERIFICATION_REPORT.md |

### reports/ — Legacy (root level)

All 28 files in reports/ are superseded by content in docs/. They represent the old pre-D1 documentation structure.

| Category | Files | Action |
|----------|:-----:|--------|
| `reports/reference/*.md` | 13 | **Delete** — superseded by docs/02_architecture/, docs/03_development/, docs/06_reference/ |
| `reports/sprint_1.1/` | 1 | **Delete** — superseded by docs/04_sprints/SPRINT_1_1.md |
| `reports/sprint_1.2/` | 1 | **Delete** — superseded |
| `reports/sprint_1.3/` | 1 | **Delete** — superseded |
| `reports/sprint_1.4/` | 5 | **Delete** — superseded |
| `reports/sprint_1.5/` | 2 | **Delete** — superseded |
| `reports/sprint_1.6/` | 4 | **Delete** — superseded |

Notable AI artifact: `reports/reference/CHATGPT_CONTEXT___ai_seed_prompts.md` — explicit AI prompt dump, should be moved to `.ai/` or deleted.

---

## 3. Duplicate Detection Report

| # | Duplicate | Locations | Recommended Action | Justification |
|---|-----------|-----------|--------------------|---------------|
| 1 | Module completion reports | `documentation/module_03_report.md` + `documentation/module_04_report.md` | **Delete** | Content subsumed by docs/04_sprints/SPRINT_1_*.md and docs/02_architecture/ |
| 2 | UI verification report | `documentation/ui_verification_report.md` | **Delete** | Superseded by docs/05_reports/VERIFICATION_REPORT.md (Sprint D1.1) |
| 3 | Sprint 1.1–1.6 reports | `reports/sprint_*/*.md` (15 files) | **Delete** | Superseded by docs/04_sprints/SPRINT_1_*.md (6 consolidated files) |
| 4 | Reference docs | `reports/reference/*.md` (13 files) | **Delete** | All content exists in updated form in docs/ |
| 5 | AI prompt dump | `reports/reference/CHATGPT_CONTEXT___ai_seed_prompts.md` | **Delete** | Pure AI workflow artifact, not human documentation |
| 6 | Default counter test | `test/widget_test.dart` | **Delete** | Stale `flutter create` leftover, tests unrelated counter app |
| 7 | Logo duplicate | `assets/logo.jpg` vs old `docs/source/logo_mecha_connect..jpg` | ✅ **Already fixed** in D4 |

**No other duplicates found.** All files in lib/ are unique Dart source files. No duplicated widgets, services, or models were identified.

---

## 4. File Action Matrix

### docs/ — Keep All (31 files)

All files in the new docs/ structure are properly categorized and maintained. No changes needed.

### documentation/ — Delete All (3 files)

| File | Action | Risk | Reason |
|------|--------|:----:|--------|
| `documentation/module_03_report.md` | Delete | Low | Superseded by docs/ |
| `documentation/module_04_report.md` | Delete | Low | Superseded by docs/ |
| `documentation/ui_verification_report.md` | Delete | Low | Superseded by docs/ |

### reports/ — Delete All (28 files)

| Category | Action | Risk | Reason |
|----------|--------|:----:|--------|
| `reports/reference/*.md` (13) | Delete | Medium | All content exists in docs/; git preserves history |
| `reports/sprint_1.*/*.md` (15) | Delete | Medium | All content exists in updated form in docs/04_sprints/ |

### lib/

| File | Action | Risk | Reason |
|------|--------|:----:|--------|
| `lib/Starting_screen/` (3 files) | **Rename** | Medium | PascalCase violates snake_case convention; rename to `lib/starting_screen/` or consolidate |
| `lib/homescreen/` (3 files) | **Keep** | Low | Actively referenced; naming is inconsistent but functional |
| `lib/home/mock_data.dart` | **Rename** | Low | Misleading name — functions as production data model, not mock |
| `lib/mechanic/mock_data.dart` | **Rename** | Low | Same — functions as production data model |
| `lib/parts/order_data.dart` (40 bytes) | **Review** | Low | Very small file, likely contains only data classes |

### test/

| File | Action | Risk | Reason |
|------|--------|:----:|--------|
| `test/widget_test.dart` | **Delete** | Low | Default Flutter counter test, unrelated to Mecha Connect |
| `test/verify_e2e_network.dart` | **Move** | Low | Integration test → move to `test/integration/` |
| `test/verify_chatbot_widget.dart` | **Move** | Low | Integration test → move to `test/integration/` |

### Root files

| File | Action | Risk | Reason |
|------|--------|:----:|--------|
| `README.md` | **Edit** | Low | Fix 4 broken absolute paths |
| `.vscode/settings.json` | **Edit** | Low | Fix broken absolute path, or add to .gitignore |
| `ui_blueprint.html` | **Keep or Move** | Low | Interactive prototype, valuable for design reference; could move to `docs/source/` |
| `.flutter-plugins` | **Keep (gitignored)** | None | Auto-generated |
| `.flutter-plugins-dependencies` | **Keep (gitignored)** | None | Auto-generated |

### assets/

| File(s) | Action | Risk | Reason |
|---------|--------|:----:|--------|
| All 23 images | **Keep but compress** | Low | Functionally needed; 9 oversized PNGs should be optimized to <500KB each |
| Optimize: spark plugs (5.7MB), break pads (5.5MB), tool kit (4.9MB), battery (4.4MB), etc. | **Optimize** | Low | Can reduce 30MB+ with PNG compression |

### backend/

| File(s) | Action | Risk | Reason |
|---------|--------|:----:|--------|
| `ai/knowledge_base/bikes/` (empty) | **Delete** | Low | Empty directory |
| `ai/knowledge_base/cars/` (empty) | **Delete** | Low | Empty directory |
| `ai/knowledge_base/maintenance/` (empty) | **Delete** | Low | Empty directory |
| `ai/knowledge_base/repair_guides/` (empty) | **Delete** | Low | Empty directory |
| `backend/venv/` | **Delete + gitignore** | High | 1.3GB, 50K files — tracked in git. Sprint D3 blocker #1 |

---

## 5. Obsolete Files Report

### Safe to Delete (Phase A)

| File | Size | Reason |
|------|:----:|--------|
| `documentation/module_03_report.md` | ~5 KB | Superseded |
| `documentation/module_04_report.md` | ~5 KB | Superseded |
| `documentation/ui_verification_report.md` | ~8 KB | Superseded |
| `test/widget_test.dart` | 1 KB | Stale default counter test |
| `ai/knowledge_base/bikes/` | 0 B | Empty directory |
| `ai/knowledge_base/cars/` | 0 B | Empty directory |
| `ai/knowledge_base/maintenance/` | 0 B | Empty directory |
| `ai/knowledge_base/repair_guides/` | 0 B | Empty directory |

### Safe to Archive/Delete (Phase B)

| File/Group | Size | Reason |
|------------|:----:|--------|
| `reports/reference/*.md` (13 files) | ~200 KB | All content in docs/; historical value in git |
| `reports/sprint_1.*/*.md` (15 files) | ~150 KB | All content in docs/04_sprints/ |
| `.vscode/settings.json` | 89 B | Broken absolute path, should not be tracked |

### High Risk — Needs Approval (Phase C)

| File/Group | Size | Reason |
|------------|:----:|--------|
| `backend/venv/` | 1.3 GB | Critical to remove from git tracking; needs proper gitignore + BFG/git-filter-branch |
| `reports/` (entire folder) | ~350 KB | 28 historical files; all content exists in docs/ but deletion removes pre-D1 history |
| `documentation/` (entire folder) | ~18 KB | 3 historical reports |

---

## 6. Folder Structure Recommendation

### Current State

```
/ (root)
├── docs/          ← Clean (31 md + 7 source)
├── lib/           ← 111 files, good organization
├── backend/       ← 30 files + 1.3GB venv
├── assets/        ← 23 images, 43 MB
├── test/          ← 3 files
├── documentation/ ← LEGACY (3 files, should be removed)
├── reports/       ← LEGACY (28 files, should be removed)
├── android/       ← Platform (standard)
├── ios/           ← Platform (standard)
├── web/           ← Platform (standard)
├── linux/         ← Platform (standard)
├── windows/       ← Platform (standard)
├── macos/         ← Platform (standard)
└── .vscode/       ← Config (should NOT be tracked)
```

### Recommended

```
/ (root)
├── docs/              ← Unchanged (clean)
├── lib/               ← Unchanged structure
├── backend/           ← Unchanged (remove venv)
├── assets/            ← Unchanged (compress images)
├── test/              ← Remove widget_test.dart, add integration/ subdir
├── .github/           ← CREATE: CI/CD workflows (future)
├── scripts/           ← CREATE: dev utilities (future)
├── .ai/               ← CREATE: AI workflow artifacts (future)
├── android/           ← Unchanged
├── ios/               ← Unchanged
├── web/               ← Unchanged
├── linux/             ← Unchanged
├── windows/           ← Unchanged
├── macos/             ← Unchanged
```

**Key changes:**
- Remove `documentation/` (obsolete)
- Remove `reports/` (obsolete)
- Add `.vscode/` to `.gitignore`
- Create `test/integration/` for E2E tests

---

## 7. Broken References Report

### Broken Absolute Paths — README.md

| Line | Current (Broken) | Should Be |
|:----:|-------------------|-----------|
| 48 | `file:///c:/fsd with flutter/mecha_connect - Copy/INSTALLATION_GUIDE.md` | `docs/03_development/INSTALLATION.md` |
| 49 | `file:///c:/fsd with flutter/mecha_connect - Copy/PROJECT_ARCHITECTURE.md` | `docs/02_architecture/PROJECT_ARCHITECTURE.md` |
| 50 | `file:///c:/fsd with flutter/mecha_connect - Copy/API_DOCUMENTATION.md` | `docs/06_reference/API_SPEC.md` |
| 51 | `file:///c:/fsd with flutter/mecha_connect - Copy/documentation/module_04_report.md` | `docs/04_sprints/SPRINT_1_6.md` |

### Broken Absolute Path — .vscode/settings.json

| Line | Current (Broken) | Should Be |
|:----:|-------------------|-----------|
| 2 | `"C:/fsd with flutter/mecha_connect/linux"` | `"linux"` (relative) |

### Dead Reference — DESIGN_SYSTEM.md

Previously fixed in D4: `reports/reference/DESIGN_SYSTEM___colors_typography_components.md` → `02_architecture/DESIGN_SYSTEM.md`

### MASTER_ENGINEERING_HANDBOOK — Self-Reference

Previously fixed in D4.

### All docs/ cross-references

✅ Verified: 44 cross-references corrected in D4, all working.

---

## 8. Naming Convention Report

### Violations Found

| Location | Current Name | Convention | Recommended Name | Risk |
|----------|-------------|------------|-----------------|:----:|
| `lib/` | `Starting_screen/` | snake_case (Dart) | `starting_screen/` or `splash/` | Medium |
| `lib/` | `homescreen/` (vs `home/`) | snake_case | One authoritative name — either merge or rename | Medium |
| `lib/home/` | `mock_data.dart` | Naming clarity | `home_data.dart` or `user_data.dart` | Low |
| `lib/mechanic/` | `mock_data.dart` | Naming clarity | `mechanic_data.dart` | Low |
| `test/` | `widget_test.dart` | Naming clarity | Already recommended for deletion | Low |
| Root | `documentation/` | Plural vs `docs/` | Delete (superseded) | Medium |
| Root | `reports/` | Plural vs `docs/05_reports/` | Delete (superseded) | Medium |

### Convention Standards

| Scope | Standard | Check |
|-------|----------|:-----:|
| Dart files | `snake_case.dart` | ✅ Mostly compliant (except `Starting_screen/`, `homescreen/`) |
| Documentation | `SCREAMING_SNAKE_CASE.md` | ✅ Compliant (D4 fix) |
| Directories (docs) | `NN_category/` | ✅ Compliant (01_product, etc.) |
| Directories (lib) | `snake_case/` | ❌ `Starting_screen/` violates |
| Assets | kebab-case or snake_case | ✅ Mix of both |

---

## 9. Repository Standards Compliance Report

### Standards Violations

| # | Standard | Violation | Location | Severity |
|---|----------|-----------|----------|:--------:|
| 1 | One Source of Truth | Two documentation directories: `documentation/` and `docs/` | Root | **High** |
| 2 | One Source of Truth | Duplicate report directories: `reports/` and `docs/05_reports/` | Root | **High** |
| 3 | No dead documentation | `documentation/` contains 3 superseded reports | Root | Medium |
| 4 | No dead documentation | `reports/` contains 28 superseded files | Root | Medium |
| 5 | Consistent naming | `lib/Starting_screen/` uses PascalCase | lib | Low |
| 6 | Clear folder responsibility | `lib/homescreen/` vs `lib/home/` — unclear overlap | lib | Low |
| 7 | No temporary files in production | `test/widget_test.dart` is default template code | test | Low |
| 8 | No generated files tracked | `.vscode/settings.json` tracked (contains machine-specific path) | Root | Low |
| 9 | CI/CD workflows | No `.github/` directory | Root | Medium |
| 10 | venv not in gitignore | `backend/venv/` is tracked | Root | **Critical** |

### What's Compliant

| Standard | Status |
|----------|:------:|
| Documentation organized by category | ✅ docs/ |
| Version headers in documents | ✅ All docs/ files |
| Cross-references between documents | ✅ Fixed in D4 |
| Sprint reports in dedicated folder | ✅ docs/04_sprints/ |
| Reports separated from living docs | ✅ docs/05_reports/ |
| README as navigation index | ✅ docs/README.md |
| `.env` gitignored | ✅ |
| `__pycache__` gitignored | ✅ |

---

## 10. Cleanup Execution Plan

### Phase A — Safe Changes (Execute now, no approval needed)

| # | Task | Files | Effort | Impact |
|---|------|-------|:------:|:------:|
| A1 | Fix README.md broken absolute paths | 1 | 5 min | README becomes shareable |
| A2 | Fix `.vscode/settings.json` path | 1 | 2 min | Removes machine-specific path |
| A3 | Delete `test/widget_test.dart` | 1 | 1 min | Removes misleading template test |
| A4 | Delete empty knowledge_base dirs | 4 | 1 min | Removes clutter |
| A5 | Add `.vscode/` to `.gitignore` | 1 | 1 min | Prevents machine-specific config tracking |
| A6 | Delete `documentation/` folder | 3 | 1 min | Removes superseded pre-D1 content |
| A7 | Create `test/integration/` + move E2E tests | 2 | 5 min | Proper test organization |

**Total Phase A: ~15 min, zero risk.**

### Phase B — Review Required

| # | Task | Files | Effort | Impact |
|---|------|-------|:------:|:------:|
| B1 | Delete `reports/` folder | 28 | 5 min | Removes ~350KB of superseded content |
| B2 | Rename `lib/Starting_screen/` → `starting_screen/` | 3 files + imports | 30 min | Fixes naming; needs import updates in bottom_navigation.dart |
| B3 | Rename `lib/home/mock_data.dart` → `home_data.dart` | 1 file + 8 imports | 15 min | Clarity; needs import updates in 8 widgets |
| B4 | Rename `lib/mechanic/mock_data.dart` → `mechanic_data.dart` | 1 file + 10 imports | 15 min | Clarity; needs import updates |
| B5 | Optimize 9 oversized PNGs | 9 | 30 min | Saves ~30MB in repo |
| B6 | Move `ui_blueprint.html` → `docs/source/` | 1 | 1 min | Better home for prototype artifact |

**Total Phase B: ~1.5 hours.**

### Phase C — High Risk (Explicit Approval Required)

| # | Task | Files | Effort | Impact |
|---|------|-------|:------:|:------:|
| C1 | Remove `backend/venv/` from git tracking | 50,244 | 1 hour | **Critical:** saves 1.3GB, enables cloning |
| C2 | Verify asset image usage and remove unused | ~23 | 2 hours | Confirm which images are actually loaded |
| C3 | Restructure `lib/homescreen/` vs `lib/home/` | ~17 | 3 hours | Medium: merge or clarify responsibility |

---

## 11. Final Repository Hygiene Score

### Dimension Scores (0–10)

| Dimension | Score | Strengths | Weaknesses |
|-----------|:-----:|-----------|------------|
| **Repository Organization** | **7** | Clean docs/ structure, lib/ mostly well-organized | Legacy `documentation/` + `reports/` at root; `lib/Starting_screen/` naming |
| **Documentation Quality** | **9** | Verified cross-references, version headers, categorized | `README.md` has broken paths; MASTER_ENGINEERING_HANDBOOK is aspirational/barely used |
| **Consistency** | **6** | Docs/ uses SCREAMING_SNAKE_CASE, lib/ mostly snake_case | `Starting_screen/` violates; `mock_data` misnamed; `homescreen` vs `home` overlap |
| **Maintainability** | **7** | Small modules, clean service layer, feature-based organization | 5 files >24KB (refactoring candidates); no DI framework |
| **Developer Experience** | **5** | `INSTALLATION.md`, `CONTRIBUTING.md`, clean docs index | No CI/CD, no scripts/, stale counter test, broken README |
| **Startup Readiness** | **4** | Strong docs, real AI features, clean architecture | venv bloat (1.3GB), no LICENSE, no CI/CD, broken README paths |
| **Open Source Readiness** | **4** | Professional docs index, contributing guide | Missing LICENSE, broken README, venv bloat, no Code of Conduct |
| **Overall Hygiene** | **6/10** | Solid foundation after D4 cleanup | 2 major items (venv, legacy folders) + several nits |

### Top 5 Priorities Before Next Dev Sprint

| Priority | Task | Phase | Impact |
|:--------:|------|:-----:|:------:|
| 1 | **Remove `backend/venv/` from git** | C | Repo shrinks 1.3GB → ~50MB |
| 2 | **Fix README broken paths** | A | README becomes shareable |
| 3 | **Delete `documentation/` + `reports/`** | A + B | Removes duplicate content, one source of truth |
| 4 | **Add CI/CD workflow (`.github/`)** | Future | Enables automated testing |
| 5 | **Rename `lib/Starting_screen/`** | B | Naming consistency |

### Summary

The repository is in **solid shape** after the D4 documentation refactoring. The docs/ directory is professional-grade. The lib/ codebase is well-organized. The main issues are:

1. **Legacy root folders** (`documentation/`, `reports/`) that should have been removed when docs/ was created
2. **The 1.3GB venv bloat** in git (Sprint D3 blocker #1, still unresolved)
3. **Naming inconsistencies** in lib/ (Starting_screen, mock_data, homescreen vs home)
4. **Missing infrastructure** (no CI/CD, no .github/)

These are all low-risk to fix and would take less than a day of focused work. The repository is ready for Sprint 1.7 (Fuel Delivery) once these hygiene items are addressed.
