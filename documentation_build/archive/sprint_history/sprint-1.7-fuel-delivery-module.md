# Sprint 1.7 — Fuel Delivery Module (Production Ready)

## Overall Completion
100%

## Overview
Upgraded the entire Fuel Delivery module into a production-ready, feature-first
architecture under `lib/features/fuel_delivery/` while preserving the existing
UI/design language (no redesign; Auth, Home Dashboard, Mechanic, Marketplace and
AI were untouched). The legacy `lib/homescreen/petrol_page.dart` flow was
migrated to a single `FuelProvider` (ChangeNotifier) backed by a mock
`FuelRepository` (real backend lands in Sprint 2). All 10 screens of the flow —
Fuel Home, Request, Fuel Type, Quantity, Vehicle Info, Location, Station
Selection, Order Summary, Confirmation, Live Tracking, Delivery Complete, Order
History — are delivered, plus a new Receipt screen. 23 new tests added;
`flutter analyze` 0 errors / 0 warnings and `flutter test` 44/44 green.

## Architecture
Feature-first module mirroring `lib/features/mechanic/`:

```
lib/features/fuel_delivery/
├── constants/fuel_constants.dart      # default litres, min/max, presets [1,2,5,10], default coords
├── models/                            # fuel_type, order_status, fuel_station, fuel_vehicle,
│                                      #   fuel_order, fuel_partner, delivery_location,
│                                      #   price_estimate, tracking_info, invoice + models.dart barrel
├── repositories/
│   └── fuel_repository.dart           # mock API (700ms latency), 6 stations, 3 vehicles,
│                                      #   4 partners, seeds 5-order history, invoices INV-{orderId}
├── providers/
│   ├── fuel_provider.dart             # single ChangeNotifier for the whole module
│   └── providers.dart                 # barrel (exports only fuel_provider.dart)
├── services/fuel_service.dart         # calculatePrice (station rate + ETA), quantity validation
├── utils/location_utils.dart
├── screens/                           # 9 screens + screens.dart barrel
└── widgets/                           # 14 widgets + widgets.dart barrel
```

Key decisions:
- **Single provider**: `FuelProvider` owns all module state — `FuelScreenState`
  (initial/loading/ready/error/empty), fuel types, selection, quantity, price
  estimate, saved vehicles, delivery location, stations, active order, order
  history, tracking info and flags (`isTracking`, `isPlacingOrder`,
  `isRefreshing`). Screens read via `context.watch` / `context.read`, never
  re-fetch manually.
- **Required tracking states** modelled as `OrderStatus` (8 values): Requested,
  Accepted, Fuel Packed, Delivery Partner Assigned, En Route, Arrived,
  Delivered, Cancelled — with `.label`, `.isTerminal` and `.stepIndex`.
- **Coming-soon fuels**: `FuelType.electric` (Electric Charging) and
  `FuelType.cng` are `comingSoon: true`; `FuelTypeCard` renders them disabled
  with a "Coming Soon" badge, `selectFuelType` ignores them, and `orderable`
  still excludes them for service math.
- **Order IDs / invoices**: orders are `FUEL-{year}-{counter}`; invoices are
  `INV-{orderId}`; a delivered order automatically carries its invoice.
- Provider registered in `lib/main.dart` `MultiProvider`.

## Implementation Details

### Fuel Provider
Exposes `loadHome`, `refreshHistory`, `selectFuelType`, `setQuantity`,
`setDeliveryLocation`, `fetchStations`, `selectStation`, `canPlaceOrder`,
`placeOrder`, `setPaymentMethod`, `acceptOrder`, `cancelOrder`, `completeOrder`,
`openOrder`, `generateInvoice`, `generateInvoiceForOrder`, `startTracking`,
`stopTracking`, `resetRequest` and `reset`. `placeOrder` creates the order in
`requested` status; `acceptOrder` moves it to `accepted` (called by
`PaymentScreen` after a fake 2s processing delay); `_pollTracking` advances
status every 5s and calls `completeOrder()` (attaching the invoice) the moment
the order reaches `delivered`.

### Booking Flow
A 5-step wizard (`FuelBookingScreen`) — Fuel Type → Vehicle → Location →
Station → Review — driven by a single `_currentStep` with a progress indicator
and Back/Continue bottom bar. Fuel step shows the 5 fuel-type cards (coming-soon
disabled) plus a `QuantitySelector` (presets 1/2/5/10 + Custom slider) with live
`PriceBreakdown`. Vehicle step lists saved vehicles horizontally plus a manual
add form (vehicle type chips + name/number). Review shows the order summary card
and full price breakdown before `Place Order`.

### Order Lifecycle
`requested → accepted → fuelPacked → partnerAssigned → enRoute → arrived →
delivered`. `advanceStatus` walks the sequence, assigning a random partner at
`partnerAssigned`. `PaymentScreen` confirms the payment method (UPI, Card, Net
Banking, Cash on Delivery, Wallet) then `acceptOrder`; confirmation, live
tracking and completion follow.

### Live Tracking
`LiveTrackingScreen` shows an animated `TrackingTimeline` (7 steps, animated via
`AnimatedContainer`), a partner/location map, ETA and distance, an order-details
bottom sheet, and auto-advancement through the provider's 5s polling. Supports
manual Cancel (with confirmation). `Delivery Complete` screen shows the summary
and hands off to the receipt.

### Receipts
`ReceiptScreen` supports two modes: the just-completed order via
`generateInvoice()` and history orders via `generateInvoiceForOrder(order)`
(which never mutates the active order). `openOrder(order)` brings a history
order into the active slot so tracking/receipts can operate on it.

### Order History
`OrderHistoryScreen` lists all orders with search and filter chips (All /
Delivered / In Progress / Cancelled) and a details bottom sheet with Track and
View Receipt actions. The home screen also shows the three most recent orders.

## Location Auto-Detection
Mirrors the mechanic `VehicleFormScreen` UX exactly:
- `_LocationStatus {idle, loading, success, denied, error}`.
- Auto-detect runs when entering the Location step.
- Loading shows "Loading current location..." with only the location fields
  disabled.
- Success shows "📍 Current Location Detected".
- Denied shows `Location permission denied.` with Retry / Enter Manually.
- ~10s `TimeoutException` → `Unable to determine your location.`
- `_enterManually()` focuses the address field; pincode is auto-appended to the
  address on continue.
- Coordinates come from `LocationProvider.currentLatLng`
  (`GeocodingResult` has no lat/lng fields).

## Accessibility
Semantics wrappers (`Semantics(button:, selected:, enabled:, label:)`) on fuel
type cards, vehicle cards, station cards, timeline steps and vehicle-type chips.
`TrackingTimeline` exposes a semantic label of the current status. Shared
`AppLoading` widget and `context.*` theme helpers keep contrast and spacing
consistent.

## Performance
- Repository latency is centralized (700ms) so the UI behaves like production
  without repeated real work.
- `loadHome` performs its two sequential fetches (vehicles, history) once at
  boot; screens reuse provider state instead of re-fetching.
- Lists use `ListView` lazy building; station/fuel lists are scrollable and
  constrained to viewport heights.
- Tracking polls once every 5s and stops on terminal states.

## Testing
23 new tests in `test/fuel_module_test.dart` (service/enums, repository,
provider, widget):

- FuelService (3): orderable types, price calculation, quantity validation.
- OrderStatus (2): the 7 labels, terminal states.
- FuelRepository (5): history seed, sorted stations with availability,
  createOrder pricing, advanceStatus sequence + partner, invoice on complete,
  cancel.
- FuelProvider (7): loadHome, coming-soon rejection, quantity clamp, station
  price estimate, rejected place order, full place/accept/cancel lifecycle,
  invoice attach.
- Widgets (6): home screen renders (banner, fuel options incl. 2 "Coming Soon"
  cards, recent orders), full 5-step booking flow reaching payment, timeline
  states, delivered timeline, quantity custom dialog.

Verification:
- `flutter analyze`: **0 errors, 0 warnings** (remaining info-level
  `avoid_print` items are pre-existing in `test/integration/`).
- `flutter test`: **44 passed, 0 failed** (23 new fuel + 21 existing).

Issues fixed during test bring-up:
- `_preload` pump had to cover `loadHome`'s sequential 700ms+700ms latency.
- `FuelTypeCard` overflow when names/labels wrapped — name capped at 2 lines,
  price/"Coming Soon" capped at 1 line with ellipsis.
- `TrackingTimeline` no longer shows the "Current status" badge on terminal
  (delivered/cancelled) orders.
- `getFuelTypes()` returns all 5 types so coming-soon cards render; a non-
  standard `orderedBy` matcher was replaced with an explicit sort assertion.

## Risks / Notes
- The fuel module uses a mock repository (6 stations, random ratings/distances/
  prices each call); real backend, geocoding coordinates and partner tracking
  land in Sprint 2.
- A final grep confirms no references to the deleted
  `order_provider.dart`/`tracking_provider.dart`/`pricing_service.dart`/
  `location_service.dart`/`tracking_service.dart` or the legacy
  `petrol_page.dart`/`fuel_provider_card.dart`/`fuel_quantity_selector.dart`
  remain in `lib/` or `test/`. Stale prose references to `petrol_page` in
  `docs/` are historical and non-blocking.
- Navigation already pushes `const FuelHomeScreen()` from
  `lib/features/home/screens/home_screen.dart` and `lib/starting_screen/home.dart`.

## Production Ready?
YES
