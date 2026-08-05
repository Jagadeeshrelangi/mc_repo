# Sprint 1.5 — Home Dashboard (Finalized)

## Completion
100%

## Features Implemented

### 1. Feature-First Home Architecture
```
lib/features/home/
  models/home_models.dart              # HomeData + 8 section models + mock data
  repositories/home_repository.dart    # fetchHomeData() — Sprint 2 API-ready seam
  providers/home_provider.dart         # load / refresh / error / greeting
  screens/home_screen.dart             # HomeDashboard (tabs[0])
  screens/home_search_screen.dart      # functional mock search
  widgets/                             # 14 widgets (header, cards, lists, states)
```
- `HomeData` aggregates all dashboard sections into one fetch payload
- `HomeRepository.fetchHomeData()` simulates an 800ms network delay — swap for real API in Sprint 2 without touching UI
- `HomeProvider` registered once in `main.dart` MultiProvider (line 40), consumed via `context.watch/read`

### 2. HomeProvider State Machine
| State | Trigger | UI |
|---|---|---|
| Loading | `load()` (first build) | `HomeLoadingSkeleton` — animated shimmer (pulsing opacity) |
| Error | `_repository` throws | `HomeErrorView` — icon + message + "Try Again" → `refresh()` |
| Success | fetch completes | Full dashboard + pull-to-refresh |
- `load()` guards against duplicate fetches (`_data != null`)
- `refresh()` supports `RefreshIndicator` and error retry, with `isRefreshing` flag

### 3. Loading Skeleton
- `HomeLoadingSkeleton`: pulsing opacity animation (0.4→0.9, 1.1s) mirroring real layout
- Header row, location card, search bar, emergency, vehicle, AI card, nearby strip, and 3×2 quick-service grid placeholders
- Non-interactive (`NeverScrollableScrollPhysics`) so no scrolling during load

### 4. Pull-to-Refresh
- `RefreshIndicator` wraps the scrollable dashboard
- `AlwaysScrollableScrollPhysics` so pull works even when content fits the screen
- `refresh()` re-fetches and `notifyListeners()` on completion

### 5. Error Handling
- `HomeErrorView`: cloud-off icon, message, orange "Try Again" button → `provider.refresh()`
- Error message surfaces `provider.error` string (repo exception → UI)

### 6. Empty States (per section)
- Quick Services → grid empty message
- Nearby Services → "No nearby services"
- Marketplace → "Marketplace is empty"
- Recent Activity → "No activity yet"
- Offers → "No offers right now"
- All via reusable `HomeEmptyView` (icon + title + message)

### 7. Functional Mock Search
- Tapping `HomeSearchBar` opens `HomeSearchScreen` (autofocus, live filter on every keystroke)
- Filters Quick Services (by label) and Nearby Services (by name + category)
- "No results found" empty state for unmatched queries
- Result taps reuse the same navigation handlers as the dashboard (Mechanic → `VehicleFormPage`, Fuel → `FuelHomeScreen`, AI → `ChatBot`)

### 8. Dynamic Greeting
- `HomeProvider.greetingForHour(hour)` → Good Morning (<12) / Good Afternoon (<17) / Good Evening
- `HomeHeader` renders greeting + user's initial from `UserProfile`

### 9. Navigation Wiring (no dead buttons)
| Card | Action |
|---|---|
| Mechanic (Quick Service) | → `VehicleFormPage` (mechanic_screen.dart) |
| Fuel (Quick Service) | → `FuelHomeScreen` |
| AI Diagnosis (Quick Service + AI Assistant card) | → `ChatBot` |
| Others (Parts/Battery/Towing), Notifications, Location, SOS, Vehicle, nearby/marketplace/activity/offer details | "coming soon" SnackBar |

## Files Created (16)
- `lib/features/home/models/home_models.dart`
- `lib/features/home/repositories/home_repository.dart`
- `lib/features/home/providers/home_provider.dart`
- `lib/features/home/screens/home_screen.dart`
- `lib/features/home/screens/home_search_screen.dart`
- `lib/features/home/widgets/home_header.dart`
- `lib/features/home/widgets/location_card.dart`
- `lib/features/home/widgets/search_bar_widget.dart`
- `lib/features/home/widgets/emergency_card.dart`
- `lib/features/home/widgets/vehicle_card.dart`
- `lib/features/home/widgets/ai_assistant_card.dart`
- `lib/features/home/widgets/quick_service_card.dart`
- `lib/features/home/widgets/nearby_service_card.dart`
- `lib/features/home/widgets/marketplace_card.dart`
- `lib/features/home/widgets/recent_activity_card.dart`
- `lib/features/home/widgets/offer_banner.dart`
- `lib/features/home/widgets/section_title.dart`
- `lib/features/home/widgets/home_loading_skeleton.dart`
- `lib/features/home/widgets/home_error_view.dart`
- `lib/features/home/widgets/home_empty_view.dart`
- `test/home_dashboard_test.dart`

## Files Modified (2)
- `lib/main.dart` — registered `HomeProvider(HomeRepository())` in MultiProvider
- `lib/bottom_bar/bottom_navigation.dart` — import updated to `features/home/screens/home_screen.dart`

## Files Deleted (14)
- `lib/home/home_screen.dart` (replaced by feature-first version)
- `lib/home/home_data.dart` (models moved to `features/home/models/`)
- `lib/home/widgets/` — all 12 widgets moved to `features/home/widgets/`

## Architecture Changes
- Home module migrated from flat `lib/home/` to feature-first `lib/features/home/`
- Design tokens preserved 1:1: `AppColors`, `AppSpacing`, `AppElevation`, `AppResponsive`, `Space Grotesk`, brand gradients
- No redesign — same visual design, enhanced engineering

## UI Improvements
- Skeleton shimmer replaces blank screen during load
- Pull-to-refresh on the whole dashboard
- Reusable error + empty states (5 sections)
- Functional search (was: dead "Search coming soon!" screen)
- Added chevron affordance on `VehicleCard` (tappable)
- Cards now accept `onTap` callbacks — navigation driven by the screen, not baked into widgets

## Responsive Status
PASS — `AppResponsive.scale()/scaleFont()/horizontalPadding()` + `ConstrainedContent` desktop wrapper preserved

## Dark Mode Status
PASS — `isDark` throughout, all widgets adapt colors/gradients/borders

## Bugs Fixed
- `HomeLoadingSkeleton` used `Expanded` inside `Padding` (ParentDataWidget error) → restructured to `Expanded` direct under `Row`
- Nearby service card rating row overflowed by 18px on narrow screens → distance text wrapped in `Flexible` + ellipsis
- Search screen threw `undefined_method: watch` → added missing `provider` import
- Old search opened a dead "Search coming soon!" page → real filtering screen
- Old `HomeDashboard` was fully static with no loading/error/refresh states → provider-driven state machine

## Tests
- `test/home_dashboard_test.dart` (new): renders all 5 dashboard sections after load; search filters quick services by query
- `test/widget_test.dart`: smoke test still passes
- `flutter test`: **3 passed, 0 failed**

## Remaining Issues
None introduced by Sprint 1.5. 22 pre-existing info-level issues unrelated (file names, private-type-in-API, test prints).

## flutter analyze Result
0 errors, 0 warnings (22 pre-existing info-level only)

## Production Ready?
YES
