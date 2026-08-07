# Repositories & Services Inventory — Mecha Connect

> Phase 1 · Class names captured by repo scan

## 1. Repositories (7, all mock/in-memory at RC1)

| Repository | File location | Data served | Backend relation (Sprint 2) |
|---|---|---|---|
| `AuthRepository` | `lib/features/auth/repositories/` | Auth session, login/logout | `backend/app/api/v1/auth*` (scaffolded) |
| `HomeRepository` | `lib/features/home/repositories/` | Dashboard aggregates | — |
| `MechanicRepository` | `lib/features/mechanic/repositories/` | Mechanics, services, bookings | `backend/app/api/v1/*` |
| `AiRepository` | `lib/features/ai/repositories/` | Chat history, suggested questions | `conversation.py`, `knowledge.py` |
| `ProfileRepository` | `lib/features/profile/repositories/` | Profile, wallet, rewards, addresses | — |
| `FuelRepository` | `lib/features/fuel_delivery/repositories/` | Fuel orders, stations, partners | — |
| `MarketplaceRepository` | `lib/features/marketplace/repositories/` | Products, cart, orders, coupons | — |

All repositories share one contract at RC1: **in-memory mock engines with simulated
latency + injected failures** (see `docs/03_development/FAULT_INJECTION.md`). No
network I/O in the client at RC1.

## 2. Services (13 classes / 10 files)

| Service | Module | Purpose |
|---|---|---|
| `AiService` | ai | Chat completion orchestration |
| `DiagnosisService` | ai | Fault diagnosis engine (mirrors `fault_classifier.joblib`) |
| `AuthService` | auth | Auth use-cases over `AuthRepository` |
| `FuelService` | fuel_delivery | Fuel delivery use-cases |
| `NearbyService` | fuel_delivery | Nearby stations/partners (distance-based) |
| `QuickService` (+ `_QuickService` private) | fuel_delivery | Quick order shortcuts |
| `CartService` | marketplace | Cart state/count |
| `SelectService` (+ `_SelectService` private) | marketplace | Selection state helpers |
| `ProfileService` | profile | Profile use-cases |
| `ValidationService` | profile | Form validation (address, vehicle, payment) |
| `GeocodingService` | shared (`lib/services/`) | Reverse geocoding for location display |
| `LocationService` | shared (`lib/services/`) | Wraps geolocator + permission_handler |

## 3. Shared Services Detail

- `LocationProvider` (in `lib/services/location_provider.dart`) depends on
  `GeocodingService` + `LocationService`; consumed by fuel delivery and mechanic
  nearby screens for map centering and "nearest" ordering.
