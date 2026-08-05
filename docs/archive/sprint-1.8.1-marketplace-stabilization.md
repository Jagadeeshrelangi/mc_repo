# Sprint 1.8.1 — Marketplace Stabilization

## What changed, in one sentence

Sprint 1.8's Marketplace module got a runtime-stabilization pass: four runtime bugs (pull-to-refresh skeleton flash, search query leaking back into the home grid, cart row striking through the sale price instead of the MRP, checkout duplicating the pincode) and three 320dp overflow rows were fixed with **layout-only, no-design-change** edits, and the whole set is now locked down by a new runtime-verification test group.

No UI redesign: colors, spacing, typography, animations and the design system are untouched. All fixes respect the pre-existing design-system constraints.

---

## 1. Bugs found and fixed

| # | Bug | Root cause | Fix |
|---|---|---|---|
| 1 | Pull-to-refresh blanked Home to the skeleton | `MarketplaceProvider.refresh()` simply called `load()`, which sets `_state = loading`, so every refresh tore down the ready page to the `ShimmerBox` state (and a second latency cycle) | Rewrote `refresh()` to re-fetch products/categories/brands/offers directly and assign them, never flipping out of `ready` (mirrors the Fuel refresh pattern). Errors land in `error` with `'Could not refresh the marketplace. Pull to retry.'` |
| 2 | Closing Search left the browse grid filtered | `_SearchScreenState.dispose` reset `searchQuery` by `context.read<MarketplaceProvider>()` — Home keeps its search local (never writes `searchQuery`), so after leaving Search the provider's stale query silently filtered the Home grid | Moved the reset to `openSearch()` in `navigation.dart`: `Navigator.push(...).then((_) => provider.setSearchQuery(''))`. The dispose-time `context.read` was also crash-prone (see §3) |
| 3 | Cart row struck through the sale price | `CartItemTile` built the strikethrough from `item.product.price` — the price the user would actually pay | Strikethrough now renders `'MRP ${formatINR(item.product.mrp)}'` |
| 4 | Checkout duplicated the pincode | The address card appended `address!.pincode` after `fullAddress`, which already ends with `- $pincode` | Removed the duplicate line in `checkout_screen.dart` |
| 5 | Sticky bottom bar overflowed 49px at 320dp | Theme `elevatedButtonTheme` `minimumSize: Size(double.infinity, 52)` + `AppSpacing.xl` horizontal padding makes the full-width "Add to Cart" button unshrinkable; price + `QuantityStepper` + button could not share one Row | Restacked `_bottomBar` into a `Column`: `Row(price/stock + stepper)` then a full-width 48dp `ElevatedButton.icon` below it |
| 6 | Detail rating row overflowed 54px at 320dp | `Row(RatingStars, Text('4.6 (890 reviews)'))` — the reviews label could not shrink | Wrapped the reviews text in `Flexible` + `maxLines: 1` + `TextOverflow.ellipsis` |
| 7 | Cart tile price row overflowed 60px at 320dp | Price column + `QuantityStepper` need ~164px but only get ~136px in the tile at 320dp (real overflow, not just a test artifact) | Made the row a `Wrap(spacing: 8, runSpacing: 6)` — stepper drops to its own line only when it doesn't fit |
| 8 | Wishlist action row overflowed 50px at 320dp | `OutlinedButton('Move to Cart')` + `IconButton` could not share one Row in the tile column | Wrapped them in `Wrap(spacing: 4, runSpacing: 4)` |

---

## 2. Files modified

| File | Change |
|---|---|
| `lib/features/marketplace/providers/marketplace_provider.dart` | `refresh()` rewritten — no loading-state flash, keeps `ready`/`error` |
| `lib/features/marketplace/navigation.dart` | `openSearch()` clears `searchQuery` after the route pops |
| `lib/features/marketplace/screens/search_screen.dart` | `dispose` reduced to controller/tabs disposal (the provider reset was moved out) |
| `lib/features/marketplace/widgets/cart_item_tile.dart` | MRP strikethrough; price row → `Wrap` |
| `lib/features/marketplace/screens/checkout_screen.dart` | Removed duplicated pincode line |
| `lib/features/marketplace/screens/product_detail_screen.dart` | Sticky bottom bar restacked to a Column + full-width button; rating label `Flexible` + ellipsis |
| `lib/features/marketplace/screens/wishlist_screen.dart` | Action row → `Wrap` |
| `test/marketplace_module_test.dart` | New `Runtime stabilization (Sprint 1.8.1)` group (4 tests) + `_wrapThemed` helper; `ProductDetailScreen` import |

---

## 3. Two crashes avoided while fixing the search reset

The first fix attempt reset `searchQuery` inside `_SearchScreenState.dispose` via `context.read<MarketplaceProvider>()`. That produced two distinct widget-lifecycle crashes:

1. `Looking up a deactivated widget's ancestor is unsafe` — resolving the provider through a deactivated element's context during unmount.
2. `setState() or markNeedsBuild() called when widget tree was locked` — `setSearchQuery` → `notifyListeners` fired from inside `StatefulElement.unmount`.

Both are avoided by resetting **after the route future completes** (`.then` on the `Navigator.push` in `navigation.dart`), with the provider read before the push. This also matches the semantic: leaving Search must leave no hidden filters; Home's own search never writes the provider query.

---

## 4. Why the 320dp overflows are "real", and the fix rule

The app bundles no fonts (`pubspec` `fonts:` section is commented out; no `.ttf` under `assets/`), so widget tests render with the Ahem font, where every glyph is ~`fontSize` wide — roughly 2× a real proportional font. That makes the width sweep a worst-case stress test, but it also produced one true-positive (cart tile price row, #7, which overflows even with real fonts at 320dp) alongside artifacts. The rule applied to every fix:

- **Layout/flow fixes only** (stack the row into a Column, let a stray control `Wrap`, or `Flexible` + ellipsis a label) — never color/spacing/typography/animation changes.
- Verify with the sweep in both themes across 320/360/412dp; a pass under the Ahem worst case guarantees a pass on device.

---

## 5. Runtime verification added

New group in `test/marketplace_module_test.dart` — `Runtime stabilization (Sprint 1.8.1)`:

- **Pull-to-refresh keeps the home page** — trigger `refresh()` mid-test and assert the `ShimmerBox` never appears and state stays `ready`.
- **Closing search resets the browse grid** — set a query, close Search, assert `searchQuery` is empty and `visibleProducts` is back to full.
- **End-to-end: home → search → product → cart → checkout → success** — full user journey including the address sheet form; asserts the Order Success screen, an emptied cart, and an `'MKP-...'` order id registered in the Orders store. (Navigates back from the product detail via `Navigator.pop`, because the SliverAppBar `BackButton` is offstage to default finders.)
- **All screens render without overflow at 320/360/412dp × light/dark** — sweeps home, search, product detail, cart, checkout, wishlist and order success in both themes at three widths, asserting `tester.takeException()` stays null.

Test helpers: `_preload` (provider load + double 800ms pump), `_navSettle` (pump + 350ms pump), `_wrapThemed(child, provider, {dark})` (MultiProvider + explicit-brightness `ThemeData`). Note: `placeOrder`'s 700ms mock latency must be advanced with `tester.pump` (fake time), not awaited directly.

## 6. Verification results

- `flutter analyze --no-pub` — **0 errors, 0 warnings** (the 20 `info` items are the pre-existing `avoid_print` in `test/integration/*`, untouched).
- `flutter test` — **89/89 passing** (85 pre-existing + 4 new stabilization tests). Marketplace suite: **31/31**.
