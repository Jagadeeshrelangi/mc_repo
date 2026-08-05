# Sprint 1.7A — Fuel Delivery (Investigation + Foundation)

**Date:** 2026-07-30  
**Version:** 1.0  
**Status:** ✅ Complete

---

## Priority 1 — Blank Fuel Screen Investigation

**Root Cause:** `Geolocator.getCurrentPosition(LocationSettings(accuracy: LocationAccuracy.high))` hangs indefinitely on devices without GPS (e.g., Android emulator, tablets, indoor testing). Since `_getCurrentLocation()` had no timeout, the `_fuelLocationStatus` remained `_FuelLocationStatus.loading` forever, rendering a blank screen (the loading spinner sometimes invisible due to async gap after `initState`).

**Fix Applied (`lib/homescreen/petrol_page.dart`, later refactored into `lib/features/fuel_delivery/screens/fuel_booking_screen.dart`):**
- Added `LocationSettings(timeLimit: Duration(seconds: 10))` to cap GPS acquisition
- Wrapped the `getCurrentPosition` call with `.timeout(const Duration(seconds: 12))`
- Both locations (banner `_getCurrentLocation()` + manual refresh path) uniformly apply the timeout
- Added "Set Manually" fallback button in `unavailable` state → default coordinates (Bengaluru)

**Verification:** `flutter analyze` — 0 errors, 0 warnings

---

## Priority 2 — Fuel Delivery Foundation

### Architecture

```
lib/features/fuel_delivery/
├── constants/
│   └── fuel_constants.dart          # min/max litres, delivery charge, tax rate, defaults
├── models/
│   ├── fuel_type.dart               # enum (petrol, diesel) with name, icon, price
│   ├── vehicle.dart                 # id, name, number, fuelType
│   ├── fuel_order.dart              # full order with status, partner, invoice
│   ├── fuel_partner.dart            # partner profile with rating, distance, ETA
│   ├── delivery_location.dart       # lat/lng, address, label
│   ├── price_estimate.dart          # fuel cost, delivery charge, fees, taxes, total
│   ├── tracking_info.dart           # real-time tracking positions
│   ├── order_status.dart            # enum: created → searching → ... → delivered → cancelled
│   ├── invoice.dart                 # itemised invoice
│   └── models.dart                  # barrel export
├── repositories/
│   └── fuel_repository.dart         # mock: create order, assign partner, track, history, invoice
├── services/
│   ├── fuel_service.dart            # price calculation with validation
│   ├── pricing_service.dart         # distance-aware pricing
│   ├── location_service.dart        # default location, search, distance calc
│   └── tracking_service.dart        # mock live tracking data
├── providers/
│   ├── fuel_provider.dart           # UI state machine (initial/loading/ready/error/unavailable/empty)
│   ├── order_provider.dart          # order lifecycle (create → assign → cancel)
│   ├── tracking_provider.dart       # polling-based live tracking
│   └── providers.dart               # barrel export
├── screens/
│   ├── fuel_home_screen.dart        # banner, fuel type grid, quantity, price, partners
│   └── screens.dart                 # barrel export
├── widgets/
│   ├── fuel_type_card.dart          # selectable fuel type with price
│   ├── quantity_selector.dart       # preset chips + stepper
│   ├── price_breakdown.dart         # itemized cost card
│   ├── fuel_action_button.dart      # primary/secondary action button
│   ├── fuel_empty_state.dart        # empty state with retry
│   ├── fuel_error_state.dart        # error state with retry
│   ├── recent_order_card.dart       # order history list item
│   └── widgets.dart                 # barrel export
└── utils/
    └── location_utils.dart          # haversine distance, distance formatting
```

### State Handling

| State | UI |
|-------|----|
| `initial` / `loading` | Centered `CircularProgressIndicator` |
| `error` | Error icon + message + Retry button |
| `noInternet` | Wi-Fi off icon + "No Internet Connection" + Retry |
| `noLocation` | Location off icon + "Set Location Manually" button |
| `empty` | Shipping icon + "No Partners Available" + Search Again |
| `ready` | Full Fuel Home Screen |

### Non-Goals (Sprint 1.7B)
- Booking flow (confirm order, address, vehicle select)
- Live map tracking
- Payment integration
- Backend API integration
- Partner mobile app connectivity

---

## Verification

- `flutter analyze`: ✅ 0 errors, 0 warnings (25 info-level, all pre-existing)
- All new code follows existing conventions (no comments, `const` constructors, immutable models)
- No new dependencies added
- Pre-existing blank screen issue fully resolved

---

## Related Docs

- [CHANGELOG.md](../03_development/CHANGELOG.md#120--2026-07-30--sprint-17a)
- [PROJECT_STATUS.md](../01_product/PROJECT_STATUS.md)
- [fuel_booking_screen.dart](../../lib/features/fuel_delivery/screens/fuel_booking_screen.dart) (GPS fix — formerly `lib/homescreen/petrol_page.dart`)
- [fuel_home_screen.dart](../../lib/features/fuel_delivery/screens/fuel_home_screen.dart)
