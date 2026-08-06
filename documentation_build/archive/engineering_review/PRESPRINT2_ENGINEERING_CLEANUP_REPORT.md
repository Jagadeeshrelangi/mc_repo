# ENGINEERING REVIEW REPORT — Mecha Connect

> **Pre-Sprint 2 Engineering Cleanup (deliverable)** · **Date:** 2026-08-06
> **Scope:** Documentation integrity/cleanup/validation, frontend security, backend
> scaffold cleanup, dependency audit, repo hygiene, doc synchronization,
> code-quality classification, final validation.
> **Commit reviewed:** `84b68f5` (`main`) + working-tree changes from this cleanup.
> **Related audit:** `documentation_build/archive/engineering_review/ENGINEERING_REVIEW_REPORT.md`
> (the independent read-only audit this cleanup responds to).

---

## 1. Executive Summary

The Pre-Sprint 2 Engineering Cleanup is **COMPLETE (10/10 tasks)**. The
repository is now a defensible Sprint 2 baseline. All follow-ups F1–F10 from
`documentation_build/archive/engineering_review/MERGE_SUMMARY.md` were executed,
plus the standalone report deliverable.

**Architecture freeze honored.** No Flutter UI/feature/provider/structure
redesign, no new features. All changes are engineering hygiene: fixing what was
broken or stale, and documenting honestly what remains.

**Verified green at baseline AND re-verified green at close:**
- `flutter analyze` — **0 issues**
- `flutter test` — **162/162 passing**
- Backend imports load; **6 routes** registered (FastAPI app factory + RAG +
  XGBoost diagnosis + Gemini connectors all initialize).
- All 6 JSON exports in `documentation_build/09_exports/` parse valid.

**What was wrong and is now fixed:**
- **8 broken documentation links** (archived `05_reports/` paths left dangling)
  — repaired; full-repo scan now reports **0 broken links**.
- **6 leaked tool artifacts** (stray `</arg_value>…</write_to_file>` XML blocks)
  — removed from core docs and process reports.
- **Fabricated 12-month project timeline** — replaced with the canonical
  history matching `CHANGELOG.md` + git (2026-07-20 → 2026-08-05).
- **Plaintext password persistence** in SharedPreferences — removed
  (write + read paths), login auto-fill of the saved password removed, logout
  now always clears stored credentials.
- **False "validation PASS" claims** in archived refactor reports — corrected
  with dated correction notes.
- **Stale status docs** (`PROJECT_STATUS.md`, `ROADMAP.md`, `docs/README.md`,
  `NEXT_SESSION_HANDOVER.md`, `CANONICAL_DOCUMENT_MAP.md`) — synced to the
  canonical CHANGELOG + as-built backend state.
- **Repo hygiene** — `.env.example` files added (root + backend), `.gitignore`
  hardened, `__pycache__/` and venv cache dirs cleaned, no secrets found in any
  tracked source.

**Remaining debt** (detailed in §8) is honest and non-blocking for Sprint 2
*planning*: zero backend tests, no DB layer, unverified `GEMINI_API_KEY`
(non-standard `AQ.` prefix), no root `LICENSE` file, and a pre-existing
dart-format divergence across the frontend. None of it requires architecture
change.

---

## 2. Files Modified

### Working-tree changes (this cleanup + the audit it executes)

| Area | Files |
|---|---|
| **Docs — links** | `docs/PROJECT_DOCUMENTATION_INDEX.md`, `docs/README.md`, `docs/archive/SPRINT_1_7.md`, `documentation_build/archive/SPRINT_1_7A_REPORT.md`, `documentation_build/10_claude_bundle/CLAUDE_PROMPT.md` |
| **Docs — artifacts/timeline** | `documentation_build/00_core/AI_PROJECT_MEMORY.md`, `documentation_build/00_core/PROJECT_TIMELINE.md`, `documentation_build/archive/process_reports/GAP_ANALYSIS.md`, `SPRINT_2_BACKEND_BLUEPRINT.md`, `BACKEND_AUDIT_REPORT.md`, `BACKEND_BLUEPRINT.md` |
| **Docs — truth corrections** | `documentation_build/archive/process_reports/DOCUMENTATION_REFACTOR_REPORT.md`, `DOCUMENTATION_BUILD_V2_1_COMPLETION_REPORT.md` |
| **Docs — sync** | `docs/01_product/PROJECT_STATUS.md`, `docs/01_product/ROADMAP.md`, `documentation_build/NEXT_SESSION_HANDOVER.md`, `documentation_build/CANONICAL_DOCUMENT_MAP.md` |
| **Frontend security** | `lib/features/auth/providers/auth_provider.dart`, `lib/features/auth/repositories/auth_repository.dart`, `lib/features/auth/screens/login_screen.dart` |
| **Backend** | `backend/app/services/chat_service.py` (unused `Any` import removed), `backend/requirements.txt` (pinned) |
| **Config / env** | `.gitignore`, `.env.example` (new), `backend/.env.example` (new), `backend/app/core/config.py`, `backend/app/main.py` (already settings-driven) |
| **Dependencies** | `pubspec.yaml`, `pubspec.lock` (+ regenerated platform plugin registrants: `linux/`, `macos/`, `windows/`) |
| **Prior session (audit base)** | `docs/03_development/CHANGELOG.md` (added `1.9.3-docs`), `docs/03_development/INSTALLATION.md` (§1D + §5 backend as-built) |
| **Removal (intentional)** | `docs/05_reports/` — 5 tracked sprint reports deleted; contents preserved at `documentation_build/archive/` |

> `docs/05_reports/` deletion is intentional and conscious (MERGE_SUMMARY F5).
> All 5 reports are archived under `documentation_build/archive/` and every
> link to them was repointed before the deletion. Committing the deletion
> without `documentation_build/` would be data loss — commit them together.

---

## 3. Documentation Fixes

### 3.1 Broken links — fixed (8 found, 0 remain)

A scripted full-repo link scan found 8 broken Markdown links in 3 files (all
caused by archiving `05_reports/` without updating references). All repaired:

| File | Fix |
|---|---|
| `docs/PROJECT_DOCUMENTATION_INDEX.md:65-68` | 4 `05_reports/*.md` links → `../documentation_build/archive/*.md` |
| `docs/archive/SPRINT_1_7.md:53` | `../05_reports/SPRINT_1_7A_REPORT.md` → `../../documentation_build/archive/SPRINT_1_7A_REPORT.md` |
| `documentation_build/archive/SPRINT_1_7A_REPORT.md:101-102` | `../03_development/…` / `../01_product/…` → `../../docs/…` |

Post-fix re-scan: **165 links checked, 0 broken.** The single remaining
"miss" is `10_claude_bundle/CLAUDE_PROMPT.md:55` (`diagrams/png/<name>.png`) —
an intentional template placeholder, not a real link.

Also fixed: stale `13_claude_bundle/` folder reference in `CLAUDE_PROMPT.md:4`
(actual folder is `10_claude_bundle/`).

### 3.2 Tool-artifact leakage — removed (6 files)

Stray XML/artifact blocks (`</arg_value>`, `<task_progress>`,
`</write_to_file>`) found and removed from:

- `documentation_build/00_core/AI_PROJECT_MEMORY.md` (+ stale folder paths
  corrected to `09_exports/`, `10_claude_bundle/`, `01_knowledge/`, `archive/`)
- `documentation_build/00_core/PROJECT_TIMELINE.md` (artifact removed during
  timeline rewrite)
- `documentation_build/archive/process_reports/GAP_ANALYSIS.md`
- `documentation_build/archive/process_reports/SPRINT_2_BACKEND_BLUEPRINT.md`
- `documentation_build/archive/process_reports/BACKEND_AUDIT_REPORT.md`
- `documentation_build/archive/process_reports/BACKEND_BLUEPRINT.md`

### 3.3 Timeline corrected (F1)

`00_core/PROJECT_TIMELINE.md` claimed a **fabricated 12-month history
(2025-07 → 2026-06)** that contradicted `CHANGELOG.md` and git. Rewritten as a
**HISTORY document** matching the canonical record: project init 2026-07-20 →
RC1 2026-08-05; commits `0811e62` (init), `c98f12e` (frontend rewrite),
`84b68f5` (RC1 docs). Repurposed from "editable PLAN" to historical record.

### 3.4 False "validation PASS" claims corrected (F4)

`DOCUMENTATION_REFACTOR_REPORT.md` and `DOCUMENTATION_BUILD_V2_1_COMPLETION_REPORT.md`
asserted `✅ PASS` on cross-reference validation while 8 links were actually
broken. Dated correction notes now flag the original claims as overstated and
reference this report. Archived history is preserved, not rewritten.

### 3.5 Status/handover docs synced

- `docs/01_product/PROJECT_STATUS.md` → v1.3.0 (2026-08-06): RC1 state, Sprint 2
  next, completed modules 1.7A/1.8/1.9/1.9A/1.9B, 162/162 metrics.
- `docs/01_product/ROADMAP.md` → v1.2.0: Sprint 1 fully done, Sprint 2 rows
  reflect the existing scaffold ("integration pending").
- `docs/README.md` → v1.9.3-docs: removed deleted `05_reports/` and
  non-existent `design_reference/` from structure; reports now in
  `documentation_build/archive/`.
- `documentation_build/NEXT_SESSION_HANDOVER.md` → rewritten for 2026-08-06
  (fixed stale `00_engineering_audit/` and `DOCUMENTATION_HEALTH_REPORT.md` paths).
- `documentation_build/CANONICAL_DOCUMENT_MAP.md` → fixed
  `PROJECT_REQUIREMENTS_DOCUMENT.md`→`PRODUCT_REQUIREMENTS_DOCUMENT.md` and
  stale `archive/00_engineering_audit/` path; added Sprint 2 baseline rows.

---

## 4. Security Fixes (frontend)

**Plaintext password persistence — REMOVED (P0 from prior audit).**

| Before | After |
|---|---|
| `AuthProvider.login()/register()` wrote `remember_me_password` to SharedPreferences | Only `remember_me_email` is stored; password is never persisted |
| `_loadSavedCredentials()` read the saved password back | Reads email only |
| `LoginScreen` auto-filled the saved password into the password field | Pre-fills email only; user always types the password |
| `logout()` kept stored credentials when "remember me" was on | `logout()` always clears stored credentials |

The three surviving `prefs.remove('remember_me_password')` calls are legacy-key
**cleanup** (defense-in-depth for already-installed users), never writes.

**Mock seam documented.** `AuthRepository` now carries an explicit doc comment:
it is a frozen dev-only mock that returns `true` without credential
verification and MUST be replaced before production. This converts an implicit
security risk into a documented, deliberate seam (no behavior change — tests
still pass).

**No secrets found.** A repo-wide scan of source (excluding `venv/`,
`.git`, archives, and `.env.example`) found no committed API keys, private keys,
or `AIza`/`sk-` patterns.

---

## 5. Backend Cleanup

The FastAPI scaffold was verified against the audit findings and is **largely
already clean** (most TASK-5 items were centralized in the audit session):

- **CORS** — `main.py` uses `settings.CORS_ORIGINS` (explicit allow-list,
  default `localhost:3000`), never `*` with credentials. The old wildcard
  `allow_origins=["*"]` is gone.
- **Model name** — `gemini-2.5-flash` is defined once in
  `config.py:GEMINI_MODEL`; all service call sites use `settings.GEMINI_MODEL`
  (verified by grep — zero hardcoded occurrences outside config).
- **Default mileage** — `mileage=80000` defined once as
  `config.py:DEFAULT_VEHICLE_MILEAGE`; `chat_service._orchestrate_diagnosis`
  uses `settings.DEFAULT_VEHICLE_MILEAGE`.
- **Unused import removed** — `Any` in `backend/app/services/chat_service.py`
  (AST-verified unused). `diagnosis_service.py`/`rag_service.py` imports all used.
- **`ENABLE_FALLBACK` default flipped `False → True`** (F7 recommendation) —
  the code now defaults to the resilient local-fallback path, so the app boots
  without a valid key; `backend/.env` still pins `False` for strict mode.
- **Backend imports validate** — `from app.main import app` succeeds; app boots
  with XGBoost classifier, FAISS index, and both Gemini connectors; **6 routes**
  registered.

> Remaining backend debt (no tests, no DB layer, FAISS
> `allow_dangerous_deserialization=True` for local dev, in-memory sessions) is
> unchanged by design — see §8.

---

## 6. Config Cleanup

- **`.env.example` created at repo root and `backend/`** — documents required
  env keys (`GEMINI_API_KEY`, `FIREBASE_PROJECT_ID` at root;
  `PROJECT_NAME`, `LOG_LEVEL`, `GEMINI_API_KEY`, `FIREBASE_CREDENTIALS_PATH`,
  `ENABLE_FALLBACK` in backend) with no real values.
- **`.gitignore` hardened:**
  - `.env` / `.env.*` ignored with `!.env.example` exceptions (root + backend)
    so template files stay tracked while real secrets stay out.
  - `devtools_options.yaml` (untracked Flutter DevTools artifact) ignored.
  - `Thumbs.db`, `desktop.ini` (Windows junk) added.
  - Existing coverage verified: `build/`, `.dart_tool/`, `.idea/`, `.vscode/`,
    `*.log`, `.DS_Store`, `__pycache__/`, `venv/` all present.
- **Cache cleanup** — app-level `__pycache__/` directories removed; venv cache
  directories cleaned (regenerable).
- No tracked files match `.vscode/`, `build/`, or editor junk patterns.
- **No `LICENSE` file at repo root** — the project has `LICENSE_GUIDE.md` +
  `COPYRIGHT_NOTICE.md` in `07_rc1_certification/`, but no actual license file.
  Adding one is a legal decision; recorded as debt (§8), not invented here.

---

## 7. Dependency Cleanup

### 7.1 Flutter (`pubspec.yaml`)

Unused dependencies removed (verified by source scan: 0 imports anywhere in
`lib/` or `test/`):

- `flutter_map_tile_caching` — no import found
- `flutter_map_cancellable_tile_provider` — no import found
- `cupertino_icons` — no import found

`pubspec.lock` is consistent (packages absent from lock). Regenerated platform
plugin registrants (`linux/`, `macos/`, `windows/`) reflect the removed
plugins. `flutter pub get` resolves. **Still used:** `provider` (66 refs),
`shared_preferences` (12), `latlong2`, `google_nav_bar`, `device_preview`,
`flutter_dotenv`, `http`, `nested`, `flutter_map` (1 each).

> Note: `flutter pub get` reports 48 transitive packages with newer versions
> incompatible with the pinned constraints — deliberate, not an error.

### 7.2 Python (`backend/requirements.txt`)

Pinned to the verified venv freeze (2026-08-06): `fastapi==0.139.0`,
`uvicorn==0.49.0`, `pydantic==2.13.4`, `pydantic-settings==2.14.2`,
`pandas==3.0.3`, `numpy==2.5.0`, `scikit-learn==1.9.0`, `xgboost==3.3.0`,
`joblib==1.5.3`, `faiss-cpu==1.14.3`, `langchain==1.3.11`,
`langchain-community==0.4.2`, `langchain-google-genai==4.2.6`,
`firebase-admin==7.5.0`, `sentence-transformers==5.6.0`, etc. No `>=` pins.

---

## 8. Remaining Debt (P0–P3)

### P0 — Block Sprint 2 *execution* (not planning)

1. **Zero backend tests** — no pytest, no FastAPI tests anywhere. First Sprint 2
   task should stand up the test harness.
2. **No database layer / no Alembic migrations** — `DATABASE_BLUEPRINT.md` +
   `schema.sql` exist; nothing implements or migrates them.
3. **`GEMINI_API_KEY` invalid-format** — the configured key has a non-standard
   `AQ.` prefix (real keys start `AIzaSy`). Unverified until a live key is
   supplied. Code default is now `ENABLE_FALLBACK=true` (resilient), but
   `backend/.env` sets `ENABLE_FALLBACK=False`, so with that file and no valid
   key, Gemini endpoints raise 422.

### P1 — Should fix in Sprint 2

1. No CI/CD pipeline, no Dockerfile, no auth middleware/JWT/Firebase wiring.
2. No backend architecture / data-flow / deployment diagrams.
3. `ordersList` typed as `Map<String, dynamic>` instead of a model.
4. FAISS `allow_dangerous_deserialization=True` (acceptable for local dev, must
   be gated/removed before any network exposure).
5. No root `LICENSE` file (legal decision required).

### P2 — Defer

1. No ADR documents; missing backend/data-flow/deployment diagrams.
2. No performance benchmarks; no WCAG accessibility detail pass.
3. Screenshots pending (0/54) in the documentation set.

### P3 — Cosmetic / accepted

1. **dart format divergence** — most of `lib/` and `test/` is not
   `dart format`-clean (pre-existing; verified via `dart format --output=none
   --set-exit-if-changed`). Not mass-formatted in this cleanup because it would
   create a huge churn diff against the frozen frontend; should be a
   behind-the-scenes formatting pass in Sprint 2 if desired.
2. In-memory backend session store (fine for dev; swap for Redis later).
3. Duplicate knowledge between `docs/` and `documentation_build/` (accepted,
   per the canonical document map).

---

## 9. Sprint 2 Readiness Score

| Dimension | Score | Rationale |
|---|---|---|
| Frontend quality | **10/10** | `flutter analyze` 0 issues; 162/162 tests re-verified; architecture frozen and coherent |
| Frontend security | **8/10** | Plaintext password removed; mock auth documented; no committed secrets. Residual: mock auth seam + no auth tests (P0/P1) |
| Backend scaffold | **6/10** | 6 routes run; settings centralized; deps pinned. Residual: no tests, no DB, invalid-format key (P0) |
| Docs integrity | **9/10** | 0 broken links; artifacts removed; timeline corrected; false claims annotated. Residual: dart-format/style and duplicate knowledge (P3) |
| Repo hygiene | **9/10** | .gitignore hardened; `.env.example` added; caches cleaned. Residual: no LICENSE file (P1) |
| **Overall** | **8.4/10** | **Ready to START Sprint 2.** Cleanup work is done; remaining P0s are Sprint-2 *work items*, not blockers for planning |

---

## 10. Final Recommendation

**APPROVE this working tree as the Sprint 2 baseline.**

1. **Commit the working tree as one coherent baseline commit.** It must include
   `documentation_build/` together with the `docs/05_reports/` deletion — they
   are two halves of the same move, and committing the deletion without the
   archive is data loss (see §2 note).
2. **Start Sprint 2 with the P0 list (§8):** stand up the backend test harness,
   make the DB-layer decision (SQLite/PostgreSQL + Alembic), and replace the
   `GEMINI_API_KEY` with a valid key or keep `ENABLE_FALLBACK=true` for dev.
3. **Treat mock auth (`AuthRepository` always-`true`) and the FAISS
   deserialization flag as explicit production-gates**, not future cleanup.
4. **Do not mass-reformat the frontend** (P3) during Sprint 2 feature work;
   schedule it as a standalone pass if the team wants format-enforced CI.

**Constraint honored:** no architecture change, no feature work, no invented
solutions — every open item above is either documented debt or a Sprint 2
work item.

