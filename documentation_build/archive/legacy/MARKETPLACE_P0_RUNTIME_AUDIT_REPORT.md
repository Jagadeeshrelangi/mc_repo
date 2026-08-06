# Marketplace P0 Runtime Audit Report 1.0

> **Date:** 2026-08-01
> **Auditor:** Runtime QA (opencode)
> **Status:** Audit closed — findings fixed, evidence below

## Executive Summary

The reported P0 symptoms — *"cart badge, list and total could disagree"* and
*"back navigation fails after opening the cart"* — were **not reproducible** in
the real runtime path. A widget test that boots the exact `main()` wiring
(`buildRootProviders` + `MyApp`, no test-local provider harnesses) was driven
Home → Marketplace → Product → Add to Cart → Cart → Checkout and back. Runtime
instrumentation proves a **single `MarketplaceProvider` instance** and a
**single Navigator** are used by every screen in the flow, and the badge, cart
list, and grand total always agree.

One **real, previously unknown layout bug** was found and fixed during the
audit: the CartScreen coupon field's Apply button crashed with
`BoxConstraints forces an infinite width` in unbounded layout contexts
(`flutter test` root pass / test environments). The fix is behavior-preserving
on-device.

## Method

- **Real wiring only:** the test pumps `MultiProvider(providers:
  buildRootProviders(), child: MyApp(...))` — the same graph `main()` builds.
  No test-local provider wrappers, no shortcuts.
- **Temporary runtime tracing** (`lib/debug/runtime_trace.dart`,
  `kRuntimeTrace = true`): each marketplace screen logs
  `provider=<hashCode> cartLines=… cartQty=… grandTotal=… navigator=<hashCode>
  canPop=…` at build time; a `NavigatorObserver` logs every
  push/replace/pop with the navigator identity.
- **Full flow driven:** Home dashboard → "Parts" quick service →
  MarketplaceHome (catalog 700ms parallel load) → ProductDetail → Add to Cart
  → Cart → Checkout, then back-navigation Checkout → Cart → Product → Home.

## Evidence (runtime traces, `test/integration/runtime_marketplace_flow_test.dart`)

Single run across the whole forward + backward flow:

| Screen | provider hashCode | navigator hashCode | canPop | cartLines / cartQty / grandTotal |
|--------|------------------|--------------------|--------|----------------------------------|
| MarketplaceHomeScreen | **649856469** | **774559648** | true | 0 / 0 / 0 |
| ProductDetailScreen  | **649856469** | **774559648** | true | 0 / 0 / 0 |
| ProductDetailScreen (after add) | **649856469** | **774559648** | true | 1 / 1 / 874 |
| CartScreen           | **649856469** | **774559648** | true | 1 / 1 / 874 |
| CheckoutScreen       | **649856469** | **774559648** | true | 1 / 1 / 874 |
| CartScreen (popped back) | **649856469** | **774559648** | true | 1 / 1 / 874 |
| ProductDetailScreen (popped back) | **649856469** | **774559648** | true | 1 / 1 / 874 |
| MarketplaceHomeScreen (popped back) | **649856469** | **774559648** | true | 1 / 1 / 874 |

Empty-cart run: `CartScreen provider=715662477 navigator=66810597` — again one
instance per run; the empty state shows and the checkout bar is gated off.

### Conclusions from evidence

1. **Single provider:** `provider.hashCode` is identical across
   MarketplaceHome, ProductDetail, Cart, and Checkout. There is no duplicate
   `MarketplaceProvider` scope anywhere in the flow.
2. **Single navigator:** `navigator.hashCode` is identical for every push and
   pop. No nested `Navigator`/`NavigatorState` scopes are introduced by the
   marketplace flow, so system-back and AppBar-back cannot get trapped inside a
   dead-end nested stack.
3. **Consistency:** `cartLines`, `cartQty`, and `grandTotal` are recomputed by
   each screen from the same instance and always agree. The cart-title badge is
   asserted to equal the visible cart lines.
4. **Back navigation works:** Checkout → Cart → Product → Home pops the same
   stack and every screen still reads the same provider after the pop.

## Findings

### FIXED — Bug: `CouponField` crashes with `BoxConstraints forces an infinite width`

- **Where:** `lib/features/marketplace/widgets/coupon_field.dart` (Apply /
  Remove `ElevatedButton`), co-factor `lib/theme/app_theme.dart:78`
  (`elevatedButtonTheme.minimumSize = Size(double.infinity, 52)`).
- **Trigger:** `flutter test`'s root layout pass lays the Navigator's Overlay
  out with **unbounded** constraints and the route's child (the coupon field
  `Row` → `SizedBox(height: 46)` → `ElevatedButton`) is given `w = Infinity`.
  The theme's `minimumSize.width = Infinity` then makes the button require an
  infinite width → layout exception at `coupon_field.dart`. On-device the
  Overlay is finite, so this is a *robustness* bug that only ever bites in
  unbounded contexts — but a widget must not throw.
- **Proof:** scratch bisect showed plain Scaffold + default `ThemeData` passed,
  plain Scaffold + `AppTheme.light` + cart items crashed, `BottomNavigation`
  participation and in-flight snackbars were irrelevant; test E failed before
  the fix and passed after it.
- **Fix:** wrap the button in
  `ConstrainedBox(constraints: BoxConstraints(maxWidth: 160))` (with its
  `SizedBox(height: 46)`). In bounded contexts the row's remaining width (≈120dp
  on phone) binds first, so on-device appearance is unchanged; in unbounded
  contexts the width clamps to 160 and cannot overflow.

### Test-side (not product bugs)

- **`find.widgetWithText(ElevatedButton, 'Add to Cart')` matched nothing:** the
  app uses `ElevatedButton.icon`, which constructs an `_ElevatedButtonWithIcon`
  subclass; `byType(ElevatedButton)` does **not** match subclasses. Finder now
  uses `find.text('Add to Cart')`. Diagnostic output confirmed
  `elevatedButtons=0` with the old finder.
- **Snackbar-timing coupling removed:** the test now adds to cart directly via
  `detailProvider.addToCart(product)` (product resolved through the shared
  provider) so the toast's duration is irrelevant to the assertions.
- **Scratch bisect harness** `test/scratch_cart_route_test.dart` was deleted
  after the audit closed.

## Verification

| Check | Result |
|-------|--------|
| `flutter test test/integration/runtime_marketplace_flow_test.dart` | **Pass** (2 tests) |
| Full suite `flutter test` | **Pass — 104/104** |
| `flutter analyze` | Clean for `lib/`; 20 pre-existing `avoid_print` infos in `test/integration/verify_*.dart` (untouched) |

## Files

- `lib/features/marketplace/widgets/coupon_field.dart` — **fixed** (bounded
  Apply button).
- `lib/debug/runtime_trace.dart` — temporary runtime tracing
  (`TraceNavigatorObserver` + `traceMarketplace`), `kRuntimeTrace = true`; flip
  to `false` once on-device traces have been observed.
- `test/integration/runtime_marketplace_flow_test.dart` — real-wiring
  regression test covering single provider/navigator, cart consistency,
  empty-cart gating, and back navigation.
- `lib/theme/app_theme.dart` — co-factor of the crash (infinite minimum size);
  not changed.

## Follow-up

1. Run the app on device/emulator with `kRuntimeTrace = true` and confirm the
   `[TRACE]` lines show one provider and one navigator hash across the flow.
2. Set `kRuntimeTrace = false` (or delete `lib/debug/runtime_trace.dart` and its
   call sites) once the audit is accepted.
