# Testing Audit — Mecha Connect

> **Phase 0 · Complete Engineering Audit · 2026-08-05**
> Scope: coverage, missing tests, widget/integration tests, failure paths, regression coverage.

## 1. Current State

- **162/162 tests passing** (frozen baseline).
- **9 test files** in `test/` + 1 in `test/integration/`.
- **Distribution:** AI 25 · Fuel 37 · Marketplace 43 · Profile 30 · Mechanic 10 · Vehicle location 8 · Home 3 · Integration 2 · Widget 4.

### 1.1 Test file inventory
| File | Tests | Scope |
|---|---|---|
| `test/ai_module_test.dart` | 25 | AiRepository, AiProvider, AiService, DiagnosisService, AI screens |
| `test/fuel_module_test.dart` | 37 | FuelRepository, FuelProvider, FuelService, Fuel screens |
| `test/marketplace_module_test.dart` | 43 | MarketplaceProvider, CartService, screens, checkout |
| `test/profile_module_test.dart` | 30 | ProfileRepository, Provider, validation, screens |
| `test/mechanic_module_test.dart` | 10 | MechanicProvider, validator, screens |
| `test/vehicle_location_test.dart` | 8 | Location flow, VehicleFormScreen |
| `test/home_dashboard_test.dart` | 3 | HomeDashboard, LocationCard, HomeSearch |
| `test/integration/runtime_marketplace_flow_test.dart` | 2 | Real provider-graph runtime flow |
| `test/widget_test.dart` | 4 | Shared widget semantics & touch targets |

## 2. Strengths

| # | Finding | Detail |
|---|---|---|
| S1 | **Module tests drive real providers over mock repos** | Each module test constructs the actual provider with a fast (zero-latency) repo — not fake providers |
| S2 | **Failure injection tested** | `_fastRepo(failForFirstCalls: 1)` proves error paths work |
| S3 | **Pull-to-refresh last-known-good tested** | `_FlakyRefreshRepo` proves a failed refresh never wipes data |
| S4 | **Runtime integration test uses production graph** | `buildRootProviders()` — NOT a test-local wrapper; catches provider-scope bugs |
| S5 | **Single-navigator assertion** | Integration test proves all marketplace screens share ONE Navigator |
| S6 | **Accessibility tested** | 44px touch targets, merged semantics, tooltips |
| S7 | **Responsive overflow tested** | 320px narrow screen test |
| S8 | **Consistent test helpers** | `_wrap()`, `_fastRepo()`, `_FakeLocationProvider` patterns across files |
| S9 | **Real SharedPreferences mock** | `SharedPreferences.setMockInitialValues` used correctly |

## 3. Weaknesses

| # | Finding | Severity | Detail |
|---|---|---|---|
| W1 | **No backend tests (zero)** | P0 | `backend/` has no `test/` or `tests/` dir. FastAPI endpoints, ChatService, DiagnosisService, RAGService are 0% tested. |
| W2 | **No auth module tests** | P1 | `AuthProvider`/`AuthService`/`AuthRepository` have zero direct tests. Auth is the security-critical path. |
| W3 | **No coverage measurement** | P1 | No `lcov`, no coverage target, no coverage gate. Actual line coverage unknown. |
| W4 | **No golden/screenshot tests** | P2 | 0/54 screenshot plan; no visual regression guard. |
| W5 | **Mechanic module under-tested (10)** | P2 | 11 screens but only 10 tests — live tracking, rating, invoice flows not deeply tested. |
| W6 | **Home module under-tested (3)** | P2 | 2 screens but only 3 tests. |
| W7 | **No performance/benchmark tests** | P2 | No rebuild-count assertions, no `tester.takeException()` beyond narrow cases. |
| W8 | **No test for orders tab (Orderscreen)** | P2 | `bottom_bar/order_screen.dart` — unified Orders feed has no dedicated test file (covered indirectly via marketplace/profile orders tests). |
| W9 | **No security tests** | P2 | No tests asserting passwords are NOT persisted, no validation edge cases for malicious input. |
| W10 | **`AuthRepository` always returns true** | P1 | Mock auth never fails — error paths (invalid credentials) untestable. |

## 4. Coverage Estimate (gaps)

| Area | Tested? | Gap |
|---|---|---|
| AI module | ✅ 25 | Good |
| Fuel module | ✅ 37 | Good |
| Marketplace | ✅ 43 | Good |
| Profile | ✅ 30 | Good |
| Mechanic | ⚠️ 10 | Live tracking/rating flows |
| Vehicle location | ✅ 8 | Good |
| Home | ⚠️ 3 | Thin |
| Widgets | ✅ 4 | Shared widgets only |
| Integration | ✅ 2 | Marketplace runtime only |
| Auth | ❌ 0 | **Critical gap** |
| Orders tab | ⚠️ 0 direct | Indirect only |
| Backend | ❌ 0 | **Critical gap** |
| Failure paths (Mechanic/Fuel/Auth) | ❌ | No failForFirstCalls in these repos |

## 5. Risks

| # | Risk | Severity | Mitigation |
|---|---|---|---|
| R1 | Auth + backend untested | P0 | Add tests in Sprint 2 |
| R2 | No coverage gate | P1 | Add `--coverage` + lcov in CI |
| R3 | Visual regression unguarded | P2 | Golden tests in Sprint 3 |

## 6. Technical Debt

| # | Debt | Priority | Effort |
|---|---|---|---|
| TD1 | No backend tests | P0 | 1 day |
| TD2 | No auth tests | P1 | 4 hr |
| TD3 | No coverage measurement | P1 | 1 hr |
| TD4 | Orders tab direct tests | P2 | 2 hr |
| TD5 | Golden tests | P2 | 1 day |

## 7. Recommendations

1. **P0 — Add backend tests**: pytest + httpx TestClient for diagnosis/knowledge/conversation endpoints + service unit tests.
2. **P1 — Add auth tests**: login/register/forgot/logout, validation, password strength, remember-me behavior.
3. **P1 — Add coverage gate**: `flutter test --coverage` + enforce ≥80% in CI.
4. **P2 — Add Orders tab direct tests**.
5. **P2 — Add golden tests** for key screens in Sprint 3.
6. **P2 — Add MechanicRepository failForFirstCalls** + failure-path tests.
7. **P2 — Add security tests**: assert passwords never persisted, auth validation edge cases.

## 8. Priority Summary

| Priority | Count | Items |
|---|---|---|
| P0 | 1 | W1, R1, TD1 |
| P1 | 3 | W2, W3, W10, R2, TD2, TD3 |
| P2 | 5 | W4, W5, W6, W7, W8, W9, R3, TD4, TD5 |
| P3 | 0 | — |