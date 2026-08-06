# Sprint 1.8.2 — Marketplace QA & Runtime Stabilization (P0)

## What changed, in one sentence

A full manual-style QA pass over the Marketplace module surfaced and fixed eight runtime/navigation/provider-sync/layout defects — including the category-page `RenderSliver` crash and the Home "Parts" dead-end — with **layout and logic fixes only** (no redesign, no color/typography/spacing/animation changes), each locked by a new regression test and covered by a widened responsive sweep.

---

## 1. Bugs found and fixed

### 1.1 P0 — Category pages crashed: `RenderSliverPadding expected RenderSliver but received RenderErrorBox`

- **Root cause:** `CategoryScreen` passed a **box** widget — `ProductGrid`, which builds a `GridView.builder` — directly as the `sliver:` child of a `SliverPadding`.p
- **Why it happened:** `SliverPadding.sliver` must be a sliver (`RenderSliver`); a box child fails the layout assertion. The home screen wraps its grid in `SliverToBoxAdapter` and search wraps it in `SingleChildScrollView`, but the category screen placed the grid straight into the sliver list. Category was also the one browse screen the Sprint-1.8.1 overflow sweep did **not** cover, so the crash shipped silently.
- **File modified:** `lib/features/marketplace/screens/category_screen.dart`
- **Exact fix:** wrapped `ProductGrid` in `SliverToBoxAdapter` inside the existing `SliverPadding`.
- **Why it works:** `SliverToBoxAdapter` is the box→sliver bridge; the `shrinkWrap` grid lays out to its natural extent inside the scroll view. Visual layout is unchanged.
- **Regression test added:** *"every category page renders without a sliver crash"* (renders every `kMarketplaceCategories` entry with `takeException() == null`); `CategoryScreen` also added to the responsive sweep.

### 1.2 P0 — Home Quick Service "Parts" still said "Coming Soon"

- **Root cause:** the active home dashboard (`lib/features/home/screens/home_screen.dart`) `_handleQuickService` had cases only for Mechanic/Fuel/AI Diagnosis; `Parts` fell through to `default` → `_comingSoon('Parts service')`.
- **Why it happened:** Sprint 1.8 wired the *legacy* `lib/starting_screen/home.dart` Parts tile to `MarketplaceHomeScreen`, but the app actually runs `HomeDashboard` (used by `bottom_navigation.dart`), which was never updated.
- **File modified:** `lib/features/home/screens/home_screen.dart`
- **Exact fix:** added `case 'Parts':` → `Navigator.push(MarketplaceHomeScreen)` (plus its import).
- **Why it works:** the Parts quick service now opens the real Marketplace landing; no snackbar.
- **Regression test added:** *"Home Quick Service Parts opens the Marketplace, not a snackbar"* — pumps `HomeDashboard` with both providers, taps Parts, asserts `MarketplaceHomeScreen` + loaded `'Browse All Products'` and no "coming soon" snackbar.

### 1.3 P0 — Product Detail showed "Already in cart" but "Add to Cart"

- **Root cause:** `ProductDetailScreen._bottomBar` always rendered the local `_quantity` stepper and an **"Add to Cart"** button, even when `quantityInCart > 0` (whose only hint was the "Already in cart" sub-label). Tapping it silently **added more**, and the shown total was for the local stepper, not the cart.
- **Why it happened:** the bar's labels were hard-coded; only the sub-label watched the cart.
- **File modified:** `lib/features/marketplace/screens/product_detail_screen.dart`
- **Exact fix:** when `inCart`: price shows the in-cart quantity's total, the stepper is hidden, the button becomes **"Go to Cart"** → `openCart(context)` (enabled even if the product later goes out of stock). When not in cart, the UI is unchanged.
- **Why it works:** the bottom bar is now fully driven by `quantityInCart`, so it can never claim "already in cart" while offering "Add to Cart".
- **Regression test added:** *"product already in cart shows Go to Cart, never Add to Cart"* — plus a back-navigation assertion (Go to Cart → Cart → back → returns to the product), and an in-cart detail pump in the sweep.

### 1.4 P0 — Cart badge / body sync invariant

- **Root cause:** `addToCart` accepted any quantity; `addToCart(product, quantity: 0)` created a `CartItem` line with **quantity 0**. The badge (`cartCount` = Σ quantities) then disagreed with the body (which shows the line). No code path could make a *non-empty* cart render an *empty* body (both come from the same `_cart` on the single root provider), but the zero-quantity line was a real provider-consistency hole and could produce "body has item, badge says 0".
- **Why it happened:** no validation on the `quantity` parameter.
- **File modified:** `lib/features/marketplace/providers/marketplace_provider.dart`
- **Exact fix:** `addToCart` clamps `quantity` to `≥ 1` before merging/inserting.
- **Why it works:** every cart line always has positive quantity, so `cartCount == Σ quantity` and the `Cart (N)` title always equals the number of lines the body renders.
- **Regression tests added:** *"addToCart never creates a zero or negative quantity line"* and *"cart title badge always matches the visible cart lines"* (add → inc → dec → second product → remove → clear, asserting title/badge vs `CartItemTile` count at every step).

### 1.5 — Unhandled async exceptions when a parallel fetch fails

- **Root cause:** `load()`/`refresh()` created four futures and `await`ed them **sequentially**. If the first threw, the other three were abandoned with pending errors → unhandled async exceptions (red console noise in prod; test failures).
- **Why it happened:** sequential awaits of already-started futures leak sibling errors.
- **File modified:** `lib/features/marketplace/providers/marketplace_provider.dart`
- **Exact fix:** await the four fetches together via a record `.wait` (`(products, categories, brands, offers) = await (...).wait`) — subscribes to all four and surfaces the first error into the existing `try/catch`.
- **Why it works:** no future is abandoned; a partial failure cleanly enters the error/retry path.
- **Regression tests added:** *"failed load lands in the error state and retry recovers"*.

### 1.6 — Failed pull-to-refresh tore the page down

- **Root cause:** `refresh()` set `_state = error` on any failure — flipping a fully-loaded page to the full-page error view and losing the content the user could see.
- **Why it happened:** refresh re-used the load failure handling without distinguishing "already showing content".
- **File modified:** `lib/features/marketplace/providers/marketplace_provider.dart`
- **Exact fix:** on refresh failure the provider stays in `ready` when it was already ready (the error message is still recorded); it only enters `error` if it wasn't showing content.
- **Why it works:** a failed refresh never blanks the screen (mirrors "never lose state unexpectedly"); the Retry path is unchanged.
- **Regression test added:** *"failed refresh keeps the loaded catalog and the ready state"* (via an injected `_FlakyRepository`).

### 1.7 — Tablet hero banner overflow (2px at 768dp)

- **Root cause:** `hero_banner.dart` sized the tablet carousel to 170dp while mobile used 176dp; the two-line title + two-line subtitle + code badge needed ~132dp and only got 130dp under the test font.
- **File modified:** `lib/features/marketplace/widgets/hero_banner.dart`
- **Exact fix:** tablet height 170 → 176 (same value mobile already used to guarantee no clipping).
- **Why it works:** content area (176 − 40 padding) now exceeds the tallest content stack.
- **Regression test added:** covered by the sweep, which now includes 600/768dp.

### 1.8 — Tablet product-grid overflow (6.3px)

- **Root cause:** `ProductGrid` used `childAspectRatio: 0.8` (variable, too-short cells) for every width ≥ 600 while mobile already used a fixed 250px `mainAxisExtent`; tablet cells could not fit the card column.
- **File modified:** `lib/features/marketplace/widgets/product_grid.dart`
- **Exact fix:** the fixed `mainAxisExtent: 250` now applies below desktop (`width < 1024`); the aspect-ratio path is used only at ≥1024 where cells are tall enough.
- **Why it works:** tablet cards get the same guaranteed 250px height as mobile.
- **Regression test added:** covered by the sweep at 600/768dp in both themes.

---

## 2. Manual QA walkthrough mapping

| Flow | Walked path | Verification |
|---|---|---|
| 1 | Home → Parts → Marketplace → Category → Product → Add to Cart → Cart → Checkout → Order Success → Orders → back | e2e test + *Parts shortcut* + *category* + *cart back* tests; `ordersList` seeded with `MKP-…` entry |
| 2 | Marketplace → Search → Product → Wishlist → Cart → back | e2e search→product, wishlist sweep + provider tests, cart-back test |
| 3 | Every category → every product → back | *every category page renders without a sliver crash* |
| 4 | Offers → product/category → back | hero-banner `_openOffer` → `openCategory`/`openSearch`; covered by category/search tests |
| 5 | Wishlist → Move to Cart → Checkout | provider `moveWishlistToCart` tests + checkout sweep |

Navigation matrix: AppBar/Android back works on every route (all standard pushes); Cart→Back returns to Marketplace, Product→Cart→Back returns to Product (tested); Checkout is `pushReplacement`d by Order Success so no stale price/duplicate route remains below; Order Success offers "Continue Shopping" and "Back to Home" (`popUntil isFirst`) — no dead ends, no blank screens after popping.

Provider sync: single root `MarketplaceProvider`; every cart/wishlist/coupon mutation notifies; the new tests prove title badge, body lines and `provider.cart` can never disagree, and that refresh/load failures never strand the UI.

Responsive: the overflow sweep now runs **home, search, product detail (plain + in-cart), category, cart, checkout, wishlist, order success** at **320/360/390/412/600/768dp × light/dark** with `takeException() == null`.

## 3. Files modified

| File | Change |
|---|---|
| `lib/features/marketplace/screens/category_screen.dart` | grid wrapped in `SliverToBoxAdapter` (RenderSliver crash fix) |
| `lib/features/home/screens/home_screen.dart` | `Parts` quick service opens `MarketplaceHomeScreen` |
| `lib/features/marketplace/screens/product_detail_screen.dart` | in-cart bottom bar → price = cart qty, no stepper, "Go to Cart" |
| `lib/features/marketplace/providers/marketplace_provider.dart` | `addToCart` qty clamp; record `.wait` fetches; failed refresh preserves `ready` |
| `lib/features/marketplace/widgets/hero_banner.dart` | tablet height 170 → 176 |
| `lib/features/marketplace/widgets/product_grid.dart` | fixed 250px `mainAxisExtent` below desktop |
| `test/marketplace_module_test.dart` | `QA & runtime stabilization (Sprint 1.8.2)` group (8 tests) + `_FlakyRepository` + widened sweep |

## 4. Verification

- `flutter analyze --no-pub` — **0 errors, 0 warnings** (the 20 `info` items are the pre-existing `avoid_print` in `test/integration/*`, untouched).
- `flutter test` — **97/97 passing** (marketplace suite now **39/39**, +8 over Sprint 1.8.1).

## 5. Completion criteria

- Zero runtime crashes — category RenderSliver crash fixed & sweep-locked; no RenderFlex overflows at any swept width incl. tablet.
- Zero blank screens / dead ends — checkout `pushReplacement`, Order-Success exits, cart back-paths all tested.
- Zero provider sync bugs — badge/body invariant + qty clamp tested across the full cart lifecycle; failed load/refresh recovery tested.
- Home shortcut opens Marketplace — HomeDashboard Parts → `MarketplaceHomeScreen` tested.
- Product Detail always reflects cart state — "Go to Cart" replaces "Add to Cart" when already in cart, tested.
