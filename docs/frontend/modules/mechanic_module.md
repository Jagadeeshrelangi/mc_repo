# Module Knowledge: Mechanic (`frontend/lib/features/mechanic/`)

> Phase 5 · Entry via Services tab. Source: Architecture §5.3, API §6, FEATURE_SPECIFICATIONS §5.

## Purpose
Complete mechanic booking lifecycle: browse → details → select service →
vehicle form → summary → confirm → live track → complete → rate/review → history.

## Inventory
| Layer | Items |
|---|---|
| Models (3 files, 6 classes) | `MechanicInfo`, `MechanicService`, `MechanicCategory`, `MechanicReview`, `BookingRequest`, `Booking` |
| Provider | `MechanicProvider` (root graph #5; repository constructor-injectable) |
| Repositories | `MechanicRepository` |
| Services | (uses AI module `DiagnosisService` for VehicleForm) |
| Screens (11) | `MechanicHomeScreen`, `NearbyMechanicsScreen`, `MechanicDetailsScreen`, `SelectServiceScreen`, `VehicleFormScreen`, `BookingSummaryScreen`, `BookingConfirmationScreen`, `LiveTrackingScreen`, `JobCompletedScreen`, `RatingReviewScreen`, `BookingHistoryScreen` |
| Widgets (8) | mechanic card, review stars, service tile, tracking timeline, etc. |

## Key Behavior
- Seed: 4 mechanics (`m1`–`m4`, `m4` unavailable), 3 featured, reviews `r1`–`r8`,
  8 categories, 8 services.
- VehicleForm runs the AI mock diagnosis (no HTTP) — 1.9b fix removed the legacy
  real-HTTP call to `127.0.0.1:8000` (90s hang hazard).
- Live tracking: 3s `_ProgressTimeline` timer; map never rebuilds on ticks.
- Availability surcharge (₹100) shown as an explicit cost line.

## Failure Paths
Mechanic unavailable → card disabled; location denied → permission dialog; GPS disabled →
settings redirect; `MechanicNetworkException` retry; "No mechanics found" empty state.

## Tests
`test/mechanic_module_test.dart` — 10 tests.

## Backend Relation (Sprint 2)
`mechanics` (+ skills/languages/working hours), `mechanic_services` + offered M:N,
`mechanic_categories`, `mechanic_reviews`, `mechanic_bookings`, `booking_events` (JSONB),
`ratings`. Live tracking via `tracking_events` + WebSocket.
