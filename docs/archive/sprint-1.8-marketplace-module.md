# Sprint 1.8 — Marketplace Module (Parts Store)

## What changed, in one sentence

A complete, mock-data-driven **Marketplace module** (browse/category/search/product detail/cart/checkout/wishlist/orders) was built as a self-contained feature under `lib/features/marketplace/`, following the same production-grade conventions as Home (1.5), Mechanic (1.6) and Fuel (1.7) — with `MarketplaceProvider` as the single source of truth, a 700ms-latency mock repository as the future Sprint-2 API swap point, and checkout orders registered into the existing Orders tab through a single funnel.

No UI redesign: the module reuses the existing design system (`AppColors`, Space Grotesk/Inter, `AppSpacing`, `AppResponsive`, theme helpers, dark mode) and integrates with the existing `Orderscreen` without changing its architecture.

---

## 1. Module architecture

```
lib/features/marketplace/
 ├─ marketplace.dart                     feature barrel (models, navigation, provider,
 │                                       repository, screens, services, utils, widgets)
 ├─ navigation.dart                      route constants + fade-through push helpers
 ├─ models/
 │   ├─ product.dart  review.dart  offer.dart  coupon.dart
 │   ├─ cart.dart     order_models.dart     (CartItem, WishlistItem, PriceSummary,
 │   │                                     OrderItem, CheckoutAddress, MarketplaceOrder,
 │   │                                     VehicleType)
 │   └─ mock_data.dart                   10 categories · 15 brands · 40+ products ·
 │                                       3 offers · 3 coupons
 ├─ services/cart_service.dart           GST 18%, delivery ₹49 free ≥ ₹999,
 │                                       MECHA10/MECHA20/FREESHIP coupons → PriceSummary
 ├─ utils/currency_formatter.dart        Indian digit grouping (formatINR)
 ├─ repositories/marketplace_repository.dart   700ms Future.delayed mock API; createOrder
 │                                       returns one MarketplaceOrder per cart line
 ├─ providers/marketplace_provider.dart  single source of truth (see §2)
 ├─ screens/                             home · category · search · product detail ·
 │                                       cart · checkout · order success · wishlist
 └─ widgets/                             shimmer/error/empty · rating stars ·
                                         product image/card/grid/rail · category rail ·
                                         hero banner · filter chips/sheet · sort menu ·
                                         qty stepper · cart tile · coupon field ·
                                         price summary · address sheet · section header
```

Integration points with the existing app:

- `lib/main.dart` — `MarketplaceProvider` registered via `ChangeNotifierProvider.value` alongside the other feature providers.
- `lib/starting_screen/home.dart` — the Parts quick-service now opens `MarketplaceHomeScreen` (previously a "coming soon" snackbar).
- `lib/parts/order_data.dart` — the **only** cross-feature write surface: `addMarketplaceOrder(...)` inserts a `parts`-typed order into the global `ordersList` at index 0; `resetOrdersList()` is the test helper. `OrderType` is reused from `lib/widgets/order_card.dart`.
- `test/marketplace_module_test.dart` — 26 new tests (unit + widget), following the `_wrap`/double-`pump(800ms)` convention from the fuel suite.

---

## 2. State ownership

`MarketplaceProvider` mirrors the exact provider model used by Fuel 1.7.4: **UI mirrors the provider, never the reverse; every write funnels through a provider method.**

```
                   ┌──────────────────────────────────────────────────┐
                   │           MarketplaceProvider                     │
                   │  (single source of truth for the whole module)   │
                   │                                                  │
                   │  state · catalog · searchQuery · filters · sort  │
                   │  visibleProducts · cart · wishlist ·             │
                   │  recentlyViewed · offers · coupons ·             │
                   │  priceSummary · checkoutAddress · checkoutPayment│
                   │  lastOrderIds · lastOrderTotal · cartCount       │
                   └──────────────▲───────────────────────────────────┘
                                  │  injected
                    ┌─────────────┴──────────────┐
                    │   MarketplaceRepository    │  (700ms mock; Sprint-2 swap point)
                    │   fetchCatalog / getCoupons│
                    │   createOrder              │
                    └────────────────────────────┘

          reads via context.watch         writes (all funnelled)
              ┌───────────┐   ┌────────────────────────────────────┐
              │ 8 screens │   │ addToCart · setQuantity ·          │
              │ 20 widgets│   │ toggleWishlist · moveWishlistToCart│
              └───────────┘   │ applyCoupon · removeCoupon ·       │
                              │ setSearchQuery · setBrands ·       │
                              │ setVehicleTypes · setInStockOnly · │
                              │ setPriceRange · setMinRating ·     │
                              │ setSortOption · placeOrder ·       │
                              │ openProduct · resetFilters · ...   │
                              └────────────────────────────────────┘
```

- `placeOrder` is the **only** path that creates orders: it asks the repository for one `MarketplaceOrder` per cart line, writes each through `addMarketplaceOrder(...)` into the Orders store, and only then clears the cart and the applied coupon. Orders tab architecture is untouched — marketplace entries simply register as `OrderType.parts.name`.
- Cart math (GST 18%, delivery threshold, capped/percent/free-delivery coupons) lives entirely in `CartService` and is exposed through `priceSummary` / `priceSummaryForProduct`; nothing in the UI recomputes prices.
- Checkout address/payment are held on the provider (`checkoutAddress`, `checkoutPayment`) so Order Success can render the confirmation from the same state that placed the order.

---

## 3. Files created

| Area | Files |
|---|---|
| Models | `models/product.dart`, `review.dart`, `offer.dart`, `coupon.dart`, `cart.dart`, `order_models.dart`, `mock_data.dart`, `models.dart` |
| Services / utils | `services/cart_service.dart`, `utils/currency_formatter.dart` |
| Repository | `repositories/marketplace_repository.dart` |
| Provider | `providers/marketplace_provider.dart` |
| Widgets | `marketplace_shimmer.dart`, `marketplace_error_view.dart`, `marketplace_empty_state.dart`, `rating_stars.dart`, `product_image.dart`, `product_card.dart`, `product_grid.dart`, `section_header.dart`, `category_rail.dart`, `hero_banner.dart`, `product_rail.dart`, `filter_chips.dart`, `filter_sheet.dart`, `quantity_stepper.dart`, `cart_item_tile.dart`, `coupon_field.dart`, `price_summary_card.dart`, `coming_soon.dart`, `sort_menu.dart`, `address_sheet.dart`, `widgets.dart` |
| Screens | `marketplace_home_screen.dart`, `category_screen.dart`, `search_screen.dart`, `product_detail_screen.dart`, `cart_screen.dart`, `checkout_screen.dart`, `order_success_screen.dart`, `wishlist_screen.dart`, `screens.dart` |
| Feature plumbing | `navigation.dart`, `marketplace.dart` |

## 4. Files modified

| File | Change |
|---|---|
| `lib/main.dart` | `MarketplaceProvider` registered via `ChangeNotifierProvider.value` |
| `lib/starting_screen/home.dart` | Parts quick-service now opens `MarketplaceHomeScreen` |
| `lib/parts/order_data.dart` | `addMarketplaceOrder(...)` (index-0 insert, returns order id) + `resetOrdersList()` test helper |
| `lib/features/marketplace/models/mock_data.dart` | fixed two pre-existing tyre-size quote typos (`'90/90-17')`, `'90/100-10')`) |

---

## 5. Runtime verification

- `flutter analyze --no-pub` — **0 errors, 0 warnings** (the 20 `info` items are the pre-existing `avoid_print` in `test/integration/*`, untouched).
- `flutter test` — **84/84 passing** (58 pre-existing + 26 marketplace). Marketplace suite (`test/marketplace_module_test.dart`): **26/26** including:
  - Unit: `formatINR` Indian grouping; `CartService` empty / GST+delivery / free-threshold / capped-percent / free-delivery / flat-coupon; provider catalog load, search filter, composed filters (brand+price+in-stock+rating+SUV), sort ordering (monotonic price/rating), cart merge+stock-clamp, coupon min-order gating, wishlist toggle/remove/move, recently-viewed cap, `placeOrder`→Orders-store, repository one-order-per-line.
  - Widget: home skeleton→full-page, search-entry navigation, live search filtering, product-detail add-to-cart + snackbar, empty cart, full checkout flow ending in an Orders-tab registration, wishlist move-to-cart.
  - Responsive: home page renders with **zero overflow at 320/360/412dp**.
- Responsive fixes landed during verification (all pre-existing design-system constraints respected): mobile browse grid uses a fixed 250px `mainAxisExtent` instead of the 0.68 aspect ratio (which produced a 23px card-height overflow at 320dp); the search-bar hint ellipsizes via `Expanded`; the hero banner mobile height is 176 so the two-line title + subtitle + CTA never clip at narrow widths.

---

## 6. Why the module can't drift from the app

1. **One writer for orders.** `placeOrder` (provider) → `addMarketplaceOrder` (Orders store) is the single funnel; the Orders tab is a passive reader of `ordersList`. The marketplace can never inject an order the Orders tab can't render, because it reuses the existing `OrderType.parts` + `OrderItem` shape.
2. **One store per concern.** Catalog, filters, cart, wishlist, coupon and checkout state live only on `MarketplaceProvider`; screens and widgets are `context.watch` readers. The "move wishlist to cart" and "coupon recompute" tests prove cross-widget consistency comes from the provider, not from duplicated copies.
3. **Repository is the seam.** All simulated latency and "API" shape is behind `MarketplaceRepository`; Sprint 2 replaces it with real HTTP without touching providers or screens.
4. **Cart math is centralized.** `CartService` owns GST/delivery/coupon rules; both the cart screen and the checkout screen render the same `PriceSummary` computed once on the provider, so the cart total and the order total can never disagree.
