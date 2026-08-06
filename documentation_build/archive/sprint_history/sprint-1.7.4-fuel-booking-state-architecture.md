# Sprint 1.7.4 — Fuel Booking State Architecture Refactor

## What changed, in one sentence

`FuelProvider` is now the **single source of truth** for the entire booking wizard; `FuelBookingScreen` owns exactly one piece of state (`_currentStep`); the GPS success path has exactly **one write point** (`FuelProvider.setDeliveryLocation`); every booking step is a stateless view or a pure text-edit surface.

No UI redesign, no color/typography/spacing changes, no `Future.delayed`, no `addPostFrameCallback` hacks, no `Key`s introduced to mask bugs. The `Key('location_status_area')` and `ValueKey(locationStatus)` that exist are layout/pump identifiers carried over from Sprint 1.7.2a — they do not influence behavior.

---

## 1. State ownership diagram

```
                    ┌──────────────────────────────────────────────────┐
                    │                  FuelProvider                    │
                    │  (single source of truth — every booking datum)  │
                    │                                                  │
                    │  fuelTypes · selectedFuelType · quantity         │
                    │  priceEstimate · savedVehicles · selectedVehicle │
                    │  deliveryLocation · deliveryAddress ·            │
                    │  deliveryPincode · locationStatus ·              │
                    │  isDetectingLocation · stations · selectedStation│
                    │  activeOrder · orderHistory · isPlacingOrder     │
                    │  trackingInfo · isTracking · state · errorMessage│
                    └───────────────▲──────────────────────────────────┘
                                    │  injected
                                    │
                    ┌───────────────┴─────────────┐
                    │       LocationProvider      │  (lib/services/location_provider.dart)
                    │  permission · GPS · geocode │
                    └─────────────────────────────┘

                 reads via context.watch / reads via prop     writes (all funnelled)
                    ┌───────────────┐  ┌───────────────────────────────┐
                    │ FuelBooking   │  │ FuelProvider methods:          │
                    │ Screen        │  │ selectFuelType / setQuantity   │
                    │ owns ONLY     │  │ selectVehicle / selectStation  │
                    │ _currentStep  │  │ setDeliveryLocation  ← GPS     │
                    └───────┬───────┘  │ setDeliveryAddress            │
                            │          │ setDeliveryPincode            │
              ┌─────────────┼──────────────┐
              ▼             ▼              ▼
   ┌────────────────┐ ┌──────────────┐ ┌─────────────────────────┐
   │ stateless steps│ │ _VehicleStep │ │ _LocationStep           │
   │ Fuel (247)     │ │ (483)        │ │ (687)                   │
   │ Station (298)  │ │ owns ONLY    │ │ owns ONLY editing       │
   │ Review (351)   │ │ manual-form  │ │ mirrors: address/       │
   │  ─ read only   │ │ UI state     │ │ pincode controllers +   │
   └────────────────┘ └──────────────┘ │ focus node              │
                                       └─────────────────────────┘
```

- **`FuelBookingScreen` (`fuel_booking_screen.dart:29`)** — `int _currentStep = 0`. Nothing else. Step navigation is `setState(() => _currentStep±1)`; everything the steps render is read from the provider.
- **`_VehicleStep` (`:483`)** — a private editor surface. Its only local state is the manual-add form's UI (`_showManualVehicle`, `_manualVehicleType`, name/number controllers). Selecting a saved vehicle writes `provider.selectVehicle(...)`; typing in the manual form writes `provider.selectVehicle(FuelVehicle(id: 'manual', …))`. It never caches a vehicle.
- **`_LocationStep` (`:687`)** — a private editor surface. Its only local state is `_addressController`, `_pincodeController`, `_addressFocusNode`. `initState` seeds the controllers **from** the provider (`:707`); `didUpdateWidget` reconciles them **from** the provider whenever it changed (`:714`). Every keystroke writes back via `provider.setDeliveryAddress` / `setDeliveryPincode`. The banner, preview card, status and GPS button all read the provider.
- **Steps 0/3/4** are plain methods returning widgets (`_buildFuelStep` :247, `_buildStationStep` :298, `_buildReviewStep` :351) — zero local state, provider reads only.

---

## 2. Dependency graph

```
main.dart
 ├─ final locationProvider = LocationProvider();            (provides ChangeNotifierProvider.value)
 ├─ final fuelProvider = FuelProvider(locationProvider: locationProvider);
 └─ providers (both via .value) → MaterialApp → ...

FuelProvider (fuel_provider.dart)
 ├─ LocationProvider  _locationProvider   (constructor injection, :29)
 ├─ GeocodingService   (transient, used inside detectDeliveryLocation, :276)
 ├─ FuelRepository     _repository        (orders, stations, history)
 └─ FuelService        _service           (price estimation)

FuelBookingScreen → FuelProvider (watch/read/write) → PaymentScreen (pushReplacement)
    ├─ _VehicleStep  → FuelProvider.selectVehicle
    ├─ _LocationStep → FuelProvider.setDeliveryAddress/setDeliveryPincode/enterManualLocation/detectDeliveryLocation
    └─ FuelTypeCard · QuantitySelector · PriceBreakdown · FuelVehicleCard ·
       DeliveryLocationCard · FuelStationCard (widgets read values passed from the provider)
```

Key consequence: the wizard no longer reads `LocationProvider` from the widget tree at all. GPS/permission/geocode flow **through the provider** (which holds the injected instance), so detection state is guaranteed to be visible to the same notifier the UI watches. Tests exercise this by injecting the same fake into both `FuelProvider` and the tree.

---

## 3. Removed duplicated state

The pre-1.7.4 wizard kept a route-local copy of nearly every booking datum and reconciled it with the singleton provider only on certain events. That is the root of the Sprint 1.7.2d/1.7.3 symptom. All of the following local state was removed from the booking screen:

| Removed (screen-owned) | Where it lives now | Write path |
|---|---|---|
| `_locationStatus` (enum `_LocationStatus`) | `FuelProvider.locationStatus` (`FuelLocationStatus`, `fuel_provider.dart:15`) | provider only |
| `_isDetectingLocation` | `FuelProvider.isDetectingLocation` (`:88`) | provider only |
| cached `DeliveryLocation` / preview model | `FuelProvider.deliveryLocation` (`:74`) | `setDeliveryLocation` only |
| cached address string | `FuelProvider.deliveryAddress` (`:79`) | `setDeliveryAddress` / `setDeliveryLocation` |
| cached pincode string | `FuelProvider.deliveryPincode` (`:84`) | `setDeliveryPincode` / `setDeliveryLocation` |
| cached selected vehicle | `FuelProvider.selectedVehicle` | `selectVehicle` only |
| cached quantity | `FuelProvider.quantity` | `setQuantity` only |
| cached selected station | `FuelProvider.selectedStation` | `selectStation` only |
| `_addressController` / `_pincodeController` as **source of truth** | controllers exist only inside `_LocationStep` as **editing mirrors** (`:698-700`) | keystroke → `setDeliveryAddress`/`setDeliveryPincode`; provider → `didUpdateWidget` mirrors back |
| `_vehicleNameController` / `_vehicleNumberController` as source of truth | mirrors inside `_VehicleStep` (`:493-494`) | keystroke → `selectVehicle` |
| duplicate "continue gate" logic reading local text/status | single `_nextStep` gate reading provider state (`:56`) | — |

No controller holds booking data any more. A controller's text can never disagree with the provider because:
1. every edit writes through to the provider immediately, and
2. `_LocationStep.didUpdateWidget` (`:714`) forces the controller to mirror the provider whenever they diverge (the GPS path fills the fields this way).

---

## 4. Files modified

| File | Change |
|---|---|
| `lib/features/fuel_delivery/providers/fuel_provider.dart` | Added `FuelLocationStatus` enum (`:15`); constructor now takes `required LocationProvider locationProvider` (`:29`); new provider-owned fields `_deliveryAddress`, `_deliveryPincode`, `_locationStatus`, `_isDetectingLocation` (`:79-89`); `setDeliveryLocation` is now the **atomic single write** for GPS results (`:205`); new `setDeliveryAddress` (`:215`), `setDeliveryPincode` (`:221`), `enterManualLocation` (`:228`); new idempotent `detectDeliveryLocation` pipeline permission→GPS→geocode (`:249`); `_applyDetectedLocation` (`:306`); `_pincodeFromAddress` (`:334`); `loadHome` now guarantees a default fuel selection + price estimate (`:130`); `resetRequest` clears all four new fields (`:519`) |
| `lib/features/fuel_delivery/screens/fuel_booking_screen.dart` | Full rewrite: screen state reduced to `_currentStep` (`:29`); `initState` performs **no provider writes** (defensive load deferred to a microtask, `:40-49`); `_nextStep` gates on provider state only (`:56`); fuel/station/review steps stateless (`:247/298/351`); `_VehicleStep` (`:483`) and `_LocationStep` (`:687`) are the only Stateful children and hold only editing surfaces; location status area driven by `provider.locationStatus`; success banner's refresh button and the idle/error buttons call `provider.detectDeliveryLocation`; `_placeOrder` checks the `bool` returned by `provider.placeOrder()` and shows `provider.errorMessage` |
| `lib/main.dart` | `final locationProvider = LocationProvider(); final fuelProvider = FuelProvider(locationProvider: locationProvider);` both registered via `ChangeNotifierProvider.value` |
| `test/fuel_module_test.dart` | Every `FuelProvider()` construction now passes `locationProvider:` (24 call sites + `_wrap` fallback); GPS-relevant widget tests inject the **same** fake into both the provider and the tree; `_ThrowingLocationProvider` documented + reused for a new "permission request failure shows the error banner, never hangs" test; `_FailingLocationProvider` now covers the true GPS-error banner |

---

## 5. Runtime verification

- `flutter analyze` — **0 errors, 0 warnings** (20 `info` items are pre-existing `avoid_print` in `test/integration/*`, untouched).
- `flutter test` — **58/58 passing**. Fuel module (`test/fuel_module_test.dart`): **37/37**, including:
  - "completes the 5-step flow and reaches payment" — full wizard still works end to end.
  - "GPS success writes one consistent Step 3 state" — banner + preview + both fields all read the **same** provider model (`delivery.pincode`, `delivery.latitude/longitude`, `label: 'Current Location'`).
  - "reopening the booking screen renders the location identically" — fresh route over the same singleton providers reproduces identical fields/banner/preview; **no** local state to lose.
  - "geocode failure shows error + Retry, never success with empty fields" — `deliveryLocation` stays null, no success banner.
  - "Continue during detection is swallowed, then works once detected" — Continue gates on `isDetectingLocation`/`locationStatus`, no false address snack, advances once committed.
  - "permission request failure shows the error banner, never hangs" — **new test**: a throwing permission request resolves to `error`, never stuck on `loading`.
  - "location status area keeps a constant height and pins Continue across all 5 states" — the 108px reserved area and pinned Continue hold across idle/loading/success/denied/error × 320/360/412dp × text scale 1.0/1.3.
  - "all 5 steps render with zero overflow and intact CTAs at 320/360/412dp" — 6 full-flow runs, zero `RenderFlex`/bottom overflows.

### Rebuild tracing — exactly one rebuild path

Every booking-datum change follows one and only one path:

```
provider method mutates its field(s)
   └─ notifyListeners()
        └─ _InheritedProviderScope<FuelProvider> marks dependents dirty
             └─ FuelBookingScreen.build (context.watch<FuelProvider>, :130) rebuilds
                  └─ _buildStepContent → the active step re-reads provider
                       ├─ stateless steps: re-render directly from provider
                       └─ _LocationStep.didUpdateWidget mirrors the provider
                          into the controllers (address/pincode fields, banner, card)
```

GPS success, concretely: `detectDeliveryLocation` (`fuel_provider.dart:249`) → `_applyDetectedLocation` (`:306`) → **`setDeliveryLocation` (`:205`) — the single write** → one `notifyListeners` → one rebuild → `_LocationStep` shows success banner + preview card and mirrors `deliveryAddress`/`deliveryPincode` into the fields. There is **no `setState` in the GPS path** anywhere; the `setState` calls that exist in the wizard are only `_currentStep` navigation (`fuel_booking_screen.dart:66/89/99/103`) and the manual-form toggles (`_VehicleStep`, `_LocationStep`) which touch editing-surface UI only.

The only `notifyListeners()` producers in the wizard's data path are `FuelProvider` methods; `LocationProvider`'s own notifications are irrelevant to the UI because nothing in the wizard watches it.

---

## 6. Why the original architecture caused the bug

The pre-1.7.4 wizard had **multiple sources of truth** for the same booking data:

- **RC-1 — the Continue gate trusted local state, not the model.** Step 3's validation read route-local controller text and a route-local status, while the actual order later used the provider's model. The gate could therefore "pass" on values the provider never saw (or fail on values it already had), which is exactly the class of "Continue swallowed / advanced on stale data" symptoms reported for Step 3.
- **RC-2 — GPS state was captured twice.** Detection populated local controllers/status **and** separately committed the singleton provider, so the first render after a fix could show fields, banner, and preview built from two different snapshots. The divergence was masked by route reopen: the second build happened to read the committed singleton. The provider is a never-reset app-wide singleton, so a prior session's committed `deliveryLocation` could also seed a "success" that didn't correspond to the current session's GPS run.
- **RC-3 — `LocationProvider` boot races.** The real `LocationProvider` starts GPS in its constructor (`_initLocation`); a subsequent `getCurrentLocation()` returns `false` while `_isLoadingLocation` is true. The wizard's old detection called into this directly and the silent `false` produced an unusable/empty state that the test fakes (which never modeled `_isLoadingLocation`) didn't exercise.

In short: **three copies of "the delivery state" (controllers, route-local flags, provider singleton) could disagree, and reopening the route hid the disagreement.** That is not a Step-3 bug; it is an architecture bug in how the wizard stored and wrote booking state.

## 7. Why the new architecture prevents it forever

1. **One writer.** GPS success is committed by `setDeliveryLocation` and nothing else (`fuel_provider.dart:205`); the provider exposes no other path that sets `deliveryLocation`, address, pincode, or the success banner. Manual edits funnel through `setDeliveryAddress`/`setDeliveryPincode`, which rebuild the single model and notify once. It is structurally impossible for the model, the fields, the banner, and the preview to disagree, because they all read the same object that the one write committed atomically.
2. **One store.** `FuelBookingScreen` holds no booking data to drift — only `_currentStep`. There is nothing local left to desync, and nothing to lose on reopen (the "reopening renders identically" test proves it).
3. **Controllers are mirrors.** The only local controllers mirror the provider: edits push into it, and `didUpdateWidget` pulls the provider's value back in whenever it changes. The fields can never hold text the provider doesn't know.
4. **Detection always terminates.** `detectDeliveryLocation` is idempotent (a concurrent call is swallowed, `:262`) and resolves to a defined terminal state — `success`, `denied`, or `error` — including when the `hasLocation` short-circuit path or the permission request throws (both now caught). Continue gates on `isDetectingLocation || locationStatus == loading`, so it can never advance on a half-committed location nor falsely complain while detection is in flight.
5. **The gate reads the store.** `_nextStep` validates `provider.selectedFuelType / selectedVehicle / deliveryAddress / selectedStation` — the exact objects `placeOrder` will use — so the UI can never validate data that the order path doesn't hold.

Because every booking datum has exactly one owner, one write path, and one notification, the failure mode that produced the Step-3 report (two copies of delivery state disagreeing, then being "fixed" by a reopen) no longer has any way to exist.
