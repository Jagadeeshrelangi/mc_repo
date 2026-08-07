# Module Knowledge: Fuel Delivery (`frontend/lib/features/fuel_delivery/`)

> Phase 5 · Entry via Services tab. Source: Architecture §5.4, API §7, SPRINT_1_7A.

## Purpose
On-demand fuel delivery: booking, payment, confirmation, live tracking, complete,
receipt/invoice, history.

## Inventory
| Layer | Items |
|---|---|
| Models (11) | `DeliveryLocation`, `FuelOrder`, `FuelPartner`, `FuelStation`, `FuelVehicle`, `Invoice`, `PriceEstimate`, `TrackingInfo` (+ `FuelType`, `OrderStatus`, `FuelConstants`) |
| Provider | `FuelProvider` (root graph #8, `locationProvider:` dep) |
| Repositories | `FuelRepository` (700ms latency) |
| Services | `FuelService` (price), `NearbyService`, `QuickService` |
| Screens (8) | `FuelHomeScreen`, `FuelBookingScreen`, `PaymentScreen`, `OrderConfirmationScreen`, `LiveTrackingScreen`, `OrderCompleteScreen`, `ReceiptScreen`, `OrderHistoryScreen` |
| Widgets (13) | delivery location card, fuel station card, fuel vehicle card, payment method tile, tracking timeline, etc. |
| Constants | `fuel_constants.dart` (min/max litres, delivery charge, tax rate, defaults) |

## Key Behavior
- GPS capped: `LocationSettings(timeLimit: 10s)` + `.timeout(12s)`; "Set Manually" fallback
  (Bengaluru default coords) — Sprint 1.7A blank-screen fix.
- OrderStatus: requested → accepted → fuelPacked → partnerAssigned → enRoute → arrived → delivered (+ cancelled).
- `FuelService.calculatePrice`: `grandTotal = fuelCost + deliveryCharge + platformFee + taxes`.
- Seed: 6 stations, 3 vehicles, history `FUEL-2026-0005..0009`, invoice `INV-<orderId>`.
- 1s whole-screen timer isolated in `_ElapsedTimerText` (map never rebuilds on ticks).

## Failure Paths
GPS denied/disabled (R1/R9) → manual entry; station out-of-stock blocked;
`FuelNetworkException` retry; order cancel → cancelled.

## Tests
`test/fuel_module_test.dart` — 37 tests.

## Backend Relation (Sprint 2)
`fuel_orders`, `price_estimates`, `fuel_stations`, `fuel_partners`, `tracking_events`,
`invoices`. Live tracking via WebSocket push.
