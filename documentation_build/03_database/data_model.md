# Database Knowledge — Mecha Connect

> Phase 3 · Target: PostgreSQL 15 (Sprint 2). Source: `DATABASE_BLUEPRINT.md` (reused).
> At RC1 all data is in-memory; this is the forward-looking schema the UI already depends on.

## 1. Conventions
- `UUID` primary keys, `TIMESTAMPTZ` timestamps, `NUMERIC(12,2)` money (INR), `NUMERIC(5,2)` percent.
- Status stored as `VARCHAR` with app-level enums + CHECK constraints (compatible with frozen client enums).
- Soft deletes via `deleted_at` where noted; `created_at`/`updated_at` on all mutable tables.
- Client IDs (`MKP-*`, `veh-*`, `addr-*`…) map to `external_id` / `id` columns; see `04_api/id_schemes.md`.

## 2. Entity Groups

### 2.1 Users & wallet
`users` (membership_tier free|pro, emergency contact, PII) ·
`vehicles` (brand/model/registration/fuel_type, insurance & PUC expiry, service_due, is_default, health_score 0–100) ·
`addresses` (label home|office|other, lat/lng) ·
`wallet` (1-1, balance + reward_points) ·
`wallet_transactions` (debit|credit, ref_order_id) ·
`reward_ledger` (earned|referral|redeemed|achievement, signed points) ·
`notification_settings` (1-1, JSON round-trip with client).

### 2.2 Marketplace
`categories` (id TEXT e.g. `engine-parts`) · `brands` (id TEXT e.g. `bosch`) ·
`products` (40 at seed; price/mrp, rating, stock, flags is_featured/best_seller/trending/flash_deal/recommended, image_url, warranty, delivery_estimate) ·
`product_specifications` · `product_vehicle_types` (bike|car|suv M:N) · `product_compatibility` ·
`product_reviews` (is_verified_purchase, helpful_count) · `offers` (code + gradient) · `coupons`
(percent|freeDelivery, value, max_discount, min_order_value, valid_from/until).

### 2.3 Orders + unified Orders tab
`orders` (parent: subtotal/discount/delivery/tax/grand_total, external_id `MKP-<year>-<0000>`) ·
`order_items` (product snapshot) ·
`order_entries` (**client's `ordersList` mapping**; id `ORD-*`/`MKP-*`, type parts|mechanic|fuel|aiReport,
status Pending|Delivered|Completed|In Progress|Cancelled, source). Marketplace inserts write here; Orders tab +
Profile order history read the same rows.

### 2.4 Mechanic
`mechanics` (id `m*`, rating, distance/eta computed at request time, price_starting, is_verified) +
`mechanic_skills`/`mechanic_languages`/`mechanic_working_hours` (M:N strings) ·
`mechanic_services` (id `svc_*`, price, estimated_minutes) + `mechanic_service_offered` M:N ·
`mechanic_categories` · `mechanic_reviews` (id `r*`) ·
`mechanic_bookings` (state machine) + `booking_events` (payload JSONB = live-tracking snapshots) + `ratings` (1-1).

### 2.5 Fuel delivery
`fuel_orders` (id `FUEL-<year>-<0000>`, status requested→delivered/cancelled, snapshots of station/vehicle/address) ·
`price_estimates` (1-1: fuel_cost, delivery_charge, platform_fee, taxes, grand_total, eta_minutes) ·
`fuel_stations` (id `station_*`, availability available|low|outOfStock) ·
`fuel_partners` (id `partner_*`) · `tracking_events` (status, lat/lng, distance_remaining) ·
`invoices` (invoice_id `INV-<orderId>`, 1-1 with fuel_orders).

### 2.6 AI
`conversations` (id `ai-*`, is_pinned) · `chat_messages` (id `m-*`, role user|assistant, response JSONB = AiResponse blocks/actions) ·
`diagnoses` (id `diag-*`, symptoms/possible_causes JSONB, severity, estimated_cost, should_drive, confidence, recommended_service).

## 3. Client → Schema Mapping Notes (frozen)
- `ordersList` (Map entries) ↔ `order_entries`.
- `ProfileStats.orders` = `count(order_entries)`; `services` is a seed counter (12); `rewards` = `sum(reward_ledger.points)`.
- Vehicle/address client counters start at 200 (seeds use 101/102).
- `is_logged_in` and `theme_mode` stay on-device (SharedPreferences), never in DB.
- Sprint 2 live tracking: `tracking_events` + WebSocket push; `TrackingInfo` payload shape frozen.

## 4. DDL
Generated statement script: see `schema.sql` (companion to this file, same conventions).
