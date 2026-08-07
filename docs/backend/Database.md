# Database Blueprint — Mecha Connect (PostgreSQL target)

> Sprint 1.9b · Derived from the frozen mock data model
> This blueprint is the source schema for the Sprint 2 backend. It is a
> forward-looking design: at RC1 all data is in-memory (see
> `API.md`). Tables mirror the entity fields the UI
> already depends on.

## 1. Conventions

- RDBMS: PostgreSQL 15+; `UUID` primary keys; `TIMESTAMPTZ` timestamps.
- Money as `NUMERIC(12,2)` (INR). Percent as `NUMERIC(5,2)`.
- Status stored as `VARCHAR` with app-level enums (kept compatible with the
  frozen client enums); CHECK constraints for valid values.
- Soft deletes via `deleted_at` where noted.
- `created_at` / `updated_at` on all mutable tables (default `now()`).

## 2. Entity–Relationship Overview

```
users 1─N vehicles        users 1─N addresses         users 1─N wallet_transactions
users 1─N reward_ledger   users 1─N notification_settings (1-1)
users 1─N conversations 1─N chat_messages             users 1─N diagnoses
categories 1─N products   1─N product_specs / product_reviews / product_images
mechanics 1─N mechanic_reviews
orders (parent) 1─N order_items (parts/marketplace)
fuel_orders 1─N tracking_events (→ invoice 1-1)
mechanic_bookings 1─N booking_events (→ rating 1-1)
orders (parent) 1─N order_entries  (unified Orders-tab view)
```

## 3. Core Tables

### users
| Column | Type | Notes |
|---|---|---|
| id | UUID PK | |
| name | TEXT NOT NULL | |
| email | TEXT UNIQUE NOT NULL | |
| phone | TEXT UNIQUE NOT NULL | |
| password_hash | TEXT | Sprint 2 (auth) |
| date_of_birth | DATE | |
| gender | TEXT | |
| membership_tier | TEXT NOT NULL DEFAULT 'free' | `free`/`pro` |
| joined_at | TIMESTAMPTZ NOT NULL | |
| emergency_contact_name | TEXT | |
| emergency_contact_relation | TEXT | |
| emergency_contact_phone | TEXT | |
| is_logged_in (client) | — | SharedPreferences only |
| created_at / updated_at | TIMESTAMPTZ | |

### vehicles
| Column | Type | Notes |
|---|---|---|
| id | UUID PK | client id `veh-*` |
| user_id | FK → users | |
| brand / model | TEXT NOT NULL | |
| registration | TEXT NOT NULL | |
| fuel_type | TEXT NOT NULL | `petrol`/`diesel`/… |
| insurance_expiry | DATE | |
| puc_expiry | DATE | |
| service_due_km | INT | |
| service_due_date | DATE | |
| is_default | BOOLEAN NOT NULL DEFAULT false | one default per user |
| health_score | SMALLINT | 0–100 |

### addresses
| Column | Type | Notes |
|---|---|---|
| id | UUID PK | client id `addr-*` |
| user_id | FK → users | |
| label | TEXT NOT NULL | `home`/`office`/`other` |
| address | TEXT NOT NULL | |
| latitude / longitude | NUMERIC(9,6) | |
| is_default | BOOLEAN DEFAULT false | |

### wallet
| Column | Type | Notes |
|---|---|---|
| user_id | UUID PK/FK → users | 1-1 |
| balance | NUMERIC(12,2) NOT NULL DEFAULT 0 | |
| reward_points | INT NOT NULL DEFAULT 0 | |

### wallet_transactions
| Column | Type | Notes |
|---|---|---|
| id | UUID PK | client id `txn-*` |
| user_id | FK → users | |
| title / subtitle | TEXT | |
| amount | NUMERIC(12,2) NOT NULL | |
| type | TEXT NOT NULL | `debit`/`credit` |
| occurred_at | TIMESTAMPTZ NOT NULL | |
| ref_order_id | TEXT | optional link |

### reward_ledger
| Column | Type | Notes |
|---|---|---|
| id | UUID PK | client id `rew-*` |
| user_id | FK → users | |
| title / subtitle | TEXT | |
| points | INT NOT NULL | signed (earn + / redeem −) |
| type | TEXT NOT NULL | `earned`/`referral`/`redeemed`/`achievement` |
| occurred_at | TIMESTAMPTZ NOT NULL | |

### notification_settings (1-1)
| Column | Type | Notes |
|---|---|---|
| user_id | UUID PK/FK | |
| push | BOOLEAN DEFAULT true | JSON round-trips with client `NotificationSettings` |

## 4. Marketplace

### categories
`id TEXT PK` (e.g. `engine-parts`), `name TEXT`, `icon TEXT`, `sort_order INT`.

### brands
`id TEXT PK` (e.g. `bosch`), `name TEXT`.

### products
| Column | Type | Notes |
|---|---|---|
| id | TEXT PK | `p-*` |
| brand_id | FK → brands | |
| category_id | FK → categories | |
| name | TEXT NOT NULL | |
| price / mrp | NUMERIC(12,2) NOT NULL | |
| rating | NUMERIC(3,2) DEFAULT 4.0 | |
| rating_count | INT DEFAULT 0 | |
| stock | INT NOT NULL DEFAULT 0 | 0 = out of stock |
| image_url | TEXT | |
| icon | TEXT | Material icon name |
| description | TEXT | |
| warranty | TEXT | |
| delivery_estimate | TEXT | |
| popularity | INT DEFAULT 0 | |
| age_days | INT DEFAULT 0 | |
| is_featured / is_best_seller / is_trending / is_flash_deal / is_recommended | BOOLEAN DEFAULT false | |
| created_at / updated_at | TIMESTAMPTZ | |

### product_specifications
`id UUID PK`, `product_id FK`, `label TEXT`, `value TEXT`, `sort_order INT`.

### product_vehicle_types
`product_id FK`, `vehicle_type TEXT` (`bike`/`car`/`suv`). M:N.

### product_compatibility
`product_id FK`, `compatible_with TEXT`.

### product_reviews
`id UUID PK` (`rv-*`), `product_id FK`, `author TEXT`, `rating NUMERIC(3,2)`,
`comment TEXT`, `reviewed_at DATE`, `is_verified_purchase BOOLEAN DEFAULT true`,
`helpful_count INT DEFAULT 0`.

### offers
`id TEXT PK` (`offer-*`), `title`, `subtitle`, `code TEXT`, `category_id FK`,
`gradient_start TEXT`, `gradient_end TEXT`.

### coupons
`id TEXT PK` (`coupon-*`), `code TEXT UNIQUE`, `title`, `description`,
`type TEXT` (`percent`/`freeDelivery`), `value NUMERIC(5,2)`,
`max_discount NUMERIC(12,2)`, `min_order_value NUMERIC(12,2)`,
`valid_from`/`valid_until TIMESTAMPTZ`.

## 5. Orders (Marketplace) + Unified Orders Tab

### orders (parent)
| Column | Type | Notes |
|---|---|---|
| id | UUID PK | internal |
| user_id | FK → users | |
| external_id | TEXT UNIQUE | `MKP-<year>-<0000>` |
| address | TEXT NOT NULL | snapshot |
| payment_method | TEXT NOT NULL | |
| subtotal / discount / delivery / tax / grand_total | NUMERIC(12,2) | |
| status | TEXT NOT NULL DEFAULT 'Pending' | |
| created_at | TIMESTAMPTZ | |

### order_items
`id UUID PK`, `order_id FK`, `product_id FK`, `product_name TEXT`, `brand TEXT`,
`quantity INT`, `unit_price NUMERIC(12,2)`, `line_total NUMERIC(12,2)`,
`image TEXT`.

### order_entries (unified Orders-tab feed)
| Column | Type | Notes |
|---|---|---|
| id | TEXT PK | client-facing `ORD-*` / `MKP-*` |
| user_id | FK → users | |
| name / brand | TEXT | |
| quantity | INT | |
| price | NUMERIC(12,2) | |
| type | TEXT NOT NULL | `parts`/`mechanic`/`fuel`/`aiReport` |
| status | TEXT NOT NULL | `Pending`/`Delivered`/`Completed`/`In Progress`/`Cancelled` |
| occurred_at | TIMESTAMPTZ NOT NULL | |
| source | TEXT | originating module |

This is the row the client's `ordersList` maps to; Marketplace inserts write
here, and the Orders tab + Profile order history read it (single source).

## 6. Mechanic

### mechanics
| Column | Type | Notes |
|---|---|---|
| id | TEXT PK | `m*` |
| name | TEXT NOT NULL | |
| rating | NUMERIC(3,2) | |
| review_count | INT | |
| experience_years | INT | |
| distance_km | NUMERIC(6,2) | computed at request time in Sprint 2 |
| eta_minutes | INT | |
| is_available | BOOLEAN DEFAULT true | |
| price_starting | NUMERIC(12,2) | |
| phone | TEXT | |
| about | TEXT | |
| is_verified | BOOLEAN DEFAULT false | |

### mechanic_skills / mechanic_languages / mechanic_working_hours
M:N strings per mechanic (`skills[]`, `languages[]`, `workingHours{}`).

### mechanic_services
`id TEXT PK` (`svc_*`), `name`, `icon`, `price NUMERIC(12,2)`,
`estimated_minutes INT`, `description`. `mechanic_service_offered`
(mechanic_id, service_id) M:N.

### mechanic_categories
`id TEXT PK`, `name`, `icon`, `color`, `bg_color`, `description`,
`sort_order INT`.

### mechanic_reviews
`id TEXT PK` (`r*`), `mechanic_id FK`, `reviewer_name`, `rating NUMERIC(3,2)`,
`comment`, `reviewed_at DATE`, `vehicle TEXT`.

### mechanic_bookings
| Column | Type | Notes |
|---|---|---|
| id | UUID PK | |
| user_id | FK → users | |
| mechanic_id | FK → mechanics | |
| service_id | FK → mechanic_services | |
| vehicle_id | FK → vehicles | |
| status | TEXT | booking state machine |
| address / lat / lng | TEXT / NUMERIC | |
| scheduled_at / created_at | TIMESTAMPTZ | |

### booking_events
`id UUID PK`, `booking_id FK`, `status TEXT`, `occurred_at TIMESTAMPTZ`,
`payload JSONB` (live tracking snapshots). → `ratings` (booking_id 1-1):
`rating NUMERIC(3,2)`, `review TEXT`.

## 7. Fuel Delivery

### fuel_orders
| Column | Type | Notes |
|---|---|---|
| id | TEXT PK | `FUEL-<year>-<0000>` |
| user_id | FK → users | |
| fuel_type | TEXT NOT NULL | |
| quantity | NUMERIC(6,2) NOT NULL | litres |
| vehicle_type / vehicle_name / vehicle_number | TEXT | snapshot |
| station_id | FK → fuel_stations | |
| station_name / brand / price_per_litre | TEXT/NUMERIC | snapshot |
| delivery_label / delivery_address / lat / lng | TEXT/NUMERIC | |
| status | TEXT NOT NULL | `requested…delivered`/`cancelled` |
| payment_method | TEXT | |
| partner_id | FK → fuel_partners | nullable |
| created_at | TIMESTAMPTZ | |

### price_estimates (1-1 with fuel_orders)
`fuel_cost`, `delivery_charge`, `platform_fee`, `taxes`, `grand_total`
`NUMERIC(12,2)`; `eta_minutes INT`.

### fuel_stations
`id TEXT PK` (`station_*`), `name`, `brand`, `rating NUMERIC(3,2)`,
`rating_count INT`, `distance_km NUMERIC(6,2)`, `eta_minutes INT`,
`price_per_litre NUMERIC(6,2)`, `availability TEXT`
(`available`/`low`/`outOfStock`), `is_open BOOLEAN`, `address TEXT`,
`latitude/longitude NUMERIC(9,6)`.

### fuel_partners
`id TEXT PK` (`partner_*`), `name`, `phone`, `rating NUMERIC(3,2)`,
`rating_count INT`, `distance_km NUMERIC(6,2)`, `eta_minutes INT`,
`is_available BOOLEAN`, `vehicle_number TEXT`, `vehicle_model TEXT`.

### tracking_events
`id UUID PK`, `order_id FK`, `status TEXT`, `partner_lat/lng`,
`distance_remaining NUMERIC(6,2)`, `eta_minutes INT`, `occurred_at`.

### invoices
`invoice_id TEXT PK` (`INV-<orderId>`), `order_id FK UNIQUE`, `created_at`,
`fuel_type`, `quantity`, `price_per_litre`, `fuel_cost`, `delivery_charge`,
`platform_fee`, `taxes`, `grand_total`, `partner_name`, `vehicle_number`.

## 8. AI Assistant

### conversations
| Column | Type | Notes |
|---|---|---|
| id | TEXT PK | `ai-*` |
| user_id | FK → users | |
| title | TEXT NOT NULL | |
| is_pinned | BOOLEAN DEFAULT false | |
| created_at / updated_at | TIMESTAMPTZ | |

### chat_messages
`id TEXT PK` (`m-*`), `conversation_id FK`, `role TEXT` (`user`/`assistant`),
`content TEXT`, `timestamp TIMESTAMPTZ`, `response JSONB` (AiResponse blocks +
actions).

### diagnoses
`id TEXT PK` (`diag-*`), `user_id FK`, `vehicle_name`, `vehicle_type`,
`problem`, `symptoms JSONB`, `possible_causes JSONB`, `severity TEXT`,
`estimated_cost NUMERIC(12,2)`, `recommended_action TEXT`, `should_drive BOOLEAN`,
`recommended_service TEXT`, `confidence SMALLINT`, `created_at TIMESTAMPTZ`.

## 9. Mapping Notes (client → schema)

- Client `Map<String,dynamic>` orders (`ordersList`) ↔ `order_entries`.
- Client `ProfileStats.orders` is `count(order_entries)`; `services` is a
  counter (12 at seed); `rewards` is `sum(reward_ledger.points)`.
- Client vehicle/address counters start at 200 because seeds use 101/102.
- `is_logged_in` and `theme_mode` stay on-device (SharedPreferences), not DB.
- Live tracking in Sprint 2 uses `tracking_events` + WebSocket push; the
  `TrackingInfo` payload shape is already frozen.
