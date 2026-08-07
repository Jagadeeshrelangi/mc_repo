# Sprint 1.9a — Profile & User Account Module (Mock Backend)

**Date:** 2026-08-02
**Version:** 1.0
**Status:** ✅ Complete — analyze clean, all tests green

---

## Executive Summary

Sprint 1.9a delivered the production-grade Profile / User Account Center under
`lib/features/profile/` — models, mock repository, services, provider, 12
screens, 11 widgets, navigation and barrels. The legacy placeholder Profile tab
was removed and the bottom-nav tab 4 now renders the real account center. The
module follows the Fuel/Mechanic/Marketplace/AI feature-first architecture: a
single `ProfileProvider` is the source of truth for profile, vehicles, saved
addresses, wallet, rewards, unified order history and notification settings, and
orders reuse the exact same global `ordersList` the Orders tab renders.

Verification:
- `flutter analyze` — **0 errors, 0 warnings** (only pre-existing `avoid_print`
  infos in `test/integration/verify_chatbot_widget.dart` and
  `verify_e2e_network.dart`).
- `flutter test test/profile_module_test.dart` — **30/30 pass**.
- `flutter test` (full suite) — **159/159 pass** (129 prior + 30 new).

## Deliverables

```
lib/features/profile/
├── profile.dart                       # module barrel
├── navigation.dart                    # 12 route constants, profileFadeRoute, 11 open* helpers
├── models/
│   ├── user_profile.dart              # name/email/phone/DOB/gender, MembershipTier{pro,free},
│   │                                  # emergencyContact, joinedDate
│   ├── emergency_contact.dart
│   ├── vehicle.dart                   # ProfileVehicle + VehicleFuel{petrol,diesel,electric,cng},
│   │                                  # name getter, copyWith passes id
│   ├── saved_address.dart             # SavedAddress + AddressLabel, copyWith passes id
│   ├── wallet_transaction.dart        # WalletTransaction, Coupon, PaymentMethod, WalletData
│   ├── reward.dart                    # Reward, RewardType, RewardTierProgress, RewardsData
│   ├── notification_settings.dart     # push/email/sms/marketing + json round-trip
│   ├── profile_stats.dart
│   └── models.dart
├── repositories/
│   └── profile_repository.dart        # mock backend: latency + failForFirstCalls injection,
│                                      # seeds (Jagadeesh Gowda, 2 vehicles, 2 addresses,
│                                      # wallet ₹1200/2450, coupons, payment methods,
│                                      # rewards GOWDA200), full vehicle/address CRUD with
│                                      # default-promotion, notification settings via
│                                      # NotificationSettingsStore abstraction
├── services/
│   ├── validation_service.dart        # ALL field validation lives here (never in widgets)
│   └── profile_service.dart           # app layer: reads/writes + validateProfileForm
├── providers/
│   └── profile_provider.dart          # ProfileScreenState machine, loadHome/refreshHome,
│                                      # vehicle/address/profile CRUD, operation flags/errors
├── screens/
│   ├── profile_screen.dart            # account home: header, stats, vehicles, wallet,
│   │                                  # orders, settings menu, logout
│   ├── edit_profile_screen.dart
│   ├── my_vehicles_screen.dart
│   ├── vehicle_detail_screen.dart
│   ├── saved_addresses_screen.dart
│   ├── wallet_screen.dart
│   ├── rewards_screen.dart
│   ├── order_history_screen.dart
│   ├── notification_settings_screen.dart
│   ├── privacy_security_screen.dart
│   ├── support_screen.dart
│   ├── about_screen.dart
│   └── screens.dart
├── widgets/
│   ├── profile_header.dart            # exports profileAvatarIcon (avatar key → icon map)
│   ├── stats_card.dart, vehicle_card.dart, address_card.dart
│   ├── reward_card.dart, wallet_card.dart, menu_tile.dart
│   ├── profile_loading.dart, profile_error.dart, profile_empty.dart
│   ├── vehicle_form.dart              # add/edit bottom sheet: dates + fuel dropdown
│   ├── address_form.dart              # GPS Detect flow (mirrors Mechanic/Fuel exactly)
│   └── widgets.dart
```

## Architecture Decisions

- **Single source of truth.** `ProfileProvider` owns exactly one copy of every
  dataset; all screens derive from it. Sub-screens (vehicles, addresses) never
  load independently — they render the same list the home shows.
- **Orders reuse the Orders tab store.** `ProfileRepository.fetchOrders()`
  returns a snapshot of the shared `lib/parts/order_data.dart` `ordersList`, so
  profile order history and the Orders tab can never disagree.
- **Root provider.** `ProfileProvider` is created once in `buildRootProviders()`
  (`lib/app_wiring.dart`) with the default
  `SharedPreferencesNotificationSettingsStore`; tests inject in-memory stores.
- **Mock-only backend.** The repository simulates 800 ms latency and deterministic
  failure injection; `ProfileService`/`ProfileProvider`/screens depend only on its
  interface, so Sprint 2 swaps in the real FastAPI/PostgreSQL client unchanged.
- **Validation single home.** Every rule lives in `ValidationService`; widgets
  only pass validator callbacks from the provider/service.
- **GPS flow parity.** The saved-address sheet reuses the exact Mechanic/Fuel
  flow (`LocationService().detect(provider: locationProvider)`), with manual
  entry available in every non-success state.
- **State handling.** Every surface renders Loading / Ready / Empty / Error /
  Retry via `ProfileLoadingState` / `ProfileEmptyState` / `ProfileErrorState`.

## Wiring

- `lib/app_wiring.dart` — root `ProfileProvider` added to `buildRootProviders`.
- `lib/bottom_bar/bottom_navigation.dart` — tab 4 → `ProfileScreen` from
  `features/profile/screens/`.
- `lib/bottom_bar/profile_screen.dart` — **deleted** (legacy placeholder; grep
  confirms zero remaining references).
- `lib/homescreen/drawerscreen.dart` — drawer entries now call
  `openMyVehicles` / `openNotificationSettings` / `openPrivacySecurity` from
  `features/profile/navigation.dart`.
- `lib/debug/runtime_trace.dart` — `traceProfile(screenTag, context)` added and
  used by the profile screens; `kRuntimeTrace` still `true` from prior audits.

## Bugs Found and Fixed During QA

| # | Bug | Root cause | Fix |
|---|-----|-----------|-----|
| 1 | New vehicles/addresses collided with seeds | Id counters started at 100, same range as seeded `veh-101`/`addr-101`, so a new default silently also promoted the seeded item | Counters start at 200 in `profile_repository.dart` |
| 2 | Vehicle/address lists reordered between screens | Mutations returned insertion order while `fetchVehicles`/`fetchAddresses` sorted default-first | All mutation methods now return the same `_sortedVehicles()`/`_sortedAddresses()` (default-first) |
| 3 | `ValidationService.address('short')` accepted | Min length 5 equals the input length | Threshold raised to 8 (`validation_service.dart`) |
| 4 | Widget tests deadlocked on the mocked latency | `await provider.loadHome()` inside `testWidgets` awaited a `Future.delayed` timer the fake-async clock never fires | Pre-load via `tester.runAsync(...)` in `profile_module_test.dart` |
| 5 | `find.text('Wallet')` missed on ProfileScreen | `CustomScrollView` lazily builds slivers; lower sections were below the 600 px test fold | Test uses a tall viewport (1080×3200) so every sliver is built |
| 6 | Profile form tests hit an earlier validator | `validateProfileForm` returns the first error; payloads omitted DOB/gender | Test payloads supply valid DOB + gender so the intended rule is reached |
| 7 | `DropdownButtonFormField` crash (toolchain 3.29.2) | Old `initialValue:` parameter removed | Use `value:` in the vehicle form fuel dropdown |
| 8 | `use_build_context_synchronously` on logout | `context` used after `await showDialog` | Capture `AuthProvider` + `Navigator` before the dialog in `profile_screen.dart` |
| 9 | Lint on `_call<T>` | `FutureOr<T>` needs `dart:async` | Import added; `_call` uses `FutureOr<T> Function()` |

## Test Evidence

`test/profile_module_test.dart` — 30 tests across:
- `ProfileRepository` — seeds, failure injection + recovery, vehicle CRUD +
  default promotion, address CRUD + single-default invariant, wallet/rewards
  snapshots, order history == `ordersList`, notification settings round-trip.
- `ValidationService` / `ProfileService` — every field rule, `validateProfileForm`
  accept/reject paths.
- `ProfileProvider` — loadHome (ready/error/retry), refreshHome keeps data on
  failure, profile/vehicle/address lifecycle, saveNotificationSettings error
  path, validation passthroughs.
- Widgets — ProfileScreen render/loading/error/edit, MyVehicles render/empty/
  add-sheet, SavedAddresses render/add-sheet, `profileAvatarIcon` mapping.

Full-suite result: `00:27 +159: All tests passed!`

## Next Steps (Sprint 2)

- Swap the mock `ProfileRepository` internals for the real FastAPI/PostgreSQL
  API (provider, services and screens unchanged) and wire avatar storage to
  real URLs.
- Add a runtime integration test (real `main()` wiring) driving
  Home → Profile tab → My Vehicles → Wallet → Settings, mirroring the
  Marketplace P0 audit.
- Flip `kRuntimeTrace` back to `false` once the runtime audit is closed.
