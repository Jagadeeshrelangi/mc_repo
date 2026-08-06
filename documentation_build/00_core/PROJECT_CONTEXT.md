# PROJECT_CONTEXT — Mecha Connect

> **Documentation Build v2.1 · AI Knowledge Optimization · 2026-08-05**
> This is the FIRST file an AI should read. It builds the mental model before any detail.
> Everything below is traceable to the canonical documentation tree (see
> `CANONICAL_DOCUMENT_MAP.md`).

---

## 1. Identity

- **Project Name:** Mecha Connect
- **One-line pitch:** "Uber + Swiggy + AI Assistant" for vehicle services — an AI-powered
  roadside-assistance ecosystem for Indian vehicle owners.
- **Product:** A Flutter mobile app where a user can book a verified mechanic, order on-demand
  fuel delivery, buy spare parts, get AI-guided vehicle diagnosis, track help in real time,
  and manage profile/wallet/rewards — all in one platform.

## 2. Vision, Mission, Problem

- **Vision:** A unified on-demand vehicle-care platform connecting vehicle owners, mechanics,
  fuel partners, spare-part sellers, and (later) administrators.
- **Mission:** Make vehicle breakdowns and servicing as easy as ordering food — trusted help,
  transparent pricing, real-time tracking, in minutes.
- **Problem solved:** Breakdowns are stressful and offline — no trusted mechanic discovery,
  opaque pricing, fragmented fuel delivery, disconnected spare-part sourcing, no safety for
  stranded (especially women) drivers at night.

## 3. Current State (RC1)

| Aspect | Status |
|---|---|
| **Version** | `1.0.0+1` (RC1 release candidate) |
| **Frontend** | **Frontend Lock Candidate** — frozen 2026-08-02; UI/data-models/navigation/repository-interfaces frozen |
| **Backend** | FastAPI **scaffold exists** (conversation/diagnosis/knowledge + FAISS + XGBoost) but **NOT wired** to the app |
| **Data layer** | 100% in-memory mock repositories (simulated latency + `failForFirstCalls` failure injection) |
| **Verification** | `flutter analyze` 0 issues · `flutter test` 162/162 · web build passes |
| **Auth** | Local-only (SharedPreferences `is_logged_in`); Firebase Auth planned for Sprint 2 |
| **Networking** | Zero real HTTP calls at RC1 (UI never bypasses repositories) |

## 4. Architecture (high level)

```
Screens (50) → Providers (7 module + Theme + Location) → Repositories (7) → Mock engines
        ▲                                                        │
        └── UI never calls HTTP; repository interfaces are the frozen backend seam
```

- State: `ChangeNotifier` + `Provider`; `MultiProvider(buildRootProviders())` in `app_wiring.dart`.
- Shell: 5-tab `IndexedStack` (Home · Services · Orders · AI · Profile) with GNav bar.
- Cross-tab state via small singletons (`orderStore`/`ordersList` in `parts/order_data.dart`).
- Feature-first modules under `lib/features/`: ai, auth, home, marketplace, mechanic,
  fuel_delivery, profile.

## 5. Technology Stack

| Layer | Choice |
|---|---|
| Client | Flutter 3.29.2 · Dart ^3.7.2 · Provider 6.1.5 |
| Navigation | `google_nav_bar` (GNav) + imperative Navigator (only named route `/`) |
| Maps/Location | `flutter_map` 7.0.2 · `geolocator` 13.0.4 · `permission_handler` · `latlong2` |
| Storage | `shared_preferences` (theme, auth flag, notification settings) |
| Backend (target) | FastAPI + PostgreSQL 15 + Redis · Firebase Auth + JWT |
| AI (backend scaffold) | Gemini (`langchain-google-genai`), FAISS RAG (`sentence-transformers`), XGBoost `fault_classifier.joblib` |
| Other client deps | `flutter_dotenv`, `device_preview` (debug), `http` (unused at RC1) |

## 6. Folder Structure (lib/)

```
lib/
├── main.dart                  # entry: dotenv, root providers, MyApp, splash
├── app_wiring.dart            # buildRootProviders() — provider graph source of truth
├── theme/                     # tokens, AppTheme, ThemeProvider, responsive
├── bottom_bar/                # bottom_navigation.dart (5-tab), order_screen.dart
├── parts/order_data.dart      # orderStore + ordersList singletons
├── starting_screen/           # splash/onboarding/home dashboard/service selection
├── homescreen/drawerscreen.dart
├── services/                  # location_provider, geocoding_service, location_service
├── widgets/                   # shared: loading, location header/banner/picker, order card
└── features/{ai,auth,home,marketplace,mechanic,fuel_delivery,profile}/
```

## 7. Current Sprint & Timeline

- **Current sprint:** Documentation Build v2.1 (AI knowledge optimization) — the LAST
  documentation phase before Claude generates the handbook.
- **Product timeline:** Sprint 1 (frontend, done) → **Sprint 2 (backend integration)** →
  Sprint 3 (production polish) → Sprint 4 (partner app) → Sprint 5 (admin dashboard).
- History: built over ~2 weeks (2026-07-20 init → 2026-08-05 RC1) across sprints 1.1–1.9b.

## 8. Documentation State

- Canonical tree: `documentation_build/` — active docs in `00_core` (product/dev),
  `01_knowledge` (knowledge base + master handbook), `02_architecture` +
  `03_database` + `04_api` + `05_navigation` (frozen specs), `06_workflows`,
  `07_modules`, `08_assets`, `09_exports`; historical records in `archive/`
  (engineering_review, sprint_history, legacy).
- **Master Handbook:** 21-chapter book (md/pdf/docx) — the canonical narrative.
- **Doc build:** consolidated `documentation_build/` — one canonical doc per topic,
  full archive taxonomy (engineering_review / sprint_history / legacy).
- **Known docs debt:** root README stale/mojibake; audit proposed a restructure (migration
  NOT executed); docs use legacy screen names for some screens.

## 9. Testing State

- **162/162** tests: AI 25 · Fuel 37 · Marketplace 43 · Profile 30 · Mechanic 10 ·
  Vehicle location 8 · Home 3 · Runtime integration 2 · Widget 4.
- Module tests drive real providers over mock repos including failure paths.
- Runtime integration test uses the exact production provider graph.
- **No golden/screenshot tests** at RC1.

## 10. Known Limitations

- Backend not wired; all data mock. Marketplace/mechanic/fuel/profile endpoints not scaffolded.
- AI chat is a keyword engine (not generative) at RC1.
- Google Sign-In listed in spec but not implemented.
- Coupon validation is client-side catalog data (server validation in Sprint 2).
- Live tracking is simulated (WebSocket in Sprint 2).
- No screenshot captures yet (0/54 plan).

## 11. Future Roadmap

- **Sprint 2:** FastAPI deployment, PostgreSQL migration, API contract implementation,
  Firebase Auth, Maps integration.
- **Sprint 3:** Performance, error handling, fuller testing, a11y audit, store prep.
- **Sprint 4:** Partner app (job acceptance, tracking, earnings).
- **Sprint 5:** Admin dashboard (user mgmt, analytics, AI monitoring).
- **Post-MVP:** voice assistant, predictive maintenance, insurance integration, multi-language.

## 12. Certification Wording (critical)

Use **"Frontend Lock Candidate"** — never "RC1 Certified".
Release tag `v1.0.0-rc1` is a documented manual step, **not yet created**.
