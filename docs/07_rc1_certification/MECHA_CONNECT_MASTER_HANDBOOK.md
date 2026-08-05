# Mecha Connect — Master Engineering Handbook

> **Project**: Mecha Connect — AI-Powered Roadside Assistance & Vehicle Services Platform
> **Document**: Master Engineering Handbook (Frontend Lock Candidate)
> **Status**: LOCKED — Frontend Lock Candidate (Sprint 1.9b)
> **Version**: 2.0.0 (supersedes `docs/archive/MASTER_ENGINEERING_HANDBOOK_v1.0.md`)
> **Date**: 2026-08-05 · Flutter 3.29.2
> **Classification**: Internal — All Engineers

---

## Table of Contents

1. [Engineering Overview](#1-engineering-overview)
2. [Architecture at a Glance](#2-architecture-at-a-glance)
3. [Repository Standards](#3-repository-standards)
4. [Git & Commit Standards](#4-git--commit-standards)
5. [Pull Request & Code Review](#5-pull-request--code-review)
6. [Flutter & Dart Coding Standards](#6-flutter--dart-coding-standards)
7. [State Management](#7-state-management)
8. [Theming, Typography & Responsive](#8-theming-typography--responsive)
9. [Navigation Standards](#9-navigation-standards)
10. [Accessibility Standards](#10-accessibility-standards)
11. [Performance Standards](#11-performance-standards)
12. [Mock Data & the Repository Seam](#12-mock-data--the-repository-seam)
13. [API & Data Contract](#13-api--data-contract)
14. [Database Blueprint](#14-database-blueprint)
15. [Security Standards](#15-security-standards)
16. [Testing Standards](#16-testing-standards)
17. [Documentation Standards](#17-documentation-standards)
18. [Release Management & Frontend Freeze](#18-release-management--frontend-freeze)
19. [Engineering Checklists](#19-engineering-checklists)
20. [Known Limits & Out-of-Scope for RC1](#20-known-limits--out-of-scope-for-rc1)

---

## 1. Engineering Overview

### 1.1 Mission

Mecha Connect builds the most **reliable, fast, and trustworthy** roadside
assistance and vehicle-services platform. Every screen exists to help a user
in distress: parts delivered, a mechanic booked, fuel at the door, a diagnosis
before the shop opens. The engineering bar is therefore higher than for a
typical consumer app — failure paths are first-class features.

### 1.2 Project Reality at RC1

As the Frontend Lock Candidate, the entire client is a **Flutter frontend** running on
**mock repositories** that faithfully simulate production latency and failure
so the UI behaves exactly like it will against the real backend. Sprint 2
swaps repository internals for FastAPI/PostgreSQL without touching the UI.

### 1.3 Engineering Values

| Value | Practice |
|---|---|
| **Reliability** | Every mock repository supports deterministic failure injection; loading/empty/error states are rendered and tested. |
| **Speed** | No rebuild-every-tick listeners; `context.select` for fine-grained rebuilds; lazy grids everywhere. |
| **Trust** | Transparent pricing breakdowns, honest "coming soon" copy, no dead buttons. |
| **Accessibility** | Semantics on all interactive controls; ≥44px touch targets; dark mode parity. |
| **Maintainability** | `flutter analyze` at 0 issues and 162/162 tests as the permanent bar. |

---

## 2. Architecture at a Glance

### 2.1 Stack

- **Flutter 3.29.2 / Dart** — Material 3
- **Provider 7.x + nested** — state management (`ChangeNotifier`)
- **google_nav_bar** — 5-tab bottom navigation
- **device_preview** — layout preview in `kDebugMode`
- **shared_preferences** — theme mode, login state, notification settings
- **flutter_dotenv** — env loading (best-effort, `.env` optional)
- **latlong2** — geo math for distance/haversine

### 2.2 Source Tree

```
lib/
├── main.dart                        # entry, env load, root providers, SplashScreen
├── app_wiring.dart                  # single source of truth for the provider graph
├── theme/                           # AppColors, AppSpacing/AppElevation, AppResponsive,
│                                    # ThemeProvider, AppTheme (light/dark), app_theme_helpers
├── bottom_bar/
│   ├── bottom_navigation.dart       # 5-tab GNav + IndexedStack shell
│   └── order_screen.dart            # Orders tab (listens to OrderStore)
├── parts/order_data.dart            # shared order store + ordersList singleton
├── starting_screen/                 # HomeDashboard + ServiceSelectionScreen
├── homescreen/drawerscreen.dart     # ProfileDrawer
├── services/location_provider.dart  # location + FuelProvider dependency
├── widgets/                         # shared UI (order_card, location_header, app_loading, …)
└── features/
    ├── auth/          # Login / SignUp / ForgotPassword
    ├── home/          # Home repository + models
    ├── ai/            # chat, diagnosis, history
    ├── marketplace/   # catalog, cart, checkout, wishlist, orders
    ├── mechanic/      # booking, live tracking, ratings
    ├── fuel_delivery/ # booking, tracking, invoice/receipt
    ├── profile/       # profile, vehicles, addresses, wallet, rewards
    └── vehicle_location/ # vehicle location flow
```

### 2.3 App Entry Flow

1. `WidgetsFlutterBinding.ensureInitialized()`; best-effort `.env` load.
2. `LocationProvider`, `FuelProvider`, `MarketplaceProvider` constructed first.
3. `runApp(MultiProvider(providers: buildRootProviders(...), child: MyApp()))`.
4. `MyApp` → `DevicePreview(enabled: kDebugMode)` → `MaterialApp`
   (`theme: AppTheme.light`, `darkTheme: AppTheme.dark`,
   `themeMode: themeProvider.themeMode`, `initialRoute: '/'`).
5. Splash decides the target after its timed logo sequence:

| `is_logged_in` | `onboarding_completed` | Target |
|---|---|---|
| true | — | `BottomNavigation` |
| false | true | `LoginScreen` |
| false | false | `OnboardingScreen` |

Full reference: `FRONTEND_ARCHITECTURE.md`.

---

## 3. Repository Standards

### 3.1 Layout

```
lib/features/<module>/
├── models/          # entity classes (frozen field shapes)
├── repositories/    # ONLY data access point (mock today, HTTP in Sprint 2)
├── providers/       # ChangeNotifier state machines
├── screens/         # full-screen widgets
├── widgets/         # reusable widgets for that module
├── services/        # pure logic (price math, tracking simulation)
├── utils/           # formatters, constants
└── navigation.dart  # route constants + push helpers
```

### 3.2 The Repository Seam (frozen)

- Every module has a repository that is the **only** data source.
- **Screens never call HTTP and never import backend clients.**
- Providers call repositories; widgets read providers.
- `app_wiring.dart` is the single place providers are constructed; tests build
  from it verbatim.

### 3.3 Mock Realism

- Repositories simulate latency (e.g. 700–800 ms).
- Deterministic failure injection: `failForFirstCalls(N)` throws the first N
  times, so retry/error UI is exercised by tests, not just eyeballed.
- No real network calls exist anywhere in mock paths (verified by audit).

---

## 4. Git & Commit Standards

### 4.1 Branch Naming

```
feature/<module-name>
fix/<short-description>
refactor/<module-name>
docs/<what-changed>
```

### 4.2 Commit Format (Conventional Commits)

```
<type>(<scope>): <description>

types: feat | fix | refactor | docs | test | perf | chore
```

Examples:

```
feat(mechanic): add booking confirmation screen
fix(profile): fix overflow in bio section
refactor(theme): extract color constants
docs: update sprint 1.6.4 report
```

### 4.3 Workflow Rules

1. Inspect `git status`, `git diff`, and `git log --oneline -10` before committing.
2. Stage only intended files; never commit secrets or `.env`.
3. `main` is the release branch; work is committed in logical units.
4. After any change: `flutter analyze` (0 issues) + `flutter test` (162/162).
5. Do not force-push, do not amend pushed commits, do not skip hooks.

---

## 5. Pull Request & Code Review

1. **Scope discipline** — one PR per concern; no redesigns inside bug-fix PRs.
2. **Read before edit** — understand the surrounding code and its conventions first.
3. **Verify claims** — run the analysis and the full test suite before requesting review.
4. **Checklist for reviewers**:
   - [ ] No dead code / unused imports (analyze enforces).
   - [ ] No hardcoded light-mode colors in dark-mode paths (use `context.*` getters).
   - [ ] New interactive controls have Semantics/tooltips and ≥44px targets.
   - [ ] No rebuild-every-tick listeners; `context.select` for hot rebuilds.
   - [ ] Navigation uses the module `navigation.dart` helpers; no dead routes added.
   - [ ] Tests added for state/edge cases; existing suite still 162/162.

---

## 6. Flutter & Dart Coding Standards

- **`const` constructors** everywhere possible.
- **Material 3** theming; never hardcode colors — use `context.textPrimary`,
  `context.cardBg`, `context.border`, `context.accent`, etc.
- **Spacing** from `AppSpacing`; radii/shadows from `AppElevation`; never raw
  padding/margins.
- **Responsive** via `AppResponsive.scaleFont/scaleIcon`, `responsive<T>`, and
  `ConstrainedContent` (max-width 480 wrapper) on tablet/desktop.
- **Naming**: files `snake_case.dart`, classes `PascalCase`, private builders
  `_buildX`, constants `camelCase` with `const`.
- **No `print`/`debugPrint`** unless a gated dev utility (gated utilities are
  removed at freeze).
- **Widgets** are small; private `_build*` helpers inside state classes; heavy
  screens split into private widget classes.
- **No TODO/FIXME/HACK** — resolved before commit (audit at RC1 = zero).

---

## 7. State Management

### 7.1 Provider Graph (root, in order)

| # | Provider | Notes |
|---|---|---|
| 1 | `ThemeProvider` | shared_preferences `theme_mode` |
| 2 | `LocationProvider` | injectable |
| 3 | `AuthProvider` | `AuthService(AuthRepository())` |
| 4 | `HomeProvider` | `HomeRepository()` |
| 5 | `MechanicProvider` | repository injectable |
| 6 | `AiProvider` | owns **ONE** `AiRepository` (shared with services) |
| 7 | `ProfileProvider` | `ProfileRepository(NotificationSettingsStore)` |
| 8 | `FuelProvider` | needs `LocationProvider` |
| 9 | `MarketplaceProvider` | injectable |

All providers are above `MaterialApp`, so every screen — pushed or tab —
reads the **same** instance (verified by the runtime integration test).

### 7.2 Conventions

- **Reads**: `context.read` for one-shot; `context.watch` for whole-provider
  rebuilds; **`context.select`** for field-level rebuilds (e.g. wishlist).
- **Cross-tab state**: small singletons only (`orderStore`, `ordersList`).
- **Shell**: `IndexedStack` keeps all 5 tabs mounted and stateful.
- **Timers** live inside self-contained stateful widgets and are disposed;
  never run app-wide periodic timers from a screen's `initState`.

---

## 8. Theming, Typography & Responsive

### 8.1 Tokens

- **Colors**: `AppColors` (brand `brandOrange`, semantic, light + dark palettes
  incl. `darkSurface`, `darkCard`, `darkBorder`, `darkTextTertiary`).
- **Spacing/Elevation**: `AppSpacing`, `AppElevation` (light/dark shadows).
- **Typography**: `AppTypography`; brand display font "Space Grotesk".
- **Theme mode**: `ThemeProvider` (system / light / dark), persisted.

### 8.2 Context Getter Pattern

`lib/theme/app_theme_helpers.dart` exposes `context.cardBg`, `context.border`,
`context.textTertiary`, `context.accent`, `context.divider`, … so widgets are
dark-mode safe without `Theme.of(context).brightness` branching.

### 8.3 Responsive Breakpoints

| Range | Class |
|---|---|
| < 600 | mobile |
| 600–1024 | tablet |
| ≥ 1024 | desktop |

`AppResponsive.gridColumns(context)` returns 2/3/4 based on width; grids that
need a fixed count derive it from `LayoutBuilder`/`MediaQuery` instead of a
hardcoded `crossAxisCount`.

Full reference: `UI_DESIGN_SYSTEM.md`.

---

## 9. Navigation Standards

- **Imperative** `Navigator.push(MaterialPageRoute(...))`; the only named route
  is `/` (Splash).
- Each feature has a `navigation.dart` with route constants and push helpers
  (`openWallet`, `openMyVehicles`, `openNotificationSettings`, `openSupport`,
  `aiFadeRoute`, marketplace `openProduct`, `openCategory`, …).
- Back affordance: `AppBar` leading `IconButton(tooltip: 'Back')`; conditional
  back buttons use `Navigator.canPop()` + `maybePop()`.
- **No dead routes**: every route constant is wired to a real screen (audited
  at RC1; only intentional "coming soon" snackbars remain for features that
  exist in the roadmap but not the codebase — Battery, Towing, full activity
  history, nearby service details).
- Full map: `NAVIGATION_MAP.md`.

---

## 10. Accessibility Standards

- **Icon-only buttons** carry `tooltip:` and/or `semanticLabel:`.
- **Tap targets** ≥ 48dp (44dp minimum on dense product cards) — no raw
  `GestureDetector` around a bare icon.
- **Combined semantics** — `Semantics(label: …)` + `ExcludeSemantics` for
  decorative groups (stars, carousels).
- **Reduced motion** — autoplay carousels disable when
  `MediaQuery.disableAnimationsOf(context)`.
- **Dark mode parity** — every color path checked in light and dark.
- **Screen-reader tests** — `RatingStars` merges to "Rated X out of 5";
  product-card wishlist/cart are discoverable and toggle their labels.

---

## 11. Performance Standards

- **Rebuild scoping**: `context.select` for narrow state (wishlist), never
  `context.watch<Provider>()` at the top of a whole screen if a select suffices.
- **Lazy lists**: `GridView.builder`/`ListView.builder` everywhere; `shrinkWrap`
  only inside scroll views.
- **Timers**: confined to self-contained stateful widgets (`_ElapsedTimerText`,
  `_ProgressTimeline`) so a ticking component never rebuilds a map or card.
- **Controllers**: every `TextEditingController`/`AnimationController` created
  in a widget is disposed (dialogs included).
- **No leaks** verified by audit: no pending periodic timers after route pops,
  no orphaned listeners.

---

## 12. Mock Data & the Repository Seam

| Module | Repository | Latency | Failure injection |
|---|---|---|---|
| Home | `HomeRepository` | 800 ms | via `HomeProvider` retry paths |
| AI | `AiRepository` (1 instance) | 900 ms | `failForFirstCalls` |
| Marketplace | `MarketplaceRepository` | 700 ms | load/refresh failure states |
| Mechanic | `MechanicRepository` | — | booking/tracking states |
| Fuel Delivery | `FuelRepository` | 700 ms | order lifecycle + failure |
| Profile | `ProfileRepository` | 800 ms | `failForFirstCalls` |
| Auth | `AuthRepository` | — | login state persisted on-device |

**Sprint 2 integration seams** (no UI change required):

| Seam | Today | Sprint 2 |
|---|---|---|
| Repositories | In-memory mocks | HTTP client (FastAPI/PostgreSQL) |
| `AiRepository` | Mock KB + templates | Gemini/OpenAI client |
| `ProfileRepository` | In-memory + SharedPreferences | FastAPI/PostgreSQL |
| `ordersList`/`orderStore` | Global singleton | Repository-backed feed |
| Coupon validation | Catalog data | Server-side validation |
| Real-time tracking | Simulated `TrackingInfo` | WebSocket/push |

---

## 13. API & Data Contract

- Canonical contract: `API_CONTRACT.md` (frozen for Sprint 2).
- **ID schemes** (frozen): `MKP-`, `ORD-`, `FUEL-<year>-`, `INV-`, `MEC `/`svc_`,
  `ai-`, `m-`, `diag-`, `veh-`, `addr-`, `txn-`, `rew-`, `pay-`.
- Endpoints are versioned; the UI calls only repository methods, so the
  contract can evolve without frontend changes.
- No real auth at RC1; Sprint 2 adds JWT.

---

## 14. Database Blueprint

- Canonical blueprint: `DATABASE_BLUEPRINT.md` (PostgreSQL schema for Sprint 2).
- Tables follow the frozen entity shapes in `lib/features/*/models/` plus the
  order feed in `lib/parts/order_data.dart`.
- All primary keys use the frozen ID schemes above; foreign keys reference the
  canonical entity ids (products, mechanics, fuel stations, users).

---

## 15. Security Standards

1. **No secrets in code** — `.env` is git-ignored; keys load at runtime only.
2. **No real credentials in mock paths** — audit verified zero real-HTTP calls.
3. **Input hygiene** — form validation on auth, vehicle, address, fuel quantity.
4. **On-device state** — login/theme/settings use SharedPreferences (Sprint 2
   replaces with server-backed auth).
5. **Release hygiene** — dev/debug flags (`forceShowOnboarding`, runtime trace)
   removed at freeze; `debugShowCheckedModeBanner: false`.
6. **Never log tokens or PII.**

---

## 16. Testing Standards

### 16.1 Commands

```bash
flutter analyze     # MUST report: No issues found!
flutter test        # MUST report: All tests passed! (162)
```

### 16.2 Test Inventory (162 total)

| File | Count | Coverage |
|---|---|---|
| `test/ai_module_test.dart` | 25 | AI home, chat, diagnosis, history, pin/refresh merge, retry/failure |
| `test/fuel_module_test.dart` | 37 | stations, booking, price, lifecycle, tracking, invoice, history |
| `test/marketplace_module_test.dart` | 43 | catalog, categories, cart, checkout, orders, wishlist, coupons, responsive |
| `test/profile_module_test.dart` | 30 | profile, vehicles, addresses, wallet, rewards, settings |
| `test/mechanic_module_test.dart` | 10 | mechanic list, details, booking, AI vehicle form |
| `test/vehicle_location_test.dart` | 8 | vehicle location flow |
| `test/home_dashboard_test.dart` | 3 | dashboard render + sections |
| `test/integration/runtime_marketplace_flow_test.dart` | 2 | end-to-end flow on the production provider graph |
| `test/widget_test.dart` | 4 | rating semantics, product-card touch targets + tooltips, quick-services grid |
| **Total** | **162** | |

### 16.3 Rules

- **Module tests** wrap real repositories/providers; no test-local provider
  graph for integration assertions.
- **The runtime flow test** boots `buildRootProviders()` + `MyApp` and asserts
  single-provider identity and a single `Navigator` across the whole flow.
- **Responsive tests** render at 320/360/390/412/600/768dp in light+dark and
  assert zero overflow.
- **A11y tests** assert merged semantics and touch-target sizes.
- After any change, both gates must pass before commit.

---

## 17. Documentation Standards

- **Canonical docs** live in `docs/07_rc1_certification/`; superseded material
  moves to `docs/archive/` (never deleted — history matters).
- **Active sprint reports** in `docs/05_reports/`.
- **Master navigation**: `docs/PROJECT_DOCUMENTATION_INDEX.md` + `docs/README.md`.
- **Changelog**: `docs/03_development/CHANGELOG.md` — every change gets a
  versioned entry.
- Handbooks: this document is the Frontend Lock Candidate master handbook; the
  v1.0 handbook is archived as superseded.

---

## 18. Release Management & Frontend Freeze

### 18.1 Frontend Freeze (RC1)

Per `FRONTEND_LOCK_REPORT.md`, the following are **frozen** as of Sprint 1.9b:

| Area | Rule |
|---|---|
| Colors / typography / icons / cards / layout / animation | No changes without sprint sign-off |
| Navigation structure & philosophy | Frozen |
| Data models | Frozen; backward-compatible additions only |
| Repository interfaces | Frozen (Sprint 2 backend seam) |
| Permitted changes | Runtime/UX/a11y/responsive/state bugs + docs |
| Verification required | `flutter analyze` 0 issues + `flutter test` 162/162 |

### 18.2 Release Checklist

1. [ ] `flutter analyze` → No issues found!
2. [ ] `flutter test` → 162/162 passing
3. [ ] No dead code / orphan files (audited)
4. [ ] No dev flags or runtime trace wiring in `main.dart`
5. [ ] Docs updated (changelog, index, RC1 reports)
6. [ ] Commits follow Conventional Commits on `main`
7. [ ] Tag milestone for the release (RC1 tag deferred per sprint plan)

---

## 19. Engineering Checklists

### Pre-Commit

- [ ] `dart format` applied to touched files
- [ ] `flutter analyze` — 0 issues
- [ ] `flutter test` — 162/162
- [ ] No RenderFlex overflow at 320/360/412/600/768dp, light + dark
- [ ] No dangling imports, no TODO/FIXME/HACK
- [ ] Interactive controls have tooltips/semantics and ≥44dp targets
- [ ] Controllers/timers disposed

### Pre-Freeze (already satisfied at RC1)

- [ ] All navigation destinations resolve to real screens
- [ ] No real HTTP in mock paths
- [ ] Single provider graph verified at runtime
- [ ] Dead code removed
- [ ] A11y + dark-mode regressions verified

---

## 20. Known Limits & Out-of-Scope for RC1

- All data is **mock/in-memory**; Sprint 2 replaces repository internals
  (contract: `API_CONTRACT.md`).
- Real-time tracking is **simulated** (`TrackingInfo` from in-memory state).
- Coupons are **not server-validated**.
- No real **auth backend** (login state persisted on-device only).
- Roadmap features intentionally showing "coming soon": Battery service,
  Towing, full activity history, nearby service details.
- Home teaser cards (marketplace / nearby / activity) are **intentional static
  placeholders** with no entity IDs; wiring them to real screens is Sprint 2
  scope, not a defect.
- Backend (FastAPI + PostgreSQL) does not exist yet — it is the Sprint 2 build
  target behind the frozen repository interfaces.
- **Accepted contrast limits** (final-review audit): white on `brandOrange`
  ≈ 3.37:1 and `darkPrimary` ≈ 2.86:1 fall below WCAG AA for body text. Kept
  as brand-mandated; UI screen text already uses darker tokens on light
  backgrounds. Approved for RC1, revisit with design sign-off in Sprint 2.
- **P3 visual debt** (does not block RC1): a few legacy screens still carry
  hardcoded hex colors or off-scale radii (`main.dart`, `auth_scaffold.dart`,
  `starting_screen/`, `emergency_card.dart`, `mechanic_home_screen.dart`);
  audit replaced star colors (`Color(0xFFF59E0B)` → `AppColors.warning`).
- **Rating-shorthand guard**: review stars derive initials via
  `review.author.substring(0, 1)`; safe with current mock data, guard required
  once real backend data arrives (P3).

---

## Related Documents

- `FRONTEND_LOCK_REPORT.md` — freeze governance
- `QA_CERTIFICATION_REPORT.md` — certification evidence
- `PROJECT_STATUS_REPORT.md` — RC1 status, next steps, risks
- `FRONTEND_ARCHITECTURE.md` — provider graph, module tree, seams
- `UI_DESIGN_SYSTEM.md` — frozen design tokens
- `NAVIGATION_MAP.md` — full navigation maps
- `API_CONTRACT.md` — Sprint 2 API contract
- `DATABASE_BLUEPRINT.md` — Sprint 2 schema
- `../03_development/CONTRIBUTING.md` — Git/PR workflow
- `../03_development/TEST_PLAN.md` — test strategy
- `../03_development/INSTALLATION.md` — local setup
- `../03_development/CHANGELOG.md` — version history
- `../archive/MASTER_ENGINEERING_HANDBOOK_v1.0.md` — superseded v1.0
