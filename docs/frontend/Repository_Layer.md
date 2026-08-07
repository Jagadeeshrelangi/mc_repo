# Repository Layer — Mecha Connect

> The frozen seam between UI and data. At RC1 every repository is an in-memory
> mock; Sprint 2 replaces internals with the real backend without changing any
> screen or provider signature.

## 1. The Seam

- Every module has **one repository** that is the ONLY data source.
- Providers call repositories; **screens never call HTTP**.
- Repository interfaces are the frozen API contract (`docs/backend/API.md`).

## 2. Mock Realism (RC1)

| Repository | Simulated latency | Failure injection |
|---|---|---|
| `AiRepository` | 900ms | `failForFirstCalls` |
| `ProfileRepository` | 800ms | `failForFirstCalls` |
| `HomeRepository` | 800ms | — |
| `MarketplaceRepository` | 700ms | — |
| `FuelRepository` | 700ms | — |
| `MechanicRepository` | per method | constructor-injectable |

Repositories simulate latency and throw typed exceptions with user-facing
`message` (e.g. `AiNetworkException`, `ProfileNetworkException`), so loading,
empty, and error/retry states are real.

## 3. Per-Module Repositories

- **AI:** `AiRepository` — seed knowledge base (5 conversations, 2 pinned),
  raw keyword replies, structured diagnosis templates; shared by
  `AiProvider`/`AiService`/`DiagnosisService`.
- **Marketplace:** catalog (40 products / 10 categories / 15 brands / 3 offers
  / 3 coupons) + order creation with `MKP-<year>-<0000>` ids.
- **Mechanic:** 4 mechanics, 3 featured, reviews `r1`–`r8`; booking,
  tracking, rating surface.
- **Fuel:** stations near lat/lng, order lifecycle, `INV-` invoices, seeded
  history `FUEL-2026-0005..0009`.
- **Profile:** seeded profile, vehicles/addresses (counters from 200), wallet,
  rewards, stats; reads shared `ordersList`.
- **Home:** `fetchHomeData()` → `HomeData` aggregate (quick/nearby services,
  marketplace items, activities, offers).
- **Auth:** `AuthRepository` + `AuthService`; login state persisted on-device
  only at RC1.

## 4. Sprint 2 Integration Seams

| Seam | Today | Sprint 2 |
|---|---|---|
| Repositories | In-memory mocks | HTTP client (FastAPI/PostgreSQL) |
| `AiRepository` | Mock KB + templates | Gemini/OpenAI client |
| `ProfileRepository` | In-memory + SharedPreferences | FastAPI/PostgreSQL |
| `ordersList`/`orderStore` | Global singleton | Repository-backed feed (`order_entries`) |
| Coupon validation | Catalog data | Server-side validation |
| Real-time tracking | Simulated `TrackingInfo` | WebSocket/push |

## 5. Rules (frozen)

1. New data access must go through the module repository — never ad-hoc HTTP.
2. Preserve latency/failure conventions so QA states remain exercisable.
3. ID schemes and payload shapes are frozen (see `docs/backend/API.md`).
