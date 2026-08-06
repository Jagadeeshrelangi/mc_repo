# Flutter Architecture Audit — Mecha Connect

> **Phase 0 · Complete Engineering Audit · 2026-08-05**
> Scope: feature-first architecture, SOLID, Clean Architecture, Provider, Repository Pattern, Navigation.

## 1. Current State

### 1.1 Architecture overview
```
Screens (50) → Providers (7 module + Theme + Location) → Repositories (7) → Mock engines
        ▲                                                        │
        └── UI never calls HTTP; repository interfaces are the frozen backend seam
```

- **State management:** `ChangeNotifier` + `Provider`; `MultiProvider(buildRootProviders())` in `app_wiring.dart`.
- **Shell:** 5-tab `IndexedStack` (Home · Services · Orders · AI · Profile) with GNav bar.
- **Cross-tab state:** small singletons (`orderStore`/`ordersList` in `parts/order_data.dart`).
- **Feature-first modules:** ai, auth, home, marketplace, mechanic, fuel_delivery, profile.

### 1.2 Provider graph (from `app_wiring.dart`)
```
ThemeProvider
LocationProvider
AuthProvider(AuthService(AuthRepository()))
HomeProvider(HomeRepository())
MechanicProvider()
AiProvider()
ProfileProvider(ProfileRepository(NotificationSettingsStore))
FuelProvider(locationProvider:)
MarketplaceProvider()
```

## 2. Strengths

| # | Finding | Detail |
|---|---|---|
| S1 | **Single source of truth** | `app_wiring.dart` is the ONLY provider-graph definition; `main()` and the runtime regression test both build from it — no drift possible |
| S2 | **Repository Pattern consistently applied** | All 7 modules use `Provider → Repository → Mock` with the repository as the frozen backend seam |
| S3 | **SOLID — Single Responsibility** | Each provider owns exactly one module's state; services are separated (AiService, DiagnosisService, CartService, FuelService, ProfileService) |
| S4 | **SOLID — Dependency Inversion** | Providers depend on repository interfaces (constructor-injectable), not concrete HTTP clients |
| S5 | **Clean Architecture layering** | Screens → Providers → Services → Repositories → Mock engines; UI never touches data sources directly |
| S6 | **Constructor injection for testability** | `AiProvider({AiRepository?})`, `MarketplaceProvider({MarketplaceRepository?})`, `ProfileProvider({ProfileRepository?})` all support test injection |
| S7 | **Failure injection built-in** | `failForFirstCalls` in AiRepository and ProfileRepository enables deterministic error-path testing |
| S8 | **Consistent state enums** | Every module defines `initial/loading/ready/error` (plus `empty` where relevant) — uniform UI state handling |
| S9 | **Immutable model exposure** | Providers return `List.unmodifiable(...)` — screens cannot mutate provider state |
| S10 | **Navigation is imperative + consistent** | Only named route `/`; all pushes use `MaterialPageRoute` or fade routes; AI/Marketplace/Profile have `navigation.dart` helpers |

## 3. Weaknesses

| # | Finding | Severity | Detail |
|---|---|---|---|
| W1 | **Global mutable singletons** | P1 | `ordersList` (global `List<Map<String, dynamic>>`) and `orderStore` are module-level globals. This is a cross-cutting state smell — any module can mutate the list without going through a provider. |
| W2 | **`ordersList` uses `Map<String, dynamic>`** | P1 | The unified Orders tab reads untyped maps instead of a typed `OrderEntry` model. Type safety is lost; Sprint 2 schema maps to `order_entries` but the client has no typed model. |
| W3 | **Auth module has no models** | P2 | `features/auth/models/` is empty. Auth uses no typed models at RC1 (only SharedPreferences flags). |
| W4 | **`HomeProvider` is thin** | P2 | Only 63 lines — loads a single `HomeData` aggregate. Fine for RC1, but Sprint 2's `/api/v1/home` assembly endpoint will need more structure. |
| W5 | **`MechanicProvider` lacks failure injection** | P2 | Unlike Ai/Profile/Marketplace, `MechanicRepository` has no `failForFirstCalls` — error paths are less testable. |
| W6 | **`FuelProvider` hardcodes repository/service** | P2 | `final FuelRepository _repository = FuelRepository();` and `final FuelService _service = FuelService();` are NOT constructor-injectable (unlike other modules). Tests must use the real repo. |
| W7 | **`AuthProvider` stores plaintext password** | P0 | When "remember me" is enabled, `login()` writes `remember_me_password` to SharedPreferences in plaintext. This is a security issue (see SECURITY_AUDIT). |
| W8 | **No `ChangeNotifierProxyProvider`** | P3 | FuelProvider needs LocationProvider but receives it via constructor in `main()` — works, but `ProxyProvider` would be more idiomatic Provider usage. |
| W9 | **`DevicePreview` wraps MaterialApp** | P3 | `DevicePreview` is enabled in `kDebugMode` — fine for dev, but adds overhead. Acceptable. |
| W10 | **No routing table** | P2 | Only `/` is a named route; all other navigation is imperative `Navigator.push`. This works but makes deep-linking and web URL routing impossible. |

## 4. SOLID Assessment

| Principle | Verdict | Detail |
|---|---|---|
| **S**ingle Responsibility | ✅ Good | Providers own one module; services are separated |
| **O**pen/Closed | ✅ Good | Repositories are the extension point; adding a real backend = new repo internals, no screen changes |
| **L**iskov | ✅ Good | Repository interfaces are consistent; mock → real swap is transparent |
| **I**nterface Segregation | ⚠️ Partial | Repositories are concrete classes, not abstract interfaces. No `abstract class XRepository` — Sprint 2 will need interfaces for clean DI. |
| **D**ependency Inversion | ⚠️ Partial | Providers depend on concrete repository classes (constructor-injectable), not abstract interfaces. Works, but not true DIP. |

## 5. Clean Architecture Assessment

| Layer | Present? | Detail |
|---|---|---|
| Presentation (Screens/Widgets) | ✅ | 50 screens, feature widgets |
| State (Providers) | ✅ | 7 module providers + Theme + Location |
| Domain (Services) | ✅ | AiService, DiagnosisService, CartService, FuelService, ProfileService, ValidationService |
| Data (Repositories) | ✅ | 7 repositories (mock) |
| Data Sources (HTTP/DB) | ⚠️ | Mock engines only; no real HTTP at RC1 (by design) |

## 6. Navigation Audit

| Aspect | Finding | Severity |
|---|---|---|
| Named routes | Only `/` (Splash) | P2 |
| Imperative pushes | All screens use `Navigator.push` with fade routes | OK |
| Route constants | AI/Marketplace/Profile have `navigation.dart`; Fuel/Mechanic/Auth/Home use inline | P2 |
| Deep links | Not supported (no route table) | P2 |
| Web URL routing | Not supported | P2 |
| Back navigation | Works via Navigator stack | OK |
| Tab state preservation | `IndexedStack` keeps all 5 tabs alive | ✅ Good |

## 7. Risks

| # | Risk | Severity | Mitigation |
|---|---|---|---|
| R1 | Global `ordersList` mutation | P1 | Introduce a typed `OrderStore` provider in Sprint 2 |
| R2 | Concrete repositories (no interfaces) | P2 | Add `abstract class` interfaces in Sprint 2 for clean DI |
| R3 | FuelProvider not injectable | P2 | Refactor to constructor injection |
| R4 | No routing table | P2 | Add a route table for deep links in Sprint 2 |

## 8. Technical Debt

| # | Debt | Priority | Effort |
|---|---|---|---|
| TD1 | Untyped `ordersList` maps | P1 | 3 hr |
| TD2 | Global singletons | P1 | 2 hr |
| TD3 | No repository interfaces | P2 | 2 hr |
| TD4 | FuelProvider not injectable | P2 | 1 hr |
| TD5 | No routing table | P2 | 3 hr |
| TD6 | MechanicProvider no failure injection | P2 | 30 min |

## 9. Recommendations

1. **P0 — Fix plaintext password storage** (see SECURITY_AUDIT): never store passwords in SharedPreferences.
2. **P1 — Introduce typed `OrderEntry` model** for the Orders tab; replace `Map<String, dynamic>`.
3. **P1 — Replace global `ordersList`/`orderStore`** with a proper `OrderProvider` (ChangeNotifier) in Sprint 2.
4. **P2 — Add repository interfaces** (`abstract class MarketplaceRepository` etc.) for clean DI in Sprint 2.
5. **P2 — Make FuelProvider constructor-injectable** (repository + service).
6. **P2 — Add a route table** for deep links and web URL routing.
7. **P2 — Add failure injection to MechanicRepository**.

## 10. Priority Summary

| Priority | Count | Items |
|---|---|---|
| P0 | 1 | W7 (plaintext password) |
| P1 | 3 | W1, W2, R1, TD1, TD2 |
| P2 | 6 | W3, W4, W5, W6, W10, R2, R3, R4, TD3, TD4, TD5, TD6 |
| P3 | 2 | W8, W9 |