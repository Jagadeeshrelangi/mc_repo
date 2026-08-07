# Frontend Lock Report — Frontend Lock Candidate

> Sprint 1.9b · Frontend Freeze Certification
> Date: 2026-08-05 (final lock 2026-08-02) · Flutter 3.29.2

## 1. Purpose

This report freezes the frontend as the **Frontend Lock Candidate**. From the
date of this report, the UI, data models, navigation, and app architecture are
frozen. No redesign, no color/typography/icon/card/layout/animation changes,
and no navigation-philosophy changes are permitted without a new sprint
authorization. Only bug fixes and documentation updates are allowed until RC1 is approved.

## 2. Certification Gates

| Gate | Result | Evidence |
|---|---|---|
| `flutter analyze` | PASS — "No issues found!" (0 issues) | Clean static analysis |
| `flutter test` | PASS — **162 / 162** tests passing | Full suite, all modules |
| Dead-code cleanup | PASS — 29 legacy files removed + runtime-trace wiring removed | See §5 |
| Runtime/network hazards | PASS — no real-HTTP calls in mock paths | Vehicle form refactor §5.2 |
| A11y & dark-mode regressions | PASS | See §5.4 and §5.6 |

## 3. Frozen Scope (RC1)

Frozen surfaces, in order of stability commitment:

1. **App shell & navigation** — `lib/main.dart`, `lib/app_wiring.dart`,
   `lib/bottom_bar/bottom_navigation.dart` (5-tab `IndexedStack`),
   `lib/starting_screen/home.dart`.
2. **Design system** — `lib/theme/*` (AppColors, AppSpacing/AppElevation,
   AppResponsive, ThemeProvider). Token values are frozen; new tokens require
   sign-off.
3. **Feature modules** — Home, AI Assistant, Marketplace, Mechanic, Fuel
   Delivery, Vehicle Location, Profile, Orders tab.
4. **Data models** — entity fields in `lib/features/*/models/`; order store
   shape in `lib/parts/order_data.dart`. Backward-compatible field additions
   only.
5. **Repository interfaces** — `lib/features/*/repositories/*.dart`. These are
   the Sprint 2 backend integration seams; the UI never bypasses them.

## 4. Verified Baseline

- **Static analysis:** `flutter analyze` → **No issues found!**
- **Test suite:** **162/162 passing** across:
  - AI module — 25
  - Fuel module — 37
  - Marketplace module — 43
  - Profile module — 30
  - Mechanic module — 10
  - Vehicle location — 8
  - Home dashboard — 3
  - Runtime integration flow — 2
  - Widget regression — 4
  - **Total 162**

## 5. Changes Locked In This Sprint (1.9b)

### 5.1 Dead-code removal (29 files)

Legacy code that referenced a non-existent backend was removed so the mock
baseline is honest and analyzers cannot regress silently:

- `lib/services/ai_repository.dart`, `lib/services/api_client.dart`
- `lib/bottom_bar/chatboard.dart`
- `lib/widgets/` — 12 orphaned widgets (chat_bubble, chat_input,
  thinking_indicator, quick_action_card, diagnosis_card, severity_badge,
  notification_card, profile_stat_card, settings_tile, vehicle_card,
  wallet_card)
- Module barrels (deleted as unused): `lib/features/ai/ai.dart`,
  `ai/screens/screens.dart`, `fuel_delivery/providers/providers.dart`,
  `fuel_delivery/screens/screens.dart`, `marketplace/marketplace.dart`,
  `marketplace/screens/screens.dart`, `marketplace/widgets/widgets.dart`,
  `mechanic/mechanic.dart`, `mechanic/screens/screens.dart`,
  `mechanic/widgets/widgets.dart`, `profile/profile.dart`
- Dead model `lib/features/auth/models/user.dart`
- Legacy verify scripts `test/integration/verify_chatbot_widget.dart`,
  `test/integration/verify_e2e_network.dart`

Restored/fixed: `lib/features/fuel_delivery/widgets/widgets.dart` barrel now
exports all 12 widgets including the 5 newer ones (delivery_location_card,
fuel_station_card, fuel_vehicle_card, payment_method_tile, tracking_timeline).

### 5.2 Runtime hazard fixes (no silent network hangs)

- **Vehicle form** (`lib/features/mechanic/screens/vehicle_form_screen.dart`):
  replaced the legacy `services/AIRepository` (real HTTP to
  `127.0.0.1:8000` with 3×30s retries ≈ 90s hang when the backend is absent)
  with the AI module's mock engine via `AiRepository.diagnoseVehicle`.
  Diagnostic details now render typed fields
  (recommendedService, estimatedCost, confidence, recommendedAction).

### 5.3 State & refresh fixes

- **AI provider** (`lib/features/ai/providers/ai_provider.dart`): fixed a
  triple-repository bug — all of AiProvider, AiService, and DiagnosisService
  now share ONE `AiRepository` instance. Pull-to-refresh no longer wipes
  user-created conversations or pin overrides.
- **Orders tab + Marketplace integration**:
  - `lib/bottom_bar/bottom_navigation.dart` body is now an `IndexedStack`
    (all 5 tabs stay mounted).
  - New `OrderStore` singleton (`lib/parts/order_data.dart`) notifies the
    Orders tab when `addMarketplaceOrder` inserts a new order, so the tab
    rebuilds without switching tabs.
  - `lib/bottom_bar/order_screen.dart` removed a rebuild-every-tick tab
    listener; it now rebuilds only on tab change or `OrderStore` notify.
- **Perf:** `lib/features/marketplace/widgets/product_card.dart` switched from
  `context.watch` to `context.read` + `context.select` (rebuilds only on
  wishlist changes).
- **Runtime trace** (`lib/debug/runtime_trace.dart`): deleted entirely in the
  final lock pass — the `kRuntimeTrace = false` gate, `TraceNavigatorObserver`
  wiring in `main.dart`, and all 11 call-site imports were removed. The runtime
  integration test defines its own local observer instead.

### 5.4 A11y & dark-mode fixes

- `lib/features/marketplace/widgets/quantity_stepper.dart`: `Semantics`
  (button/enabled/label) wrapping the internal `_Button`.
- `lib/starting_screen/home.dart`: `Semantics` on the search bar + SOS card.
- `lib/features/mechanic/widgets/review_star.dart`: dark-mode empty-star color
  corrected to `Colors.white38`.

### 5.5 Test updates

- `test/integration/runtime_marketplace_flow_test.dart`: the two
  `find.text('Parts')` taps now use `.first` (the Home dashboard label is
  tree-first; the hidden Services tab 'Parts' label stays in the tree under
  the IndexedStack).
- `test/widget_test.dart`: replaced the trivial smoke test with 4 real
  regression tests — rating-stars semantics, product-card touch targets and
  tooltips, wishlist toggle label, and narrow-width quick-services grid.

### 5.6 Final polish (frontend lock pass)

Navigation, performance, dark-mode, accessibility, responsive, and code-quality
fixes applied in the final lock pass:

- **Navigation:** conditional back button on Marketplace home
  (`Navigator.canPop` + `maybePop`); Wallet → `openWallet`, Help & Support →
  `openSupport` from the drawer; Home notifications → `openNotificationSettings`,
  vehicle card → `openMyVehicles`, "Shop All" → Marketplace; search bar →
  real `HomeSearchScreen`; fixed "Coupon MECHA20" promo copy; mechanic booking
  availability surcharge (₹100) shown as an explicit cost line.
- **Performance:** Fuel live-tracking screen's 1s whole-screen timer isolated
  into a self-contained `_ElapsedTimerText` widget; mechanic live-tracking's
  3s progress timer moved into a `_ProgressTimeline` widget so the map never
  rebuilds on ticks; `context.watch<LocationProvider>` → `context.select` in
  `location_header.dart` and home screen; dialog `TextEditingController` now
  disposed.
- **Dark mode:** `AppLoading` message/gradient, `PasswordStrength` inactive
  bars, product-detail offer strip, primary-button disabled colors, and
  quantity-stepper border/icons all use dark tokens in dark mode.
- **Accessibility:** 13 icon-only `IconButton`s gained `tooltip:`; three
  undersized bare `GestureDetector` icons converted to `IconButton`s or given
  `Semantics` + `Tooltip`; product-card wishlist/cart buttons enlarged to 44px
  with tooltips; `RatingStars` merged semantics ("Rated X out of 5"); hero
  carousel disables autoplay under reduced motion and exposes
  "Promotion banner, offer N of M".
- **Responsive:** quick-services grid and services grid now adapt column count
  to width (2/3/4); marketplace category grid derives `crossAxisCount` from
  width.
- **Code quality:** orphan `coming_soon.dart` deleted; `runtime_trace.dart`
  deleted and all wiring/imports stripped; `forceShowOnboarding` dev flag
  removed; `flutter analyze` back to 0 issues including pre-existing lints.

## 6. Freeze Governance

| Area | Rule |
|---|---|
| Colors / typography / icons / cards / layout / animation | Frozen. No changes without sprint sign-off. |
| Navigation structure & philosophy | Frozen. |
| Data models | Frozen; backward-compatible additions only. |
| Repository interfaces | Frozen; this is the Sprint 2 backend seam. |
| Permitted changes | Runtime/UX/a11y/responsive/state bugs only, plus docs. |
| Verification required after any change | `flutter analyze` (0 issues) + full `flutter test` (162/162). |

## 7. Deliverables Produced Alongside This Lock

- `MECHA_CONNECT_MASTER_HANDBOOK.md`
- `FRONTEND_ARCHITECTURE.md`
- `UI_DESIGN_SYSTEM.md`
- `NAVIGATION_MAP.md`
- `API_CONTRACT.md`
- `DATABASE_BLUEPRINT.md`
- `QA_CERTIFICATION_REPORT.md`
- `PROJECT_STATUS_REPORT.md`

## 8. Sign-off

| Role | Decision |
|---|---|
| Frontend freeze | Candidate surfaces frozen as of 2026-08-02 |
| Static analysis | PASS (0 issues) |
| Test suite | PASS (162/162) |
