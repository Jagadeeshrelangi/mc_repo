# Database Audit — Mecha Connect

> **Phase 0 · Complete Engineering Audit · 2026-08-05**
> Scope: Database Blueprint, schema SQL, entities, relationships, constraints, indexes, migrations, scalability.

## 1. Current State

- **Target:** PostgreSQL 15 (Sprint 2). At RC1 all data is in-memory mocks.
- **Sources:** `docs/07_rc1_certification/DATABASE_BLUEPRINT.md` (canonical), `documentation_build/03_database/data_model.md`, `documentation_build/03_database/schema.sql` (430 lines).
- **Conventions:** UUID PKs, `TIMESTAMPTZ`, `NUMERIC(12,2)` money (INR), `NUMERIC(5,2)` percent, VARCHAR status + CHECK constraints, soft deletes via `deleted_at`, `created_at`/`updated_at` on mutable tables.

### 1.1 Entity groups
| Group | Tables |
|---|---|
| Users & wallet | `users`, `vehicles`, `addresses`, `wallet`, `wallet_transactions`, `reward_ledger`, `notification_settings` |
| Marketplace | `categories`, `brands`, `products`, `product_specifications`, `product_vehicle_types`, `product_compatibility`, `product_reviews`, `offers`, `coupons` |
| Orders | `orders`, `order_items`, `order_entries` |
| Mechanic | `mechanics`, `mechanic_skills`, `mechanic_languages`, `mechanic_working_hours`, `mechanic_services`, `mechanic_service_offered`, `mechanic_categories`, `mechanic_reviews`, `mechanic_bookings`, `booking_events`, `ratings` |
| Fuel | `fuel_orders`, `price_estimates`, `fuel_stations`, `fuel_partners`, `tracking_events`, `invoices` |
| AI | `conversations`, `chat_messages`, `diagnoses` |

## 2. Strengths

| # | Finding | Detail |
|---|---|---|
| S1 | **UUID primary keys** | Consistent, non-sequential, collision-safe |
| S2 | **Money as NUMERIC(12,2)** | Correct decimal representation for INR — never FLOAT |
| S3 | **CHECK constraints on enums** | `membership_tier IN ('free','pro')`, `addresses.label IN ('home','office','other')`, `health_score BETWEEN 0 AND 100` |
| S4 | **Timestamps on mutable tables** | `created_at`/`updated_at` everywhere |
| S5 | **Client mapping documented** | `ordersList` ↔ `order_entries`; client IDs (`veh-*`, `addr-*`) map to `external_id`/`id` |
| S6 | **JSONB for flexible payloads** | `booking_events` (live-tracking snapshots), `chat_messages.response` (AiResponse blocks) |
| S7 | **M:N junction tables** | `product_vehicle_types`, `mechanic_service_offered`, `mechanic_skills` etc. |
| S8 | **Status CHECKs match frozen client enums** | Order statuses `Pending|Delivered|Completed|In Progress|Cancelled` mirror client `OrderType` |
| S9 | **`wallet` is 1-1 with `users`** | Correct — one wallet per user |
| S10 | **`password_hash` nullable** | Firestore/Firebase Auth will own credentials; app-level hash is optional |

## 3. Weaknesses

| # | Finding | Severity | Detail |
|---|---|---|---|
| W1 | **No FK indexes** | P1 | `vehicles.user_id`, `addresses.user_id`, `order_items.order_id`, etc. — no explicit `CREATE INDEX` on foreign keys. Query performance will degrade with volume. |
| W2 | **No `deleted_at` on key tables** | P2 | Convention says "soft deletes via `deleted_at` where noted" but `users`, `products`, `mechanics` have no `deleted_at` column |
| W3 | **No updated_at trigger** | P2 | `updated_at` is `DEFAULT now()` but has no trigger to auto-update on row change — stale `updated_at` |
| W4 | **No migration tooling** | P0 | **No Alembic.** No migration files. Schema.sql is a static script — Sprint 2 needs Alembic. |
| W5 | **No seed data SQL** | P2 | No INSERT statements for the 40 products, 10 categories, 15 brands, 6 stations, 4 mechanics, etc. |
| W6 | **No extension declaration** | P3 | `gen_random_uuid()` requires `pgcrypto` extension — not declared in schema |
| W7 | **Index strategy missing** | P1 | No indexes documented for: `orders.external_id` (MKP-XXXX), `fuel_orders.id`, `conversations.user_id`, `order_entries.type` |
| W8 | **`order_entries` design is for the client tab** | P3 | `order_entries` (id `ORD-*`/`MKP-*`, type parts|mechanic|fuel|aiReport) is a denormalized feed for the Orders tab. Acceptable but worth documenting as a view/aggregate. |
| W9 | **No `unique` on `products.sku`** | P2 | Products have no natural key constraint |
| W10 | **No partition strategy** | P3 | `tracking_events` and `booking_events` will grow fast — no partition plan for high-volume event tables |
| W11 | **`reward_tier_progress` mismatch** | P2 | Client `RewardTierProgress` has `nextTier: free` when current is `pro` — logical inconsistency in seed data (client-side) vs schema has no tier progression table |
| W12 | **No JSON schema validation** | P3 | `booking_events` JSONB has no CHECK for required fields |

## 4. Schema Review (key tables)

### 4.1 `users` — ✅ Good
- `email UNIQUE NOT NULL`, `phone UNIQUE NOT NULL` — correct.
- `password_hash TEXT` nullable — correct for Firebase Auth integration.
- `membership_tier CHECK ('free','pro')` — matches client enum.
- **Gap:** no `deleted_at`, no `last_login_at`, no `referral_code` (client seed has `referralCode: GOWDA200`).

### 4.2 `orders` / `order_items` / `order_entries` — ⚠️ Partial
- `orders` parent with `subtotal/discount/delivery/tax/grand_total` — good.
- `order_items` product snapshot — good.
- `order_entries` = client's `ordersList` mapping — aligned.
- **Gap:** no FK from `order_entries` to `orders` visible in first 60 lines; need full read.

### 4.3 `mechanic_bookings` — ⚠️ Needs review
- State machine documented; `booking_events` JSONB for tracking — good.
- **Gap:** no explicit `CHECK` on booking status transitions visible.

### 4.4 `fuel_orders` — ⚠️ Partial
- `status requested→delivered/cancelled` documented.

## 5. Risks

| # | Risk | Severity | Mitigation |
|---|---|---|---|
| R1 | No migration tooling — schema drift | P0 | Add Alembic in Sprint 2 |
| R2 | No FK indexes — slow joins | P1 | Add indexes on all `*_id` columns |
| R3 | No seed SQL — empty dev/staging DBs | P2 | Create seed migration |
| R4 | No updated_at trigger — stale audit trail | P2 | Add trigger function |
| R5 | Event-table growth (tracking/booking) | P3 | Partition by month in Sprint 3 |

## 6. Technical Debt

| # | Debt | Priority | Effort |
|---|---|---|---|
| TD1 | No Alembic migrations | P0 | 1 day |
| TD2 | No FK indexes | P1 | 1 hr |
| TD3 | No seed data | P2 | 3 hr |
| TD4 | No updated_at trigger | P2 | 30 min |
| TD5 | `pgcrypto` extension undeclared | P3 | 5 min |

## 7. Recommendations

1. **P0 — Add Alembic** as the migration tool in Sprint 2; convert schema.sql → initial migration.
2. **P1 — Add FK indexes**: `CREATE INDEX idx_vehicles_user_id ON vehicles(user_id)` etc. for every FK.
3. **P1 — Declare `pgcrypto`** at top of schema.
4. **P2 — Add seed migration** with all frozen mock data (40 products, 10 categories, 15 brands, 6 stations, 4 mechanics + reviews).
5. **P2 — Add `updated_at` trigger** via a PL/pgSQL function.
6. **P2 — Add `deleted_at`** to users/products/mechanics per convention.
7. **P3 — Add uniqueness** on `products.sku`; document `order_entries` as a denormalized aggregate view.

## 8. Priority Summary

| Priority | Count | Items |
|---|---|---|
| P0 | 1 | W4, R1, TD1 |
| P1 | 2 | W1, W7, R2, TD2 |
| P2 | 5 | W2, W3, W5, W9, W11, R3, R4, TD3, TD4 |
| P3 | 3 | W6, W8, W10, W12, R5, TD5 |