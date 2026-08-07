# State Management — Mecha Connect

> Frozen state architecture at RC1 (Frontend Lock Candidate).
> Source: `frontend/lib/app_wiring.dart`, `frontend/lib/parts/order_data.dart`.

## 1. Model

- **`ChangeNotifier` + `Provider`** (Provider 6.1.5) for all stateful modules.
- **One provider graph** — `buildRootProviders()` in `frontend/lib/app_wiring.dart` is
  the single source of truth, used verbatim by the runtime regression test.
- **`MultiProvider`** wraps `MyApp` in `frontend/lib/main.dart`.

## 2. What Stays Where

| Concern | Mechanism |
|---|---|
| Screen state | `ChangeNotifier` providers (one per module) |
| Cross-tab feed | `orderStore` (`OrderStore extends ChangeNotifier`) + `ordersList` singleton (`frontend/lib/parts/order_data.dart`) |
| Theme mode | `ThemeProvider`, persisted to `SharedPreferences` key `theme_mode` |
| Login state | `is_logged_in` in `SharedPreferences`; read by splash routing |
| Notification settings | `NotificationSettingsStore` (SharedPreferences prod / in-memory tests) |
| Tab liveness | `IndexedStack` keeps all 5 tabs mounted and stateful |

## 3. Why `orderStore` Is a Singleton

The Orders tab (tab 2) stays alive across tab switches and must observe writes
from Marketplace (`addMarketplaceOrder()`), Fuel, Mechanic, and AI. A small
external `ChangeNotifier` (`OrderStore`) is shared by the shell and the
Marketplace provider; Profile order history reads the same `ordersList` so
every surface shows one feed.

## 4. Narrow Rebuilds

Prefer `context.read` + `context.select` (e.g. `ProductCard` wishlist state
rebuilds only when the wishlist changes). Providers expose fine-grained
notifications where the UI benefits.

## 5. Async & Failure Handling

Repositories simulate latency and accept `failForFirstCalls` for deterministic
failure injection. Providers surface typed exceptions (e.g.
`AiNetworkException`) with user-facing `message` so loading, empty, and
error/retry states are real UI paths at RC1.

## 6. Rules (frozen)

1. Screens never call HTTP; they read providers only.
2. Do not add a second wiring path — the graph in `app_wiring.dart` is canonical.
3. Cross-module state goes through the shared singletons, not ad-hoc globals.
4. State changes are reactive via `notifyListeners`; UI does not poll.
