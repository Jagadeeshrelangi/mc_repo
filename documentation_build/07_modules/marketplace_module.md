# Module Knowledge: Marketplace (`lib/features/marketplace/`)

> Phase 5 · Entry via Services tab. Source: FRONTEND_ARCHITECTURE §5.2, API_CONTRACT §5.

## Purpose
Spare-parts catalog, cart, wishlist, checkout, order success; writes the Orders tab.

## Inventory
| Layer | Items |
|---|---|
| Models (8 files, 13 classes) | `CartItem`, `WishlistItem`, `PriceSummary`, `Coupon`, `Offer`, `OrderItem`, `CheckoutAddress`, `MarketplaceOrder`, `Product`, `ProductSpecification`, `Brand`, `Category`, `Review` |
| Provider | `MarketplaceProvider` (root graph #9) |
| Repositories | `MarketplaceRepository` (700ms latency) |
| Services | `CartService`, `SelectService` |
| Screens (8) | `MarketplaceHomeScreen`, `ProductDetailScreen`, `CategoryScreen`, `SearchScreen`, `CartScreen`, `WishlistScreen`, `CheckoutScreen`, `OrderSuccessScreen` |
| Widgets (19) | product card, category card, quantity stepper, price summary, order card, etc. |
| Navigation | `navigation.dart`: `/marketplace`, `/marketplace/product|category|search|cart|wishlist` |

## Key Behavior
- Seed catalog: 40 products (incl. `p-out-of-stock`), 10 categories, 15 brands, 3 offers, 3 coupons.
- Product flags: featured / best-seller / trending / flash-deal / recommended.
- `createOrder` → `List<MarketplaceOrder>` (`MKP-<year>-<0000>`); `placeOrder` also writes
  Orders tab via `addMarketplaceOrder` + `orderStore.notify()`.
- `ProductCard` uses `context.read` + `context.select` (rebuilds only on wishlist change).
- A11y: 44px wishlist/cart touch targets + tooltips; quantity stepper `Semantics`.
- Conditional back button on Marketplace home (`Navigator.canPop` + `maybePop`).

## Failure Paths
`MarketplaceNetworkException` retry; out-of-stock buy disabled; empty cart/wishlist states.

## Tests
`test/marketplace_module_test.dart` — 43 tests.

## Backend Relation (Sprint 2)
`categories`, `brands`, `products` (+ specs/vehicle types/compatibility/reviews), `offers`, `coupons`
(server-validated), `orders` + `order_items` + `order_entries`.
