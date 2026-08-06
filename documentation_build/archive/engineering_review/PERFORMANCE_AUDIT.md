# Performance Audit — Mecha Connect

> **Phase 0 · Complete Engineering Audit · 2026-08-05**
> Scope: widget rebuilds, provider rebuilds, image optimization, memory usage, navigation performance, lazy loading, asset loading.

## 1. Current State

- **App size:** ~233 Dart files, 50 screens, 18 image assets.
- **Runtime:** All data is in-memory mocks with simulated latency (700-900ms).
- **State:** ChangeNotifier + Provider; 5-tab `IndexedStack` keeps all tabs alive.
- **Assets:** `assets/` holds 18 images (no `@2x/@3x` resolution variants declared — uses `assets/` dir directly).

## 2. Strengths

| # | Finding | Detail |
|---|---|---|
| S1 | **`IndexedStack` preserves tab state** | All 5 tabs stay mounted — no rebuild on tab switch; state (scroll, loading) preserved |
| S2 | **Parallel data loading** | `MarketplaceProvider.load()` uses `(...).wait` for products/categories/brands/offers; `ProfileProvider.loadHome()` uses `Future.wait` — single round-trip |
| S3 | **`buildRootProviders()` is the single provider graph** | No duplicate provider instances; verified by integration test (single MarketplaceProvider hashCode across flow) |
| S4 | **`AnimatedBuilder` on splash** | Splash uses `Listenable.merge` + `AnimatedBuilder` — efficient repaint of 3 animations |
| S5 | **`CustomPainter` with `shouldRepaint=false`** | Static painters don't repaint — efficient |
| S6 | **Zero-latency repos in tests** | `_fastRepo()` avoids mock latency in test suites — fast CI |
| S7 | **`List.unmodifiable` copies** | Providers expose unmodifiable views — prevents accidental mutation from UI |
| S8 | **Cancellable timers** | `FuelProvider.startTracking` cancels `_trackingTimer` in `stopTracking()`/`dispose()` — no leaked periodic timers (verified by tests disposing trees) |
| S9 | **`const` constructors** | Most widgets use `const` — good build-time optimization |
| S10 | **Lazy load per tab** | Providers load their data on first tab access (`load()` guarded by `if (_state == initial)`) |

## 3. Weaknesses

| # | Finding | Severity | Detail |
|---|---|---|---|
| W1 | **No `Selector` usage** | P1 | All screens use `context.watch<Provider>()` — every `notifyListeners()` rebuilds the ENTIRE screen subtree. `Selector<T, R>` would limit rebuilds to changed slices. |
| W2 | **No `RepaintBoundary` on lists** | P2 | Long lists (products, orders, chat) have no repaint boundaries — scrolling repaints over scoped regions. |
| W3 | **No `ListView.builder` everywhere** | P2 | Some screens may construct full child lists; `product_grid`/`product_rail` use builders but orders feed needs verification. |
| W4 | **`ordersList` `notify()` rebuilds all consumers** | P1 | `orderStore.notify()` notifies ALL listeners (Orders tab + any widget listening) — no granular notification. |
| W5 | **Image assets without resolution variants** | P2 | `assets/` has no `@2x/@3x` variants — all densities load the same bitmap. |
| W6 | **No caching strategy** | P2 | No `cached_network_image`; Sprint 2 network images will need caching. |
| W7 | **Splash images are large** | P3 | `no_bg.png` (logo) sized via `screenHeight * 0.33` — no explicit resolution handling. |
| W8 | **`DevicePreview` overhead in debug** | P3 | Wraps the whole app in debug — adds layout override layer. Stripped in release (`kDebugMode`). |
| W9 | **No `const` on some providers' callbacks** | P3 | Minor; Provider only runs `create` once — acceptable. |
| W10 | **Geocoding calls have no debounce** | P2 | `searchLocations(query)` fires per keystroke (>=3 chars) with no debounce — N Nominatim calls while typing. |

## 4. Rebuild Analysis

| Screen | Watch scope | Risk |
|---|---|---|
| MarketplaceHomeScreen | `watch<MarketplaceProvider>` | Rebuilds on ANY provider notify (cart badge, filters, wishlist) |
| ChatScreen | `watch<AiProvider>` | Rebuilds on typing indicator, messages, pin state — could use Selector for message list |
| FuelBookingScreen | `watch<FuelProvider>` | Rebuilds on quantity, location, station, price |
| ProfileScreen | `watch<ProfileProvider>` | Rebuilds on any profile op flag |
| HomeDashboard | `watch<HomeProvider>` + `watch<LocationProvider>` | Two watches — rebuilds on either |

## 5. Risks

| # | Risk | Severity | Mitigation |
|---|---|---|---|
| R1 | Coarse-grained rebuilds scale poorly | P1 | Introduce `Selector` for hot screens (chat, marketplace grid, orders) in Sprint 3 |
| R2 | Order feed global notify | P1 | Granular `OrderProvider` with per-type notifications |
| R3 | Network image loading in Sprint 2 | P2 | Add `cached_network_image` + resolution-aware asset pipeline |
| R4 | Nominatim API abuse | P2 | Debounce search; add rate-aware backoff |

## 6. Technical Debt

| # | Debt | Priority | Effort |
|---|---|---|---|
| TD1 | No Selector-based granular rebuilds | P1 | 4 hr |
| TD2 | Global orderStore notify | P1 | 2 hr |
| TD3 | No image resolution variants | P2 | 2 hr |
| TD4 | No network-image caching | P2 | Sprint 2 |
| TD5 | No debounce on geocoding search | P2 | 30 min |

## 7. Recommendations

1. **P1 — Introduce `Selector`** on hot screens: ChatScreen (messages), MarketplaceHomeScreen (cart count), OrdersScreen (list).
2. **P1 — Replace global `orderStore.notify()`** with a typed `OrderProvider` that notifies selectively.
3. **P2 — Add `@2x/@3x` image variants** or configure resolution-aware asset loading.
4. **P2 — Add `cached_network_image`** in Sprint 2 when network images arrive.
5. **P2 — Debounce `searchLocations()`** with a `Timer` (300ms).
6. **P3 — Add `RepaintBoundary`** around long scrolling lists (chat bubbles, product grids).

## 8. Priority Summary

| Priority | Count | Items |
|---|---|---|
| P0 | 0 | — |
| P1 | 2 | W1, W4, R1, R2, TD1, TD2 |
| P2 | 4 | W2, W5, W6, W10, R3, R4, TD3, TD4, TD5 |
| P3 | 2 | W3, W7, W8, W9 |