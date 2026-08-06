# Module Knowledge: Overview & Cross-Module Dependencies

> Phase 5 · Map of modules and their shared seams.

## Module Matrix
| Module | Tab / Entry | Provider (root#) | Screens | Models | Widgets | Tests |
|---|---|---|---|---|---|---|
| ai | Tab 3 | AiProvider (#6) | 5 | 7 | 10 | 25 |
| auth | pre-shell | AuthProvider (#3) | 3 | 0 | 1 | — |
| home | Tab 0 + Services tab | HomeProvider (#4) | 2 | 1 (9 cls) | 15 | 3 |
| marketplace | Services tab | MarketplaceProvider (#9) | 8 | 8 (13 cls) | 19 | 43 |
| mechanic | Services tab | MechanicProvider (#5) | 11 | 3 (6 cls) | 8 | 10 |
| fuel_delivery | Services tab | FuelProvider (#8) | 8 | 11 | 13 | 37 |
| profile | Tab 4 | ProfileProvider (#7) | 12 | 9 (13 cls) | 13 | 30 |
| vehicle_location | shared service | LocationProvider (#2) | — | — | — | 8 |
| orders (tab) | Tab 2 | orderStore/ordersList | 1 | — | — | (in integration 2) |

## Cross-Module Edges (frozen)
- mechanic `VehicleFormScreen` → ai `DiagnosisService` (mock, no HTTP).
- ai action buttons → mechanic/fuel/marketplace home screens (`features/ai/navigation.dart`).
- marketplace `placeOrder` → `orderStore.addMarketplaceOrder` → Orders tab (tab 2).
- profile `fetchOrders` → shared `ordersList`.
- fuel/mechanic live tracking → `LocationProvider` (map centering, nearest ordering).
- home `HomeSearchScreen` ↔ marketplace search surface.

## Shared Singletons
- `orderStore` (`OrderStore extends ChangeNotifier`) + `ordersList` — `lib/parts/order_data.dart`.
- `ThemeProvider` — above MaterialApp (SharedPreferences `theme_mode`).

## Design Constraints (apply to every module)
- Repository is the ONLY data source; screens never call HTTP.
- Simulated latency + `failForFirstCalls` failure injection per module.
- Default-first ordering for vehicles/addresses.
- Frozen ID schemes (see `04_api/id_schemes.md` → `04_api/endpoint_catalog.md` §2).
