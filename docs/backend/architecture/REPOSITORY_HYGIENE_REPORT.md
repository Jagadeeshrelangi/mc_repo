# Repository Hygiene Report — Tracked Flutter Build Artifacts

> **Sprint 2 · Pre-Commit Git Hygiene · 2026-08-07**
> Safely removed `frontend/build/` from Git tracking; local files preserved.

---

## 1. Executive Summary

The generated Flutter build directory `frontend/build/` (Flutter web/native
build output, `.dill` kernels, canvaskit WASM, generated manifests) had been
tracked by Git since the monorepo freeze commit (`c801688`). This is a Git
hygiene defect — generated build artifacts must never be version-controlled.

`frontend/build/` was removed from the Git index with
`git rm -r --cached frontend/build`. The **local** build directory and all its
files were **preserved**. The existing `.gitignore` rule (`frontend/build/`,
line 36) already covers it, so no `.gitignore` change was required. No source,
backend, AI, database, or documentation files were touched.

**Result: 109 tracked build files removed from the index; working tree
preserved; repository cleaner and ready for review/commit.**

---

## 2. Problem

`frontend/build/` was accidentally committed during the monorepo architecture
freeze (`c801688 feat(repo): freeze monorepo architecture and prepare
Sprint 2`). The `.gitignore` rule `frontend/build/` was added in that same
change, but `.gitignore` does **not** untrack files that are already in the
index — it only affects newly added paths. As a result:

- 109 generated files were tracked in Git (approx. 250k lines / large binaries)
- Every Flutter web build (typically run during validation) churned the index
  (`frontend/build/cache.dill.track.dill` showed repeated `M` changes)
- Repository bloat and noisy diffs

Generated artifacts committed to Git cause: unbounded repository growth,
meaningless diff churn on every local build, and misleading review surface.

---

## 3. Changes Made

| Action | Details |
|---|---|
| `git rm -r --cached frontend/build` | Removed 109 files from the Git index (staged deletion) |
| Local `frontend/build/` directory | **NOT deleted** — preserved on disk |
| `.gitignore` | **No change** — correct rule `frontend/build/` already exists (line 36) |
| Frontend source | Not modified (`frontend/lib/`, `frontend/test/`, `frontend/assets/` clean) |
| Backend | Not modified by this task |
| Documentation | Not modified except this report |

`--cached` was used exclusively, so only the index changed — the working tree
on disk is untouched.

---

## 4. Git Tracking

- **Number of tracked build files removed:** 109
- **`git ls-files frontend/build/` after cleanup:** no output (0 tracked files) ✅
- **Local build files preserved:** ✅ `Test-Path frontend/build` → `True`

---

## 5. .gitignore Verification

The ignore rule **already existed** and was **verified, not added**:

```
.gitignore:36:frontend/build/
```

This correctly ignores the build directory for any future `/new files` that
may appear (e.g., a subsequent `flutter build`). No `.gitignore` rewrite was
performed.

---

## 6. Files Changed

- Staged deletions (this task): **109 files** under `frontend/build/` removed
  from the index (`git diff --cached --stat -- frontend/build` →
  `109 files changed, 250810 deletions(-)`).
- Newly created: `docs/backend/architecture/REPOSITORY_HYGIENE_REPORT.md`
  (this report).

Note: the working tree already contains unrelated, pre-existing Task 2 /
Cline changes (shown in `git status`) which were **not** staged or touched by
this cleanup.

---

## 7. Files NOT Changed

Explicit confirmation:

- **Frontend source** (`frontend/lib/`, `frontend/test/`, `frontend/assets/`) — NOT changed
- **Backend implementation** (`backend/app/`) — NOT changed by this task
- **AI services** (`backend/app/services/chat_service.py`,
  `diagnosis_service.py`, `rag_service.py`) — NOT changed
- **Database foundation** (SQLAlchemy/Alembic/`core/database.py`) — NOT changed
- **Documentation** — only this report added; no existing doc modified

---

## 8. Verification Commands

| Command | Result |
|---|---|
| `git ls-files frontend/build` (before) | 109 files |
| `git ls-files frontend/build` (after) | 0 files ✅ |
| `Test-Path frontend/build` | `True` (preserved) ✅ |
| `Select-String .gitignore -Pattern 'frontend/build'` | `frontend/build/` at line 36 ✅ |
| `git status --short frontend/lib frontend/test frontend/assets` | empty (clean) ✅ |
| `git diff --cached --stat -- frontend/build` | `109 files changed, 250810 deletions(-)` |
| `git ls-files` grep `.dart_tool|.idea|flutter_assets|canvaskit` | empty (no other generated dirs tracked) ✅ |

---

## 9. Security / Repository Hygiene

Generated build artifacts are no longer intended to be committed. The index
no longer contains `frontend/build/`, `.gitignore` prevents future
re-addition, and no other generated directories (`.dart_tool/`, `.idea/`,
`build/`) are tracked. Build outputs exist only locally.

---

## 10. Final Status

**REPOSITORY HYGIENE CLEANUP COMPLETE**

- Build directory removed from Git tracking: **YES** (109 files)
- Local build directory preserved: **YES**
- `.gitignore` rule verified (already present): **YES**
- Backend / AI / database / frontend source changed: **NO**
- Documentation changed (other than this report): **NO**
- Task 2 implementation untouched: **YES**
- No commit, no push performed.