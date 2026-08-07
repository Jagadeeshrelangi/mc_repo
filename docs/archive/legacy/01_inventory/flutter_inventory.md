# Flutter Inventory — Mecha Connect

> Phase 1 · 2026-08-05

## 1. Framework

| Item | Value |
|---|---|
| Flutter | 3.29.2 |
| Dart SDK constraint | `^3.7.2` |
| App version | `1.0.0+1` |
| UI approach | Feature-first modules under `lib/features/`, 5-tab shell (Home/Services/Orders/AI/Profile) |
| State management | Provider (7 module providers + Theme + Location) |
| Networking | none to backend at RC1 (mock repositories) |
| Local storage | `shared_preferences` (theme mode, auth session) |

## 2. Entry & Wiring

- `lib/main.dart` — `main()`:
  1. `dotenv.load()` in try/catch (logs `ENV LOAD FAILED` on failure)
  2. Creates `LocationProvider`, `FuelProvider(locationProvider: ...)`, `MarketplaceProvider`, `ProfileProvider`
  3. `runApp(MultiProvider(providers: buildRootProviders(), child: MyApp()))`
  4. `MyApp` wraps MaterialApp with `enableDevicePreview = kDebugMode` (DevicePreview in debug only)
  5. Route `/` → SplashScreen; `navigatorObservers` for tab navigation
- `lib/app_wiring.dart` — `buildRootProviders()` returns the **production provider graph**:
  - `LocationProvider`, `FuelProvider(location: ...)`, `MarketplaceProvider`, `ProfileProvider`
  - **Single source of truth** — the runtime integration test (`test/integration/runtime_marketplace_flow_test.dart`) exercises the exact same graph.

## 3. Top-Level / Shared

| Path | Purpose |
|---|---|
| `lib/theme/` | Design tokens, light/dark themes, `ThemeProvider` |
| `lib/widgets/` | Shared widgets (loading, order card, location card) |
| `lib/parts/order_data.dart` | `OrderStore` — cross-module order state |
| `lib/services/` | `location_provider.dart` (LocationProvider), `geocoding_service.dart` (GeocodingService) |
| `lib/bottom_bar/` | `BottomNavigation` 5-tab shell + Orders screen |
| `lib/starting_screen/` | Onboarding flow + splash decision |

## 4. Tab Shell (Navigation)

5 tabs (frozen, `lib/bottom_bar/bottom_navigation.dart` + `docs/07_rc1_certification/NAVIGATION_MAP.md`):
1. **Home** — `HomeDashboard`
2. **Services** — `ServiceSelectionScreen` (cards → Mechanic / Fuel / Marketplace)
3. **Orders** — `Orderscreen` (shared `OrderStore`, grouped All/Parts/Mechanic/Fuel/AI)
4. **AI** — `AiHomeScreen`
5. **Profile** — `ProfileScreen`

Body is an `IndexedStack` keeping all tabs mounted; switch animation 250ms (GNav).
Order data shared via `OrderStore` (`lib/parts/order_data.dart`).

## 5. Design System

- Canonical source: `docs/07_rc1_certification/UI_DESIGN_SYSTEM.md` + Handbook ch13.
- Light/dark theme with a small token set; theme toggle persisted via `shared_preferences`.
- Module-specific widget counts: see `project_inventory.md` §3 (79 widgets across 7 modules + shared widgets).

## 6. Test Support (this is test inventory, not app code)

- 9 test files (see `tests.md`) — 8 module-focused + 1 integration that uses the real `buildRootProviders()` graph.
- `flutter test` baseline: **162/162 passing** at RC1.
