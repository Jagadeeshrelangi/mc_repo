# MASTER PROJECT KNOWLEDGE BASE — Mecha Connect

> **Documentation Build Sprint v2.1 (AI Knowledge Optimization) · 2026-08-05**
> Merged, AI-consumable knowledge compiled from the official docs tree + repo scan.
> Every claim traces to a canonical source listed in `CANONICAL_DOCUMENT_MAP.md`.
> Reused, not duplicated. See `01_knowledge/README.md` for how to use this file.

---

## 0. How to Use This Knowledge Base

1. **Read `PROJECT_OVERVIEW.md` first** — the v2.1 mental-model builder (the FIRST file an AI should read).
2. **Read `KNOWLEDGE_GRAPH.md` second** — the v2.1 structured relationship map (12 domain chains).
3. **Then read this file** — the merged, deep-detail knowledge base.
4. For deep detail, open the referenced folder by number:
   `frontend/architecture/diagrams/` (visuals), `frontend/modules/`,
   `frontend/workflows/`, `backend/Database.md`, `backend/API.md`,
   `frontend/Navigation.md`, `common/GLOSSARY.md`.
5. Machine-readable facts live in `09_exports/*.json` (v2.1: `knowledge_graph.json` regenerated).
6. If a fact matters for the handbook, it is cited as `[chN]` (Master Handbook
   chapter) or `[src: <doc>]`.
7. **Engineering audit (Phase 0) is APPROVED** — see `archive/engineering_review/AUDIT_SUMMARY.md` for the Sprint 2 baseline.

---

## 1. Project Snapshot

| Field | Value |
|---|---|
| Product | **Mecha Connect** — "Uber + Swiggy + AI Assistant" for vehicle services |
| Mission | AI-powered roadside assistance ecosystem (owners ↔ mechanics ↔ fuel partners ↔ spare-part sellers) |
| Stack (client) | Flutter 3.29.2, Dart ^3.7.2, Provider, google_nav_bar, flutter_map, geolocator |
| Stack (backend, Sprint 2) | FastAPI + PostgreSQL 15 + Redis, Firebase Auth + JWT, Gemini/FAISS/XGBoost (scaffold exists) |
| App version | `1.0.0+1` (RC1 release candidate) |
| Frontend status | **Frontend Lock Candidate** (frozen 2026-08-02; report `FRONTEND_LOCK_REPORT.md`) |
| Verification | `flutter analyze` 0 issues · `flutter test` **162/162** |
| Data layer today | 100% in-memory mock repositories (simulated latency + failure injection) |
| Repo | `github.com/Jagadeeshrelangi/mc_repo` (branch `main`) |
| Handbook | 21-chapter book (md/pdf/docx) — canonical narrative |

## 2. Product Knowledge

### 2.1 Vision & Positioning [src: PRODUCT_REQUIREMENTS_DOCUMENT]
On-demand vehicle care for Indian owners: book a verified mechanic, order fuel
delivery, buy spare parts, and get AI diagnosis — all in one app.

### 2.2 Personas
- **Rajesh** (28, daily commuter, Hyderabad, Activa) — needs a verified mechanic in <10 min.
- **Priya** (32, Bangalore, i10) — night-safety: tracked arrival, SOS, verified profiles.
- **Vikram** (40, Chennai, 10 delivery bikes) — bulk booking, cost tracking, ratings.

### 2.3 USP
1. AI-powered diagnosis before booking (symptoms → fault + cost estimate)
2. End-to-end booking (diagnosis → payment)
3. Multi-service ecosystem (Mechanic + Fuel + Parts)
4. Real-time tracking of help
5. Verified professionals with transparent pricing

### 2.4 Monetization model (internal only)
Revenue model, unit economics, CAC/AOV/LTV, and pricing/margins are
confidential and maintained only in the internal business documentation —
never in public docs.

### 2.5 Feature scope reality (docs vs code)
- In scope & **done**: Splash, Onboarding, Auth, Home Dashboard, Mechanic Booking (full),
  AI Diagnosis/Chat, Fuel Delivery, Marketplace (parts), Profile (wallet/rewards/vehicles/addresses),
  Dark Mode, Responsive Layout, 5-tab shell.
- PRD marks Fuel Delivery + Marketplace as "Sprint 2" but **both shipped in the RC1 frontend** (mock).
- Backend: **not wired at RC1**; UI never bypasses repositories. Sprint 2 swaps repo internals.

## 3. Architecture Knowledge [src: frontend/Architecture.md]

### 3.1 Layer Rule (frozen)
Screens → Providers (`ChangeNotifier`) → Repositories → **mock engines**.
- Repositories are the **only** data source; screens never call HTTP.
- Sprint 2 swaps repository internals for FastAPI clients — **UI + provider signatures unchanged**.

### 3.2 App Entry (`frontend/lib/main.dart`)
```
main() → dotenv.load (best-effort) → providers → runApp(MultiProvider(buildRootProviders))
MyApp → DevicePreview(enabled: kDebugMode) → MaterialApp(theme/darkTheme/themeMode, '/')
        → SplashScreen → {loggedIn: BottomNavigation | onboarding done: LoginScreen | else: Onboarding}
```
Splash→next uses a 450ms fade `pushReplacement`. No dev flags remain.

### 3.3 Provider Graph (`frontend/lib/app_wiring.dart`) — single source of truth
| # | Provider | Constructed with |
|---|---|---|
| 1 | `ThemeProvider` | ChangeNotifierProvider(create) |
| 2 | `LocationProvider` | injectable or default |
| 3 | `AuthProvider` | `AuthService(AuthRepository())` |
| 4 | `HomeProvider` | `HomeRepository()` |
| 5 | `MechanicProvider` | default (repo injectable) |
| 6 | `AiProvider` | owns ONE `AiRepository` (shared with AiService + DiagnosisService) |
| 7 | `ProfileProvider` | `ProfileRepository(SharedPreferencesNotificationSettingsStore)` |
| 8 | `FuelProvider` | `FuelProvider(locationProvider: location)` |
| 9 | `MarketplaceProvider` | injectable or default |

Injection points for tests: Location, Fuel, Marketplace, Profile.
Non-provider singletons: `orderStore` (OrderStore), `ordersList` (in `frontend/lib/parts/order_data.dart`).

### 3.4 Tab Shell (frozen) [src: NAVIGATION_MAP]
`BottomNavigation` = `IndexedStack` (all tabs stay mounted) + GNav bar.
| Tab | Screen |
|---|---|
| 0 Home | `HomeDashboard` |
| 1 Services | `ServiceSelectionScreen` (cards → Mechanic / Fuel / Marketplace) |
| 2 Orders | `Orderscreen` (reads `OrderStore`) |
| 3 AI | `AiHomeScreen` |
| 4 Profile | `ProfileScreen` |

### 3.5 Feature Modules (7) — 50 screens, 39 models, 7 providers, 7 repos
| Module | Repo latency | Key screens |
|---|---|---|
| ai | 900ms | AiHome, Chat, Diagnosis, History, ConversationDetail |
| marketplace | 700ms | Home, Category, ProductDetail, Cart, Checkout, OrderSuccess, Search, Wishlist |
| mechanic | per method | Home, Nearby, Details, SelectService, BookingSummary/Confirmation, LiveTracking, RatingReview, JobCompleted, History |
| fuel_delivery | 700ms | Home, Booking, Payment, Confirmation, LiveTracking, Complete, Receipt, History |
| profile | 800ms | Profile, Edit, Vehicles, VehicleDetail, Addresses, Wallet, Rewards, Orders, NotificationSettings, Privacy, Support, About |
| auth | — | Login, SignUp, ForgotPassword |
| home | 800ms | Home dashboard, HomeSearch |

Cross-module: mechanic `VehicleForm` uses AI module's `DiagnosisService` (mock, no HTTP).
Marketplace checkout writes the Orders tab via `addMarketplaceOrder` + `orderStore.notify()`.

### 3.6 ID schemes (frozen) [src: backend/API.md]
`MKP-<year>-<0000>` · `p-*` · `coupon-*`/`offer-*` · `rv-*`/`r*` · `ORD-*` · `FUEL-<year>-<0000>`
`station_*`/`partner_*` · `INV-<orderId>` · `svc_*` · `m*` · `ai-*` · `m-*` · `diag-*`
`veh-*` (counter 200) · `addr-*` (counter 200) · `txn-*` · `rew-*` · `pay-*`.

### 3.7 Frozen frontend scope (RC1)
Shell & navigation, design system tokens, feature modules, data models,
repository interfaces — all frozen. Permitted changes: bugs, a11y, responsive,
state fixes, docs. Verification gate after any change: analyze 0 + tests 162/162.

## 4. Data Layer Knowledge [src: DATABASE_BLUEPRINT]

### 4.1 Current (mock) reality
All entities live in `frontend/lib/features/*/models/` + repository seed data. Seed facts:
- HomeData: quick services, nearby, marketplace items, activities, offers.
- Marketplace catalog: **40 products, 10 categories, 15 brands, 3 offers, 3 coupons**.
- Mechanics: **4** (`m1`–`m4`, one unavailable), 3 featured, reviews `r1`–`r8`, 8 categories, 8 services.
- Fuel: 6 stations, 3 saved vehicles, seed orders `FUEL-2026-0005..0009`, invoice `INV-<orderId>`.
- AI: 5 seed conversations (`ai-0001`..`0005`), 2 pinned.
- Profile: Jagadeesh Gowda (Pro), vehicles `veh-101/102`, addresses `addr-101/102`,
  wallet 1200, 2450 pts, rewards 2450 redeemable, 12 services, referral `GOWDA200`.

### 4.2 Target schema (PostgreSQL, Sprint 2)
Core: `users`, `vehicles`, `addresses`, `wallet`, `wallet_transactions`, `reward_ledger`,
`notification_settings`.
Marketplace: `categories`, `brands`, `products` (+ `product_specifications`,
`product_vehicle_types`, `product_compatibility`, `product_reviews`), `offers`, `coupons`.
Orders: `orders` (parent) + `order_items` + `order_entries` (**unified Orders-tab feed**).
Mechanic: `mechanics` (+skills/languages/working_hours), `mechanic_services`,
`mechanic_categories`, `mechanic_reviews`, `mechanic_bookings`, `booking_events` (+`ratings`).
Fuel: `fuel_orders`, `price_estimates`, `fuel_stations`, `fuel_partners`,
`tracking_events`, `invoices`.
AI: `conversations`, `chat_messages`, `diagnoses`.

Client→schema mapping notes: client `ordersList` ↔ `order_entries`; `ProfileStats.orders`
= count(order_entries); `is_logged_in` + `theme_mode` stay on-device.

## 5. API Knowledge [src: backend/API.md]

- Base path `/api/v1` (Sprint 2 target). Latency + `failForFirstCalls` conventions
  must be honored so loading/empty/error UI stays exercisable.
- Backend scaffold already exists: `backend/app/api/v1/{conversation,diagnosis,knowledge}.py`,
  services (`chat_service`, `diagnosis_service`, `rag_service`), schemas, FAISS KB, XGBoost
  `fault_classifier.joblib` — mirrors the contract's AI surface.
- Auth today: local-only via SharedPreferences `is_logged_in`; no credentials stored.
- Full method surface per module: see `backend/API.md`.

## 6. Navigation Knowledge [src: frontend/Navigation.md]

- Only named route: `/` → Splash. Everything else imperative `Navigator.push`
  (`MaterialPageRoute`, `aiFadeRoute` 220ms, `profileFadeRoute` 220/180ms).
- AI routes: `/ai`, `/ai/chat`, `/ai/diagnosis`, `/ai/history`, `/ai/conversation`.
- Profile routes: `/profile` + 11 sub-routes (`/profile/edit|vehicles|vehicles/detail|addresses|wallet|rewards|orders|notifications|privacy|support|about`).
- Marketplace routes: `/marketplace`, `/marketplace/product|category|search|cart|wishlist`.
- Cross-module edges (frozen): AI → Mechanic/Fuel/Marketplace (action buttons);
  Marketplace checkout → Orders tab; Profile → Auth (logout `pushAndRemoveUntil`);
  Orders → Services ("Explore Services").

## 7. Design System [src: frontend/Design_System.md]

- Brand: `brandOrange #F15A22` family + `brandBlue #4285F4` family; gradient `#F15A22→#D44A15`.
- Dark palette is premium, not inversion (`darkBg #0E1117`, `darkCard #1A1D24`, `darkPrimary #FF6A2A`).
- Semantic: success `#10B981`, error `#EF4444`, warning `#F59E0B`, info `#3B82F6`.
- Spacing: 4px base scale (`xxs 2`…`hero 64`); radii `6/10/14/18/22/28/full`; elevation 0–5.
- Typography: Space Grotesk for display headings, platform default body; responsive scale clamped 0.88–1.2.
- Responsive: mobile 600 / tablet 1024 breakpoints; `ConstrainedContent` max 480.
- Theme mode: `ThemeMode.system` default, persisted as `theme_mode` (SharedPreferences).
- UI patterns: pill buttons, rounded cards, skeleton loaders, branded error/empty states,
  GNav active = accent @ 8% bg, Semantics on interactive controls.

## 8. Testing & QA [src: QA_CERTIFICATION_REPORT, FRONTEND_LOCK_REPORT]

- **162/162** tests, broken down: AI 25 · Fuel 37 · Marketplace 43 · Profile 30 ·
  Mechanic 10 · Vehicle location 8 · Home dashboard 3 · Runtime integration 2 · Widget 4.
- Module tests drive real providers over mock repos incl. failure injection.
- Runtime integration test uses the exact production `buildRootProviders()` graph.
- `flutter analyze` → 0 issues. Build web passes; no RenderFlex overflows; responsive verified.
- **No golden/screenshot tests at RC1** (Phase 6 screenshot workspace is forward-looking).

## 9. Release & Status [src: VERSION_HISTORY, PROJECT_STATUS_REPORT, RC1_RELEASE_REPORT]

- RC1 version `1.0.0+1` (2026-08-05); tag `v1.0.0-rc1` is a documented manual step (not yet created).
- Road: 0.0.1 (Init) → 0.1.0 (1.1–1.3) → 0.4.0 (1.6 booking) → 1.2.0 (1.7A fuel) →
  1.9.0 (RC1 cert) → 1.9.1/1.9.2 (polish/final review) → 1.0.0+1 RC1.
- Next: **Sprint 2** — FastAPI deployment, PostgreSQL migration, API contract
  implementation, Firebase Auth, Maps integration. Sprint 3 production polish;
  Sprint 4 partner app; Sprint 5 admin dashboard.
- Certification wording discipline: "Frontend Lock Candidate", never "RC1 Certified".

## 10. Risks & Debt [src: RISK_ANALYSIS]

Top risks: R1 GPS denied/disabled (high severity, high likelihood) — graceful state
machine + manual entry fallback; R2 network failure during booking — offline queue + retry;
R3 mechanic no-show — penalty + auto-reassign; R4 AI misdiagnosis — confidence<60% disclaimer;
R9 location permission denied — explain + manual entry.
Debt: TD1 `starting_screen/` naming; TD3 mock data hardcoded (→Sprint 2); TD4 no backend error
handling in UI (→Sprint 2).

## 11. Key Cross-Cutting Facts (memorize)

1. Repositories = sole data source; mock realism via latency + `failForFirstCalls`.
2. `orderStore`/`ordersList` singletons power the Orders tab + Profile order history (single source).
3. `IndexedStack` keeps all 5 tabs alive → offstage widgets remain findable in tests.
4. AI module shares ONE `AiRepository` across provider/service/diagnosis.
5. Mechanic VehicleForm runs AI mock diagnosis (no HTTP) since 1.9b.
6. Money = `double` INR (₹); timestamps ISO-8601 on wire payloads.
7. Vehicles/addresses always sort default-first (frozen ordering).
8. All module widget counts, providers, repos, services, models: `archive/legacy/01_inventory/project_inventory.md`.
