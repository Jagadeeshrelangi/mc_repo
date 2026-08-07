# Module Knowledge: Home (`frontend/lib/features/home/`)

> Phase 5 · Tab 0 + Services tab (HomeDashboard / ServiceSelectionScreen in `starting_screen/`).
> Source: Architecture §5.7, API §2.

## Purpose
Dashboard aggregate (`HomeData`): quick services, nearby services, marketplace
items, activities, offers. Entry point for the 5-tab shell.

## Inventory
| Layer | Items |
|---|---|
| Models (1 file, 9 classes) | `HomeData` aggregate + `UserProfile`, `LocationInfo`, `VehicleInfo`, `QuickService`, `NearbyService`, `MarketplaceItem`, `ActivityItem`, `OfferInfo` |
| Provider | `HomeProvider` (root graph #4) |
| Repositories | `HomeRepository` (800ms latency) |
| Services | none |
| Screens (2) | `HomeScreen` (`home_screen.dart`), `HomeSearchScreen` |
| Widgets (15) | service cards, activity items, location header, search bar, offer cards, etc. |

## Key Behavior
- `fetchHomeData()` returns the aggregate; loading skeleton → loaded cards → empty state.
- Services tab (`ServiceSelectionScreen`) exposes `endDrawer` (ProfileDrawer) and
  "Explore Services" affordance that switches to tab 1.
- Service cards push: SOS/Quick "Breakdown" → VehicleFormPage (mechanic),
  "Fuel" → FuelHomeScreen, Marketplace entry → MarketplaceHomeScreen, search → HomeSearchScreen.
- A11y: search bar + SOS card wrapped in `Semantics`.

## Failure Paths
`HomeNetworkException` retry; empty dashboard illustration.

## Tests
`test/home_dashboard_test.dart` — 3 tests (aggregate + search + services grid).

## Backend Relation (Sprint 2)
`HomeData` ↔ assembled from users/vehicles/orders/offers; quick services from
`mechanic_categories`/`fuel_stations`; single `GET /api/v1/home` target.
