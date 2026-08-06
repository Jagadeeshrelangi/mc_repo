# Fuel Booking Wizard — Step 3 (Location) CTA Regression — Fix Report

## Severity
P0 (Flow Blocker) — resolved.

## Root Cause
Step 3's status banner in `_buildLocationStatus` (success case) was a fixed-width
`Row`: location icon + `Expanded("📍 Current Location Detected")` + a
`TextButton.icon("Use Current Location")` whose natural width is ~322px at large
text scales (the Ahem test font renders each glyph at full em-width; real devices
hit the same failure under accessibility text scaling).

On a 360dp phone the row had only **306px** available (scroll padding 16×2 + banner
padding 14+6), so the fixed content overflowed by **42px** (`fuel_booking_screen.dart:670`).
Because the status text sat in `Expanded`, it collapsed to ~0 width and wrapped
**character-by-character**, exploding the banner to **456px tall** — the reported
"large empty space below the location cards." This destroyed the location step's
bottom action area and left the flow looking blocked.

Two related narrow-screen overflows were found in the same audit:
- Step progress indicator: 5 step labels + `Expanded` connectors could not fit 360dp at large text scale.
- `PriceBreakdown._row` (Step 1 estimate + Step 5 review): `spaceBetween` Row of two intrinsic-width `Text`s overflowed at 320dp.

## Why the Continue button "disappeared"
The bottom CTA is the last child of the body `Column`
(Header → scrollable content → persistent bottom action bar), shared by all 5 steps.
The exploded banner (456px) + garbled status row consumed the visible area below the
location cards, so the bottom action area was displaced/destroyed and the booking
could not be continued.

## Files Modified
| File | Change |
|------|--------|
| `lib/features/fuel_delivery/screens/fuel_booking_screen.dart` | Progress indicator → `FittedBox(scaleDown)` + fixed-width connectors; location success banner `Row` → `OverflowBar` (action wraps below status text, never overflows); location idle action → `FittedBox(scaleDown)`; location error action `Row` → `Wrap`; bottom bar **kept** as last child of the body Column |
| `lib/features/fuel_delivery/widgets/price_breakdown.dart` | `_row` label/value wrapped in `Flexible` (+ ellipsis, right-aligned value) |
| `test/fuel_module_test.dart` | +2 regression tests (see Verification) |

### Why the bar stays in the body Column (not `bottomNavigationBar`)
An experiment moved the bar to `Scaffold.bottomNavigationBar`; the probe showed
`bottomNavigationBar` is **not** lifted above the keyboard on Step 3 (Continue sat at
y≈590 with a 280px keyboard inset), i.e. it would be covered by the keyboard on a real
device — reintroducing the exact "Continue missing" symptom. The body-Column placement
lifts the bar above the keyboard (Continue at y≈310-330), so it was kept.

## Verification
- New: **"shows the persistent bottom bar on all 5 steps at 320dp"** — 320×640 surface,
  walks all 5 steps, opens the keyboard on Step 3; asserts **Back/Continue on every step**
  (and Place Order on Step 5); fails pre-fix (42px overflow + 456px banner), passes
  post-fix (banner = one compact line, ~280×38).
- New: **"location error state fits at 320dp"** — error banner (Retry / Enter Manually)
  + Back/Continue render without overflow.
- Pre-fix failure: `RenderFlex overflowed by 42 pixels on the right` at
  `fuel_booking_screen.dart:670`; the same test exposed the `price_breakdown.dart:45`
  overflow (22px) once the banner was fixed.
- `flutter analyze` → **0 errors, 0 warnings**
- `flutter test` → **48/48 passed**

## Remaining Issues
None for this flow. On-device confirmation of the keyboard + narrow-screen behavior
remains part of the Sprint 1.7.2 Phase 1/4 manual certification (not executable from CLI).
