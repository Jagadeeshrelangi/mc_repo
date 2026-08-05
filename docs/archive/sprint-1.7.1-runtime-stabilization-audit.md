# Runtime Audit Report

## Overall Completion
95% — every code-level audit finding is fixed, `flutter analyze` is 0 errors / 0 warnings, and `flutter test` is 44/44 green. The remaining 5% is on-device (hardware) verification, which cannot be performed from the CLI and is listed under "Remaining Issues".

## Overview
Sprint 1.7.1 — Runtime Stabilization & Navigation Audit. **No new features, no redesign, no color / typography / spacing changes.** Audited every module (Fuel, Mechanic, Home/Auth/Onboarding, ChatBot, legacy screens/widgets), fixed only runtime/navigation/overflow bugs, and removed dead code. Full navigator-graph audit (72 `Navigator.*` call sites) found all push targets resolve; the known design-level back-stack quirk in the mechanic flow is documented under Remaining Issues.

## What Was Audited
- **Fuel Delivery module** — full 7-step order flow + history/receipt flows. All pushes resolve; the `pushReplacement` chain (Booking → Payment → Confirmation → Tracking → Complete → Receipt) is intentional (Back returns to Home) and was retained. Provider is a root `ChangeNotifier` in `main.dart`, so it survives navigation.
- **Mechanic module** — entry points (`home_screen.dart`, `starting_screen/home.dart`, `mechanic_home_screen.dart` → `VehicleFormPage`) resolve; all screens exist.
- **Home / Auth / Onboarding** — modern dashboard quick-service cards navigate to the modern screens; ChatBot push/back behavior fixed; stale named route removed.
- **ChatBot** — tab-embed vs. pushed-route back-button behavior.
- **Legacy screens / widgets** — dead-code sweep with zero remaining references.

## Fixed Issues
| # | Module | Issue | Fix |
|---|--------|-------|-----|
| 1 | Fuel Live Tracking | Tracking poll timer in `FuelProvider` kept running after leaving the screen (no `stopTracking` on dispose) | Capture provider in `initState`; call `stopTracking()` in `dispose()` alongside the existing `_statusTimer` cancel |
| 2 | Fuel Live Tracking | Cancel dialog's post-cancel `popUntil` was **dead code** — it used the dialog's `ctx.mounted`, which is always false after `Navigator.pop(ctx)`, so navigation to Home depended on a rebuild side-effect | Use the screen's `context`/`mounted` for the `popUntil` |
| 3 | Fuel Live Tracking | "Call Partner" button was enabled-but-silent when a partner was assigned, and disabled otherwise | Always shows a SnackBar: "Calling {partner}..." or "No delivery partner assigned yet" |
| 4 | Fuel (5 screens) | Detail rows (`spaceBetween` label/value) overflowed on narrow screens | Value text wrapped in `Flexible` + `textAlign: right` in `live_tracking`, `order_confirmation`, `order_complete`, `order_history`, `receipt` |
| 5 | Fuel Live Tracking | 3-stat row (ETA / Distance / Time) with fixed-padding cards could overflow on narrow screens | Stats wrapped in `Expanded` with 8px gaps; card horizontal padding 20 → 10 |
| 6 | Fuel Station Card | Info row (rating/distance/ETA + price column) could overflow | Info group wrapped in `Expanded` + `Wrap` (flows to second line if needed) |
| 7 | Fuel Booking | Detected-location card had a no-op `onTap: () {}` (chevron implied action) | Tap now re-runs location detection (`_detectLocation`) |
| 8 | Fuel Type Card | Coming-soon cards were silently un-tappable (dead affordance) | Tap shows "… is coming soon" SnackBar |
| 9 | ChatBot | Pushed as a route (Home quick actions, `home_screen.dart:234`, `starting_screen/home.dart:384`) it had **no back button** (`automaticallyImplyLeading: false`) | `automaticallyImplyLeading: ModalRoute.of(context)?.canPop` — back arrow on pushed route, still clean on the tab root (`bottom_navigation.dart:35`) |
| 10 | App root | Stale named route `'/home' → OnboardingScreen` in `main.dart` (never used by any `pushNamed`) | Removed |
| 11 | Mechanic | AI analyze dialog: `Navigator.pop(context)` was unconditional — if the user dismissed the dialog (back), the awaited future then popped the **form screen** | Guarded pop via the `showDialog` future (`dialogDismissed` flag) — only the dialog is popped, never the screen |
| 12 | Mechanic | `BookingConfirmationScreen` used a `Spacer`-based non-scrollable `Column` — overflow risk on small screens / large text scale | Converted to `SingleChildScrollView` (layout preserved) |
| 13 | Profile | Badges row ("Pro Member / {pts} / {joined}") could overflow on narrow screens | `Row` → `Wrap` |
| 14 | Cleanup | Unused `ResponsiveBuilder`, `ResponsiveSpacing` (`app_responsive.dart`); unused `calculateDistance` (`location_utils.dart`); unused `searchTimeoutSeconds` / `defaultCity` (`fuel_constants.dart`) | Removed |

## Files Modified
- `lib/features/fuel_delivery/screens/live_tracking_screen.dart`
- `lib/features/fuel_delivery/screens/fuel_booking_screen.dart`
- `lib/features/fuel_delivery/screens/order_confirmation_screen.dart`
- `lib/features/fuel_delivery/screens/order_complete_screen.dart`
- `lib/features/fuel_delivery/screens/order_history_screen.dart`
- `lib/features/fuel_delivery/screens/receipt_screen.dart`
- `lib/features/fuel_delivery/widgets/fuel_station_card.dart`
- `lib/features/fuel_delivery/widgets/fuel_type_card.dart`
- `lib/features/fuel_delivery/utils/location_utils.dart`
- `lib/features/fuel_delivery/constants/fuel_constants.dart`
- `lib/features/mechanic/screens/vehicle_form_screen.dart`
- `lib/features/mechanic/screens/booking_confirmation_screen.dart`
- `lib/bottom_bar/chatboard.dart`
- `lib/bottom_bar/profile_screen.dart`
- `lib/main.dart`
- `lib/theme/app_responsive.dart`
- `lib/parts/order_data.dart` (stale doc comment only)

## Files Deleted
Verified zero references (lib + test) before deletion:
- `lib/widgets/` — 27 dead widgets: `app_avatar`, `app_badge`, `app_bottom_sheet`, `app_button`, `app_card`, `app_chip`, `app_dialog`, `app_empty_state`, `app_error_state`, `app_input`, `conversation_card`, `image_gallery`, `invoice_card`, `location_search_delegate`, `price_breakdown_card`, `pulsing_marker`, `rating_widget`, `sos_button`, `timeline_tile`, `tracking_timeline`, `typing_indicator`, `vehicle_report_card`, `wishlist_button`, `category_chip`, `cart_item_card`, `price_summary_card`, `product_card`
- `lib/parts/parts_screen.dart`, `lib/parts/cart_screen.dart` — orphaned marketplace screens (nothing imports them; `lib/parts/order_data.dart` is **kept** — the live Orders tab depends on it)

No files were renamed.

## Remaining Issues
1. **Mechanic back-stack (design-level, NOT fixed)**: `BookingSummary → Confirmation → LiveTracking` use `pushReplacement`, so after tracking, Back lands on `SelectServiceScreen` (a stale booking screen) rather than Home. This is the intended flow design (Back → previous step); the whole chain uses `pushReplacement` so there are no duplicate screens on the stack. Fixing the landing point requires a flow redesign — deferred to Sprint 2, documented here.
2. **On-device verification pending (5%)**: the CLI cannot verify hardware behavior — real OSM map tiles, GPS detection, narrow-screen (320dp) rendering, keyboard insets, and Android back-button behavior across the fixed screens still need a device run.
3. **Minor unused API kept intentionally** (harmless, standard model/provider members): `TrackingInfo.statusLabel` (written by repository, not yet read by UI), `isRefreshing` getters on `FuelProvider`/`MechanicProvider`/`HomeProvider`, `LocationProvider.removeSavedAddress`, `AuthProvider.isLoggedIn`/`clearError`, `MechanicProvider.clearError`. `FuelType.orderable`, `FuelService.isValidQuantity` and `Invoice.orderId` are **used by tests** and were kept.
4. **Info-level lints** (`avoid_print`) in `test/integration/verify_chatbot_widget.dart` and `verify_e2e_network.dart` — pre-existing script files, out of scope.

## Verification
- `flutter analyze` → **0 errors, 0 warnings** (only pre-existing info-level lints in integration scripts)
- `flutter test` → **44/44 passed** (fuel 23, mechanic, home dashboard; no tests import any deleted file)
- Post-deletion sweep: **zero** references to all 29 deleted files/classes across `lib/` + `test/`

## Production Ready?
**No — not yet.** Every code-level audit item is fixed and the suite is green, but production-ready must not be claimed until a manual on-device run confirms: live map rendering, real GPS detection, narrow-screen layouts, keyboard/safe-area handling, and Android back-button behavior on the screens fixed in this sprint. After that verification, only the mechanic back-stack redesign (Remaining Issue #1) remains as a known UX debt item.
