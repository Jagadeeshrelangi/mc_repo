# Sprint 1.8.3 — Production-Readiness Audit & Location Consolidation (P0)

## What changed, in one sentence

A production-readiness audit of the Marketplace module and shared systems replaced the three duplicated address/detection implementations with ONE GPS-first `LocationService` + ONE shared `LocationStatusBanner` (Fuel, Mechanic, Marketplace checkout all consume the same pipeline and the same UI), then hardened the shared providers and screens against every stale-UI, setState-after-dispose, null-race and overflow hazard the audit surfaced — with a final suite of 102/102 tests and 0 analyzer warnings.

---

## 1. The one-location-service mandate

### 1.1 Root cause — three different location pipelines, three different status vocabularies

Before this sprint the app had **three independent, manually-written address/detection implementations** that could drift and did drift:

- **Fuel booking** (`fuel_booking_screen.dart` + `fuel_provider.dart`) had its own `FuelLocationStatus` enum, its own `_buildLocationStatus/_buildLocationLoading/_buildLocationSuccess/_buildLocationIdle/_buildLocationError` builders, its own reserved-height constant, and a hand-rolled permission → GPS → reverse-geocode pipeline inside the provider.
- **Mechanic vehicle form** (`vehicle_form_screen.dart`) had its own `_LocationStatus` enum, its own `_buildLocationStatus/_buildLocationError`, and its own copy of the pipeline.
- **Marketplace checkout** (`address_sheet.dart`) was pure manual entry — **no auto-detection at all** — the exact "location not auto-detected at checkout" P0.

Each screen could show a *different* banner copy, a *different* retry behavior, and a *different* denied/permission/settings flow. That is a maintenance and correctness landmine: a bug fixed in Fuel stayed broken in Mechanic, and checkout never even attempted detection.

### 1.2 Why it happened

The location features were built in separate module sprints (Fuel 1.x, Mechanic 1.x, Marketplace 1.8) without a shared abstraction. `LocationProvider` existed but only exposed state + permission helpers — the *pipeline* (permission → GPS → reverse geocode → prefill) was re-implemented per screen.

### 1.3 The fix — one service, one banner, every screen

**New files:**
- `lib/services/location_service.dart` — `LocationService.detect({required LocationProvider provider})` implements the whole pipeline exactly once: check/request permission → wait for a GPS fix (10s timeout) → reverse-geocode → return a `DetectedLocation(latLng, details, address)`. Failures are mapped 1:1 into `LocationDetectException(state)` whose `state` is a **`LocationBannerState`** (`idle | loading | success | denied | deniedForever | serviceDisabled | error`) — so every error state in the app comes from ONE enum.
- `lib/widgets/location_status_banner.dart` — one `LocationStatusBanner` (key `location_status_area`, reserved height 108, overflow-clipped via `OverflowBox` + `Clip.hardEdge`) renders all seven states with identical copy/actions: `Use Current Location`, `Retry`, `Open Settings` (deniedForever), `Enable Services` (serviceDisabled), `Enter Manually`. Text is `Expanded`/ellipsized and the success row uses `OverflowBar`, so it cannot overflow.

**Consumers migrated to the single implementation:**
- `lib/features/fuel_delivery/providers/fuel_provider.dart` — removed `enum FuelLocationStatus` and the hand-rolled pipeline; `detectDeliveryLocation()` now delegates to `LocationService.detect`, `_locationStatus` is a `LocationBannerState`.
- `lib/features/fuel_delivery/screens/fuel_booking_screen.dart` — deleted the five private status builders + reserved-height constant; step 3 renders the shared banner.
- `lib/features/mechanic/screens/vehicle_form_screen.dart` — deleted `enum _LocationStatus` and the local builders; `_detectLocation()` delegates to the shared service and the shared banner handles `onOpenSettings`/`onEnableServices` via `LocationProvider`.
- `lib/features/marketplace/widgets/address_sheet.dart` — **rewritten GPS-first**: on open it auto-runs `LocationService.detect` (post-frame), prefills the editable Address/PIN/City/State fields from the `GeocodingResult`, shows the shared banner (success/denied/error with manual fallback). GPS is a **prefill, never a lock-in** — every field stays editable. The public surface (`showAddressSheet`/`AddressSheet`/`CheckoutAddress` return) is unchanged.
- `lib/features/home/widgets/location_card.dart` + `lib/features/home/screens/home_screen.dart` — the Home card now shows the live `LocationProvider.selectedAddress` (wins over the static `LocationInfo.fullAddress` mock) and opens the picker via the new `showLocationPickerSheet` helper in `lib/widgets/location_picker_sheet.dart` (wraps the sheet in a provider-scoped `ChangeNotifierProvider`). `location_header.dart` uses the same helper.
- `lib/features/fuel_delivery/services/location_service.dart` (old, fuel-specific) — **deleted**; the shared service replaces it.

### 1.4 Why it works

There is now exactly one place that knows how to turn "a screen needs an address" into "permission granted → GPS → reverse geocode → fields prefilled with an editable fallback," and exactly one widget that renders the detection UI. A permission/settings/retry change is made once and applies to every screen. The `LocationBannerState` enum is the single status vocabulary the whole app shares.

### 1.5 Regression tests

- `test/marketplace_module_test.dart` — *"checkout address sheet auto-detects GPS and prefills editable fields"* (success banner, prefilled+enabled fields, then Continue → checkout shows the address); *"checkout address sheet denied permission offers manual entry"* (denied copy + Retry + Enter Manually → idle + editable fields); *"address sheet renders without overflow in light/dark at 320/390/412dp"*.
- `test/home_dashboard_test.dart` — *"HomeDashboard LocationCard shows the live location address"* (live `selectedAddress` wins over the static mock; a `_FakeLocationProvider` with a resolved address).
- `test/fuel_module_test.dart`, `test/vehicle_location_test.dart` — existing location flows re-verified against the shared pipeline (loading/denied/error/retry/enter-manually/5-step booking + constant-height pinned Continue across all states).

---

## 2. Cart badge/body sync — re-audited

The "cart badge says N but the body looks empty" P0 was re-verified against the live code: `CartScreen` renders `Cart (${provider.cartCount})` and the body `ListView` from the **same** `provider.cart` on the one root `MarketplaceProvider` — a single source of truth, no badge/body fork. `addToCart` clamps quantity ≥ 1 (Sprint 1.8.2), so the badge (Σ quantities) can never disagree with the lines.

**Regression test added:** *"cart badge, cart body and checkout total share one source"* — adds 2+1 items, asserts `Cart (3)`, two visible `CartItemTile`s, the cart `Proceed to Checkout` total, and the checkout `Place Order` total all equal `provider.priceSummary.grandTotal`.

---

## 3. Provider/runtime audit — bugs found and fixed

A write-audit of every `ChangeNotifier` in `lib/` (Location, Fuel, Marketplace, Mechanic, Home, Auth, Theme) plus a hazard audit of the ten location/checkout/cart/home screens produced the following fixes.

### 3.1 setState after dispose — checkout address picker (P0-adjacent)

- **Root cause:** `checkout_screen.dart` `_AddressCard.onTap` awaited `showAddressSheet(context)` then called `setState` with no `mounted` guard.
- **Why it happened:** the modal sheet normally blocks the back button, so the dispose path was unreachable today — but any future route replacement while the sheet is open (deep link, provider-driven navigation) throws "setState called after dispose".
- **File modified:** `lib/features/marketplace/screens/checkout_screen.dart`
- **Exact fix:** `if (result != null && mounted) setState(...)`.
- **Why it works:** the sheet result is only applied while the State is still attached.

### 3.2 Missing notifyListeners — `FuelProvider.stopTracking`

- **Root cause:** `stopTracking()` set `_isTracking = false` with no `notifyListeners()`.
- **Why it happened:** no widget currently watches `isTracking`, and internal callers notify afterwards — latent.
- **File modified:** `lib/features/fuel_delivery/providers/fuel_provider.dart`
- **Exact fix:** `notifyListeners()` at the end of `stopTracking()`.

### 3.3 Mutable collection leaks — Fuel & Mechanic providers

- **Root cause:** `FuelProvider` (`fuelTypes`, `savedVehicles`, `stations`, `orderHistory`) and `MechanicProvider` (`mechanics`, `featuredMechanics`, `categories`, `reviews`, `bookingHistory`) returned their **internal lists** directly, so any caller could mutate provider state and bypass `notifyListeners`. `MarketplaceProvider` and `LocationProvider` already returned unmodifiable views — inconsistent.
- **File modified:** `lib/features/fuel_delivery/providers/fuel_provider.dart`, `lib/features/mechanic/providers/mechanic_provider.dart`
- **Exact fix:** each getter now returns `List.unmodifiable(_...)` (verified: no caller mutates the returned list in place).
- **Why it works:** state can only change through the provider's mutating methods, which all notify.

### 3.4 Null-race crash — Mechanic AI diagnosis details

- **Root cause:** `vehicle_form_screen.dart` passed `diag['predicted_fault']`, `diag['repair_time']`, `diag['safety_advice']` (raw API map values) straight into `Text(...)`; a missing/`null` key (server schema change, error-object response) throws an uncaught `TypeError` in the frame.
- **File modified:** `lib/features/mechanic/screens/vehicle_form_screen.dart`
- **Exact fix:** `'${diag[key] ?? ''}'` interpolation (null-safe, string-safe).

### 3.5 Unguarded `as String` cast — location picker sheet

- **Root cause:** `location_picker_sheet.dart` cast `result['shortName'] as String` on search results; safe today but a crash if the map ever lacks the key.
- **Exact fix:** `'${result['shortName'] ?? ''}'`.

### 3.6 Overflow risk — `location_header.dart` "Detecting location…"

- **Root cause:** the detecting row was a bare `Row` with an unconstrained `Text` (unlike the two sibling branches that used `Flexible` + ellipsis).
- **Exact fix:** wrapped the text in `Flexible` with `maxLines: 1` + `overflow: ellipsis`.

### 3.7 Audited and found clean (no change needed)

`notifyListeners` ordering (all write methods notify **after** the final mutation, never during build/layout, never after dispose); `MarketplaceProvider`, `LocationProvider`, `HomeProvider`, `ThemeProvider`, `AuthProvider`; cart model/service are immutable value types; all `Navigator.pop` calls in the audited screens pop a pushed route or modal sheet (no dead ends); no `late`-field `LateInitializationError` risks; all controllers are State-owned and disposed; the shared banner is overflow-engineered (`Expanded`/ellipsis/`OverflowBar`/`FittedBox`/`OverflowBox`+clip).

---

## 4. Findings documented (deferred, not a bug today)

- **Orders tab store has no notification** (`lib/parts/order_data.dart` global `ordersList` is a plain mutable list; `MarketplaceProvider.placeOrder` inserts without notifying). Verified **latent only**: `bottom_navigation.dart` creates `_navItems` once and swaps the `body`, so `Orderscreen` State unmounts whenever the user leaves the tab — a marketplace order is always placed while the tab is unmounted and appears on the next fresh mount. Recommendation (Sprint 2): make `ordersList` a `ChangeNotifier`-backed store and have `Orderscreen` listen.
- **`PriceSummaryCard` label/value rows** lack `Flexible`/ellipsis — only a risk at very large text scale.

---

## 5. Test-suite corrections (from the migration)

- `test/home_dashboard_test.dart` — the location fake now overrides `selectedAddress` (the base getter falls back to the private `_currentAddress` field, which the fake had left empty, so the card fell back to the mock address).
- `test/vehicle_location_test.dart` — *"Enter Manually dismisses banner and keeps fields editable"* now pumps `pump → pump(250ms) → pump` because the shared banner animates state swaps through `AnimatedSwitcher` (180ms); the new child's controller starts on the first build after the tap, so the transition must be advanced past 180ms before asserting the old banner is gone.
- New responsive/dark test (*3.7*) learned the `pumpWidget`-preserves-the-Navigator-route-stack subtlety: an open modal sheet leaks its barrier into the next loop iteration, so the loop resets with `pumpWidget(const SizedBox())` between iterations.

---

## 6. Verification

- `flutter analyze --no-pub` → 0 errors, 0 warnings (only the 20 pre-existing `avoid_print` infos in `test/integration/*`).
- `flutter test` → **102/102 passing** (97 baseline + cart-shared-source, checkout GPS prefill, checkout denied fallback, Home live-address, and the responsive/dark address-sheet test).
- QA walkthrough covered, in tests and code: Fuel 5-step booking (location step in all five banner states, pinned Continue, back), Mechanic vehicle form (auto-detect prefill, denied → Retry/Enter Manually, AI diagnosis), Marketplace search → detail → cart → checkout → GPS address sheet → place order → success, Home LocationCard live address → location picker sheet → cart back-navigation, at 320/360/390/412/600/768dp in light and dark.
