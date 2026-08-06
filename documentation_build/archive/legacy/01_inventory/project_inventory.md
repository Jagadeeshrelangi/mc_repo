# Project Inventory — Mecha Connect

> Phase 1 · Documentation Build Sprint v2.0 · 2026-08-05
> Purpose: structured counts and relationships for the compiler bundle.
> Primary sources: repo scan + `docs/07_rc1_certification/*` + `docs/01_product/*` + `docs/03_development/*` (reused, not duplicated).

## 1. Repository Summary

| Metric | Value |
|---|---|
| Monorepo app | Flutter client (`lib/`) |
| Backend | FastAPI scaffold (`backend/app`) + AI assets (`backend/ai`) |
| App version | `1.0.0+1` (`pubspec.yaml`) |
| Dart SDK | `^3.7.2` |
| Flutter | 3.29.2 |
| Dart source files (`lib/`) | 233 |
| Test files (`test/`) | 9 (162 tests) |
| Asset files (`assets/`) | 18 |
| Backend Python files (non-venv) | 17 |
| Remote | `https://github.com/Jagadeeshrelangi/mc_repo.git` (branch `main`) |

## 2. Top-Level Structure

| Path | Purpose |
|---|---|
| `lib/main.dart` | Entrypoint: dotenv load → provider wiring → `MyApp` (DevicePreview + MaterialApp, route `/` = SplashScreen) |
| `lib/app_wiring.dart` | `buildRootProviders()` — **single source of truth** for the root Provider graph (also used by the runtime integration test) |
| `lib/bottom_bar/` | 5-tab shell + Orders screen |
| `lib/features/<module>/` | Feature-first modules: ai, auth, fuel_delivery, home, marketplace, mechanic, profile |
| `lib/starting_screen/` | Splash (in `main.dart`) + onboarding flow |
| `lib/homescreen/` | Drawer screen (legacy location, keep) |
| `lib/theme/` | Design tokens + theme + ThemeProvider |
| `lib/widgets/` | Shared widgets (loading, order card, location) |
| `lib/parts/` | `order_data.dart` — shared `OrderStore` |
| `lib/services/` | Location services + geocoding |
| `backend/` | FastAPI scaffold + AI (RAG, classifier) — Sprint 2 target |
| `test/` | 9 test files (8 module + 1 integration) |

## 3. Feature-Module Inventory (per `lib/features/`)

| Module | models | providers | repos | services | screens | widgets | nav | total |
|---|---|---|---|---|---|---|---|---|
| `ai` | 7 | 1 | 1 | 2 | 5 | 10 | 1 | 26 |
| `auth` | 0 | 1 | 1 | 1 | 3 | 1 | 0 | 7 |
| `fuel_delivery` | 11 | 1 | 1 | 1 | 8 | 13 | 0 | 37 |
| `home` | 1 | 1 | 1 | 0 | 2 | 15 | 0 | 20 |
| `marketplace` | 8 | 1 | 1 | 1 | 8 | 19 | 1 | 39 |
| `mechanic` | 3 | 1 | 1 | 1 | 11 | 8 | 0 | 25 |
| `profile` | 9 | 1 | 1 | 2 | 13 | 13 | 1 | 39 |
| **Total** | **39** | **7** | **7** | **8** | **50** | **79** | **3** | **193** |

> `nav` column = dedicated `navigation.dart` route files (ai, marketplace, profile). Other modules navigate inline.

## 4. Backend Relation

The backend scaffold (`backend/app`) is **not yet wired to the Flutter client at
RC1**. The Flutter UI talks only to in-memory mock repositories with simulated
latency/failure. Sprint 2 will swap repository internals to the FastAPI client
behind the frozen `API_CONTRACT.md`.

| Backend piece | Purpose | Relation |
|---|---|---|
| `backend/app/api/v1/conversation.py`, `diagnosis.py`, `knowledge.py` | Chat, diagnosis, knowledge endpoints | Implements future `API_CONTRACT.md` surface (draft) |
| `backend/app/services/chat_service.py`, `diagnosis_service.py`, `rag_service.py` | Gemini chat, XGBoost diagnosis, RAG | Sprint 2 swap targets for `AiService`/`DiagnosisService` |
| `backend/ai/models/fault_classifier.joblib` | Trained fault classifier | Mirrors `DiagnosisService` mock engine |
| `backend/ai/knowledge_base/` | FAISS index, manuals, OBD, FAQ | Mirrors `AiRepository` mock data |

## 5. Key Cross-References (reuse, not duplication)

| Inventory | Canonical source |
|---|---|
| Modules / screens | `docs/07_rc1_certification/FRONTEND_ARCHITECTURE.md` + Handbook ch10 |
| Navigation | `docs/07_rc1_certification/NAVIGATION_MAP.md` + Handbook ch12 |
| UI tokens | `docs/07_rc1_certification/UI_DESIGN_SYSTEM.md` + Handbook ch13 |
| DB | `docs/07_rc1_certification/DATABASE_BLUEPRINT.md` + Handbook ch14 |
| API | `docs/07_rc1_certification/API_CONTRACT.md` + Handbook ch15 |
| Testing | `docs/07_rc1_certification/QA_CERTIFICATION_REPORT.md` + Handbook ch16 |
| Releases / sprint history | `docs/07_rc1_certification/VERSION_HISTORY.md` + Handbook ch17 |
| Risks | `docs/01_product/RISK_ANALYSIS.md` + Handbook ch20 |
