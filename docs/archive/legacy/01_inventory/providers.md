# Providers Inventory — Mecha Connect

> Phase 1 · Class names captured by repo scan (grep `class *Provider`)

## 1. Root Graph (`lib/app_wiring.dart` → `buildRootProviders()`)

| Provider | File | Injected at root? |
|---|---|---|
| `LocationProvider` | `lib/services/location_provider.dart` | Yes |
| `FuelProvider` | `lib/features/fuel_delivery/providers/fuel_provider.dart` | Yes (`location:` dep) |
| `MarketplaceProvider` | `lib/features/marketplace/providers/marketplace_provider.dart` | Yes |
| `ProfileProvider` | `lib/features/profile/providers/profile_provider.dart` | Yes |
| `AuthProvider` | `lib/features/auth/providers/auth_provider.dart` | Module-local (auth flow) |
| `HomeProvider` | `lib/features/home/providers/home_provider.dart` | Module-local (home tab) |
| `MechanicProvider` | `lib/features/mechanic/providers/mechanic_provider.dart` | Module-local (mechanic tab) |
| `AiProvider` | `lib/features/ai/providers/ai_provider.dart` | Module-local (ai tab) |
| `ThemeProvider` | `lib/theme/theme_provider.dart` | Above MaterialApp (own scope) |

> Verified: `buildRootProviders()` returns exactly 4 root providers (Location, Fuel, Marketplace, Profile);
> module providers are provided locally within their tab/screen scopes. The runtime integration test
> exercises the exact production root graph.

## 2. Per-Module Provider Summary

| Provider | Backing repository/service | Consumed by |
|---|---|---|
| `AuthProvider` | `AuthRepository` | Auth screens, profile session guard |
| `HomeProvider` | `HomeRepository` | Home dashboard screens |
| `MechanicProvider` | `MechanicRepository` | Mechanic booking/listing screens |
| `AiProvider` | `AiService` + `DiagnosisService` | AI chat + diagnosis screens |
| `FuelProvider` | `FuelRepository` + `FuelService` | Fuel delivery screens (needs `LocationProvider`) |
| `MarketplaceProvider` | `MarketplaceRepository` + `CartService` | Marketplace browse/cart/checkout screens |
| `ProfileProvider` | `ProfileRepository` + `ProfileService` + `ValidationService` | Profile screens, wallet, rewards, settings |
| `ThemeProvider` | (own) + `shared_preferences` | Theme mode across app |
| `LocationProvider` | `GeocodingService`, `LocationService` | Map + delivery + nearby features |

## 3. Backend Relation (Sprint 2)

Provider → repository → (mock engine today) → will become FastAPI client calling
`backend/app/api/v1/*`. Repository interfaces are the swap boundary; provider
state machines must not change.
