# Sprint 1.6a — Mechanic Location Auto Detection

## Completion
100%

## Summary
VehicleFormScreen now auto-detects the user's location when it opens — requests
permission, resolves GPS (10s timeout), reverse-geocodes via Nominatim, and
auto-fills the Address + Pincode fields. Manual entry stays fully available and
a "Use Current Location" button refreshes anytime. Permission-denied and timeout
states surface Retry / Enter Manually actions.

## What Changed

### New shared service — `lib/services/geocoding_service.dart`
Extracted all Nominatim logic (previously buried inside `LocationProvider`) into
a reusable singleton service:
- `GeocodingResult` — structured address: `street`, `locality`, `city`, `state`,
  `pincode` + `fullAddress` / `shortAddress` / `isEmpty`.
- `GeocodingService.reverseGeocode(LatLng)` → `GeocodingResult?` (uses
  `addressdetails=1`).
- `GeocodingService.searchLocations(String)` → forward geocoding candidates
  (moved from provider so no logic is duplicated).

### `lib/services/location_provider.dart` (refactored, behavior preserved)
- Now delegates reverse + forward geocoding to `GeocodingService`.
- Exposes structured `currentAddressDetails` / `selectedAddressDetails`
  (previous `_currentAddress`/`_selectedAddress` short-string behavior retained).

### `lib/features/mechanic/screens/vehicle_form_screen.dart`
- Auto-detection starts in `initState` (no button press).
- States: `idle | loading | success | denied | error`.
- Loading: "Loading current location..." + small spinner; only the Address and
  Pincode fields are disabled — the rest of the form stays usable.
- Success: fills Address + Pincode (pincode only when available) and shows
  "📍 Current Location Detected".
- Manual override: fields remain editable; "Use Current Location" refresh button
  (shown in success + idle states).
- Permission denied → "Location permission denied." with **Retry** / **Enter Manually**.
- Timeout (~10s via `.timeout`) / GPS failure → "Unable to determine your location."
  with **Retry** / **Enter Manually**.
- No crashes: permission request wrapped in try/catch, `mounted` guards, and
  `_isDetectingLocation` re-entry guard.

Reused the existing `LocationProvider` for permission + GPS acquisition (no
duplicated location logic). No other mechanic functionality was modified.

## Verification
- Permission flow: covered (denied → banner + actions; granted → auto-fill).
- Auto-fill works: widget test asserts Address + Pincode populated on detection.
- Manual editing still works: fields editable outside loading; Enter Manually
  keeps them editable.
- Retry works: widget test flips denied→granted and taps Retry → auto-fill.
- Timeout handled: `.timeout(10s)` → error banner (tested via unresolved GPS → error state).
- No crashes: defensive catches + `mounted` guards.
- Responsive: status cards lay out within the existing scroll view (rows use
  `Expanded`).
- Dark mode: all status cards use `context.cardBg` / `context.border` /
  `context.textPrimary` / `context.textSecondary` theme helpers.

## Tests
- `test/vehicle_location_test.dart` — 8 new tests (2 GeocodingResult unit + 6
  VehicleForm widget tests). All pass.
- `flutter analyze`: **0 errors, 0 warnings** (20 pre-existing info only —
  `avoid_print` in `test/integration/`).
- `flutter test`: **21 passed, 0 failed** (8 new + 13 existing).

## Files
- Created: `lib/services/geocoding_service.dart`, `test/vehicle_location_test.dart`
- Modified: `lib/services/location_provider.dart`,
  `lib/features/mechanic/screens/vehicle_form_screen.dart`

## Production Ready?
YES
