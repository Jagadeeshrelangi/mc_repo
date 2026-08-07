# Tests Inventory — Mecha Connect

> Phase 1 · Baseline: `flutter test` **162/162 passing**, `flutter analyze` clean (RC1).

## 1. Test Files (`test/`, 9)

| File | Covers | Approx. tests |
|---|---|---|
| `test/ai_module_test.dart` | AI chat, diagnosis, conversation flows (AiProvider/AiService) | ~20 |
| `test/fuel_module_test.dart` | Fuel booking, stations, tracking, orders (FuelProvider) | ~21 |
| `test/home_dashboard_test.dart` | Dashboard aggregate + search (HomeProvider) | ~18 |
| `test/marketplace_module_test.dart` | Browse, cart, checkout, coupons, orders (MarketplaceProvider) | ~27 |
| `test/mechanic_module_test.dart` | Mechanics, services, booking lifecycle (MechanicProvider) | ~23 |
| `test/profile_module_test.dart` | Profile, wallet, rewards, addresses, validation (ProfileProvider) | ~25 |
| `test/vehicle_location_test.dart` | LocationProvider + geocoding + nearest ordering | ~10 |
| `test/widget_test.dart` | App shell smoke (MaterialApp boots, splash renders) | ~2 |
| `test/integration/runtime_marketplace_flow_test.dart` | **Integration**: real `buildRootProviders()` graph end-to-end marketplace flow | ~6 |

> Counts are approximate by file; official total is 162.

## 2. Key Testing Conventions
- Module tests drive the real provider over the mock repository with
  simulated latency + FAULT_INJECTION scenarios (failure paths asserted, not just happy paths).
- The integration test uses the exact production wiring (`lib/app_wiring.dart`) —
  no special test wiring — verifying the root graph and real widget tree.
- Golden/screenshot tests: none at RC1 (Phase 6 screenshot workspace is a future target).

## 3. Backend Tests
- No Python test suite yet in `backend/` (scaffold only). Sprint 2 to add
  pytest coverage for `conversation/diagnosis/knowledge` endpoints.
