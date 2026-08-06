# PROJECT OPERATING MANUAL — Mecha Connect

> **Documentation Build v2.1 · AI Knowledge Optimization · 2026-08-05**
> How to operate, build, test, and continue the project.

## 1. Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| Flutter | 3.29.2 | Client app build + test |
| Dart | ^3.7.2 | Language |
| Python | 3.11+ | Backend (FastAPI, Sprint 2) |
| PostgreSQL | 15 | Database (Sprint 2) |
| Docker | latest | Containerization (Sprint 2) |
| Node.js | 18+ | Diagrams (mmdc) |
| VS Code | latest | IDE |

## 2. Project Structure

```
c:/mecha_connect - opencode/
├── lib/                    # Flutter source (233 files, 7 modules)
│   ├── main.dart           # Entry point
│   ├── app_wiring.dart     # Provider graph (buildRootProviders)
│   ├── auth/               # Auth widgets (8 files)
│   ├── bottom_bar/         # 5-tab shell (IndexedStack + GNav)
│   ├── features/           # 7 feature modules
│   ├── homescreen/         # Home dashboard
│   ├── parts/              # Shared parts (order_data.dart)
│   ├── services/           # Shared services
│   ├── starting_screen/    # Splash + onboarding
│   ├── theme/              # Design system + dark mode
│   └── widgets/            # Reusable widgets
├── test/                   # 162 tests (9 files + integration)
├── backend/                # FastAPI scaffold (NOT wired)
│   ├── app/main.py         # App factory + CORS + exception handler
│   ├── app/api/v1/         # conversation, diagnosis, knowledge
│   ├── app/services/       # chat_service, diagnosis_service, rag_service
│   └── ai/                 # FAISS index, XGBoost model, knowledge base
├── assets/                 # 18 image assets
├── documentation_build/    # Canonical documentation (see documentation_build/README.md)
├── pubspec.yaml            # Flutter dependencies
└── README.md               # Root README (canonical landing page)
```

## 3. Build & Test Commands

```bash
# Frontend
flutter pub get
flutter analyze          # must be 0 issues
flutter test             # must be 162/162
flutter run -d chrome    # web preview
flutter build apk        # Android build
flutter build ios        # iOS build

# Backend (Sprint 2)
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload

# Diagrams (mmdc)
mmdc -i diagrams/system_architecture.mmd -o diagrams/svg/system_architecture.svg
```

## 4. Architecture Rules (FROZEN)

1. **Layer rule:** Screens → Providers (ChangeNotifier) → Repositories → mock engines.
2. **Repositories are the ONLY data source** — screens never call HTTP directly.
3. **Single provider graph** — `buildRootProviders()` in `app_wiring.dart`.
4. **9 root providers** — Theme, Location, Auth, Home, Mechanic, AI, Profile, Fuel, Marketplace.
5. **5-tab shell** — IndexedStack keeps all tabs alive; GNav bar.
6. **AI module shares ONE AiRepository** across provider/service/diagnosis.
7. **orderStore/ordersList singletons** power Orders tab + Profile order history.
8. **ID schemes frozen** — MKP-, p-, ORD-, FUEL-, veh-, addr-, txn-, rew-, pay-, etc.
9. **Money = double INR (₹); timestamps ISO-8601.**
10. **Verification gate:** any change must pass `flutter analyze` (0) + `flutter test` (162/162).

## 5. Testing Protocol

- **Module tests** drive real providers over mock repos (incl. failure injection).
- **Runtime integration test** uses the exact production `buildRootProviders()` graph.
- **Test breakdown:** AI 25 · Fuel 37 · Marketplace 43 · Profile 30 · Mechanic 10 · Vehicle location 8 · Home 3 · Integration 2 · Widget 4.
- **No golden/screenshot tests at RC1** (Phase 6 workspace is forward-looking).

## 6. Documentation Rules

1. **`documentation_build/` is canonical** — one source of truth per topic (see CANONICAL_DOCUMENT_MAP.md).
2. **`archive/` is read-only** — historical records; reference only as history.
3. **Handbook is Version 1** — v2.1 prepares enrichment, does NOT regenerate.
4. **Entry order for AI:** PROJECT_CONTEXT → KNOWLEDGE_GRAPH → MASTER_PROJECT_KNOWLEDGE_BASE → MASTER_PROJECT_DATA.json → AUDIT_SUMMARY.
5. **Do NOT invent** architecture, APIs, workflows, screen names, seed data, or numbers.
6. **Do NOT fabricate** screenshots.

## 7. Phase Gates

| Phase | Gate | Status |
|---|---|---|
| Phase 0 — Engineering Audit | Approval | ✅ APPROVED 2026-08-05 |
| Phase 4 — Documentation Build v2.1 | Completion report approval | ⏸️ Pending |
| Phase 5 — Master Handbook | v2.1 approval | ⏸️ Blocked |
| Phase 6 — Repository Cleanup | Migration plan approval | ⏸️ Pending |
| Phase 7 — Git Milestone | Explicit approval | ⏸️ Blocked |
| Phase 8 — Sprint 2 | Audit P0 items fixed | ⏸️ Blocked |

## 8. Known Issues

- Plaintext password in SharedPreferences (P0)
- Zero backend tests (P0)
- No Alembic migrations (P0)
- GEMINI_API_KEY validity unverified (P0)
- Mock auth bypass (P0)
- No auth tests (P0)
- No CI/CD, Docker, auth middleware (P1)
- Root README stale (P1)
- Fonts not bundled (P1)

## 9. Contacts

- **Repo owner:** Jagadeesh Relangi
- **GitHub:** `github.com/Jagadeeshrelangi/mc_repo`
- **Branch:** `main`
- **Latest commit:** `84b68f5c6884e8b5dd3b12f58c76ca6b18d1b343`

## 10. Quick Reference

- **Frontend status:** Frontend Lock Candidate (frozen 2026-08-02)
- **Tests:** 162/162 passing
- **Analyze:** 0 issues
- **Version:** 1.0.0+1 (RC1)
- **Flutter:** 3.29.2 / Dart ^3.7.2
- **Backend:** FastAPI scaffold (NOT wired)
- **Database:** PostgreSQL 15 (schema.sql ready, no migrations)
- **AI:** Gemini + FAISS + XGBoost (scaffold exists)
- **Auth:** Firebase Auth + JWT (planned Sprint 2)