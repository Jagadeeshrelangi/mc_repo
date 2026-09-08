# TASK PHASE 1 — TASK 1: PRODUCTION PILOT CATALOG SEEDING
## STEP 1 — ARCHITECTURE DECISIONS

> **Executive Authority:** Senior Staff Engineer / Technical Architect  
> **Target Environment:** Supabase PostgreSQL (`aws-0-ap-northeast-2.pooler.supabase.com:5432/postgres`)  
> **Status:** STEP 1 — ARCHITECTURE DECISIONS ONLY (APPROVED FOR IMPLEMENTATION)  
> **Database Modifications Performed:** NONE (DML will execute in Step 2)  
> **Code Modifications Performed:** NONE  

---

### 1. Executive Decision

The Chief Executive Officer has reviewed and approved the baseline findings in `TASK_PHASE1_TASK1_RECONNAISSANCE_REPORT.md`. All backend domain models, schemas, repositories, and API routers for Mechanics, Fuel Delivery, and Marketplace are complete and verified across 700 backend pytest tests. The Flutter mobile app has 238 passing tests and 0 analysis issues.

We hereby formally lock the architectural design for the **Production Pilot Catalog Seeder**.

**Core Decisions Locked:**
1. **Pilot Geography:** Locked to **Bengaluru, Karnataka, India** (`12.9716, 77.5946`), matching all frontend default constants, geocoding fallbacks, and user profile address mocks.
2. **Deterministic Identifiers:** Every seed record uses a deterministic natural or UUIDv5 primary key matching existing frontend and test fixtures (`m1`–`m8`, `svc_1`–`svc_8`, `station_1`–`station_6`, `p-chain-kit`, `MECHA10`, etc.).
3. **Idempotency Strategy:** All inserts use PostgreSQL dialect-level `ON CONFLICT (PK) DO UPDATE` or `DO NOTHING`. The script is safe to run repeatedly without record inflation or duplicate key errors.
4. **Hard Database Safety Boundary:** Zero execution of `DROP`, `DELETE`, or `TRUNCATE`. Tables containing user accounts (`users`, `vehicles`, `addresses`, `wallet`, `orders`, `fuel_orders`, `conversations`) will never be modified.
5. **Zero Schema Alterations:** The live database at migration head `0006` contains all 41 required tables and constraints. No Alembic migrations or DDL statements will be executed.
6. **Local Asset Integration:** Product image paths map directly to existing offline bundled Flutter assets (`assets/chain kit.png`, `assets/battery.png`, etc.) with clean icon fallbacks, preventing broken remote image dependencies on real devices.

---

### 2. Confirmed Scope

The seeder (`backend/scripts/seed_pilot_catalog.py`) will seed exactly 19 catalog and attribute tables across three business domains:

```
                               ┌────────────────────────────────────────────────────────┐
                               │       MECHA CONNECT PILOT CATALOG SEED DOMAINS        │
                               └────────────────────────────────────────────────────────┘
                                      │                        │                        │
               ┌──────────────────────┴─────────┐   ┌──────────┴──────────┐   ┌─────────┴─────────────────────┐
               ▼                                │   ▼                     │   ▼                               │
       MECHANICS DOMAIN                         │  FUEL DELIVERY DOMAIN   │  MARKETPLACE & PARTS DOMAIN       │
  • mechanic_categories (8)                     │  • fuel_partners (4)    │  • categories (8)                 │
  • mechanic_services (8)                       │  • fuel_stations (6)    │  • brands (10)                    │
  • mechanics (8)                               │                         │  • offers (3)                     │
  • mechanic_skills (~30)                       │                         │  • coupons (3)                    │
  • mechanic_languages (~25)                    │                         │  • products (18)                  │
  • mechanic_working_hours (~24)                │                         │  • product_specifications (~54)   │
  • mechanic_service_offered (~40)              │                         │  • product_vehicle_types (~36)    │
  • mechanic_reviews (12)                       │                         │  • product_compatibility (~45)    │
                                                │                         │  • product_reviews (18)           │
```

---

### 3. Architecture Impact

* **Backend Layer**: A single standalone script will be added under `backend/scripts/seed_pilot_catalog.py`. It uses the existing SQLAlchemy async engine configured via `app.core.config.settings.DATABASE_URL`. Zero changes to existing routers, services, repositories, or models.
* **Frontend Layer**: Zero code modifications. The Flutter client already contains repositories and providers wired to these exact endpoints and response shapes.
* **Database Layer**: Pure additive Data Manipulation Language (DML). Zero Data Definition Language (DDL) or schema migrations.

---

### 4. Model-by-Model Seed Requirements

#### Mechanics Domain
1. **`mechanic_categories`**:
   - `id`: `Text` PK (e.g. `cat_general`, `cat_breakdown`, `cat_battery`, `cat_tyre`, `cat_engine`, `cat_brake`, `cat_electrical`, `cat_towing`).
   - `name`: `Text` NOT NULL.
   - `icon`: `Text` (Material icon name matching client).
   - `color`, `bg_color`: `Text` hex tokens.
   - `description`: `Text`.
   - `sort_order`: `Integer` NOT NULL (0..7).
2. **`mechanic_services`**:
   - `id`: `Text` PK (`svc_1` to `svc_8`).
   - `name`: `Text` NOT NULL.
   - `icon`: `Text` icon name.
   - `price`: `Numeric(12,2)` INR.
   - `estimated_minutes`: `Integer` duration.
   - `description`: `Text`.
3. **`mechanics`**:
   - `id`: `Text` PK (`m1` to `m8`).
   - `name`: `Text` NOT NULL.
   - `rating`: `Numeric(3,2)` (range 4.3 to 4.9).
   - `review_count`: `Integer` (48 to 203).
   - `experience_years`: `Integer` (5 to 15).
   - `distance_km`: `Numeric(6,2)` (0.8 to 5.0).
   - `eta_minutes`: `Integer` (5 to 20).
   - `is_available`: `Boolean` (True for 7, False for 1 to test unavailable state).
   - `price_starting`: `Numeric(12,2)` (₹149 to ₹299).
   - `phone`: `Text` (`+91 98765 43210`).
   - `about`: `Text` realistic garage bio.
   - `is_verified`: `Boolean` (True for 7, False for 1).
4. **`mechanic_skills`**: Composite PK `(mechanic_id, skill)`. FK -> `mechanics.id` ON DELETE CASCADE.
5. **`mechanic_languages`**: Composite PK `(mechanic_id, language)`. FK -> `mechanics.id` ON DELETE CASCADE.
6. **`mechanic_working_hours`**: Composite PK `(mechanic_id, day)`. FK -> `mechanics.id` ON DELETE CASCADE. `open` and `close` strings.
7. **`mechanic_service_offered`**: Composite PK `(mechanic_id, service_id)`. M:N junction.
8. **`mechanic_reviews`**: `id` `Text` PK (`r1` to `r12`). `mechanic_id` FK, `reviewer_name`, `rating`, `comment`, `reviewed_at` (Date), `vehicle`.

#### Fuel Delivery Domain
1. **`fuel_partners`**:
   - `id`: `Text` PK (`partner_1` to `partner_4`).
   - `name`: `Text` driver name.
   - `phone`: `Text`.
   - `rating`: `Numeric(3,2)` (4.5 to 4.9).
   - `rating_count`: `Integer`.
   - `distance_km`, `eta_minutes`: distance and arrival estimates.
   - `is_available`: `Boolean` (True).
   - `vehicle_number`, `vehicle_model`: bowser details.
2. **`fuel_stations`**:
   - `id`: `Text` PK (`station_1` to `station_6`).
   - `name`: `Text` bunk name.
   - `brand`: `Text` (`Indian Oil`, `BPCL`, `HPCL`, `Shell`).
   - `rating`: `Numeric(3,2)` (4.3 to 4.8).
   - `rating_count`: `Integer`.
   - `distance_km`: `Numeric(6,2)` (1.2 to 4.5).
   - `eta_minutes`: `Integer` (12 to 22).
   - `price_per_litre`: `Numeric(6,2)` (₹101.90 to ₹108.00).
   - `availability`: `Text` (`available` for 1-5, `low` for 6; strictly enforced by `ck_fuel_stations_availability`).
   - `is_open`: `Boolean` (True).
   - `address`: `Text` Bengaluru locality.
   - `latitude`, `longitude`: `Numeric(9,6)`.

#### Marketplace & Parts Domain
1. **`categories`**:
   - `id`: `Text` PK (`engine-parts`, `brake-system`, `oils`, `tyres`, `batteries`, `accessories`, `cleaning`, `lights`).
   - `name`: `Text` NOT NULL.
   - `icon`: `Text` Material icon name.
   - `sort_order`: `Integer` (0..7).
2. **`brands`**:
   - `id`: `Text` PK (`bosch`, `tvs`, `rolon`, `ngk`, `castrol`, `motul`, `mrf`, `ceat`, `exide`, `amaron`, `3m`, `philips`).
   - `name`: `Text` NOT NULL.
3. **`offers`**:
   - `id`: `Text` PK (`offer-brake`, `offer-tyre`, `offer-oil`).
   - `title`, `subtitle`, `code`: `Text`.
   - `category_id`: `Text` FK -> `categories.id`.
   - `gradient_start`, `gradient_end`: `Text` hex colors.
4. **`coupons`**:
   - `id`: `Text` PK (`coupon-mecha10`, `coupon-mecha20`, `coupon-freeship`).
   - `code`: `Text` UNIQUE (`MECHA10`, `MECHA20`, `FREESHIP`).
   - `title`, `description`: `Text`.
   - `type`: `Text` (`percent` or `freeDelivery`; strictly enforced by `ck_coupons_type`).
   - `value`: `Numeric(5,2)` (10.00, 20.00, 0.00).
   - `max_discount`, `min_order_value`: `Numeric(12,2)`.
   - `valid_from`, `valid_until`: `DateTime(timezone=True)`.
5. **`products`**:
   - `id`: `Text` PK (e.g. `p-chain-kit`, `p-spark-plug`, `p-brake-pad`, etc.).
   - `brand_id`: `Text` FK -> `brands.id`.
   - `category_id`: `Text` FK -> `categories.id`.
   - `name`: `Text` NOT NULL.
   - `price`: `Numeric(12,2)` discounted sale price.
   - `mrp`: `Numeric(12,2)` maximum retail price (`mrp >= price`).
   - `rating`, `rating_count`: `Numeric(3,2)`, `Integer`.
   - `stock`: `Integer` (>0).
   - `image_url`: `Text` local asset path.
   - `description`, `warranty`, `delivery_estimate`: `Text`.
   - `is_featured`, `is_best_seller`, `is_trending`, `is_recommended`: `Boolean`.
6. **`product_specifications`**:
   - `id`: `Uuid` PK (deterministic UUIDv5).
   - `product_id`: `Text` FK -> `products.id`.
   - `label`, `value`: `Text` NOT NULL.
   - `sort_order`: `Integer`.
7. **`product_vehicle_types`**:
   - Composite PK `(product_id, vehicle_type)`.
   - `vehicle_type`: `Text` (`bike`, `car`, `suv`, `truck`).
8. **`product_compatibility`**:
   - Composite PK `(product_id, compatible_with)`.
   - `compatible_with`: `Text` vehicle model name.
9. **`product_reviews`**:
   - `id`: `Uuid` PK (deterministic UUIDv5).
   - `product_id`: `Text` FK -> `products.id`.
   - `author`, `comment`: `Text`.
   - `rating`: `Numeric(3,2)`.
   - `reviewed_at`: `Date`.
   - `is_verified_purchase`: `Boolean` (True).
   - `helpful_count`: `Integer`.

---

### 5. Final Entity/ID Mapping

All primary keys are explicitly locked to match frontend models and test expectations:

| Domain | Entity | Locked Primary Keys |
|---|---|---|
| **Mechanics** | Categories | `cat_general`, `cat_breakdown`, `cat_battery`, `cat_tyre`, `cat_engine`, `cat_brake`, `cat_electrical`, `cat_towing` |
| | Services | `svc_1`, `svc_2`, `svc_3`, `svc_4`, `svc_5`, `svc_6`, `svc_7`, `svc_8` |
| | Mechanics | `m1`, `m2`, `m3`, `m4`, `m5`, `m6`, `m7`, `m8` |
| | Reviews | `r1`, `r2`, `r3`, `r4`, `r5`, `r6`, `r7`, `r8`, `r9`, `r10`, `r11`, `r12` |
| **Fuel** | Partners | `partner_1`, `partner_2`, `partner_3`, `partner_4` |
| | Stations | `station_1`, `station_2`, `station_3`, `station_4`, `station_5`, `station_6` |
| **Marketplace** | Categories | `engine-parts`, `brake-system`, `oils`, `tyres`, `batteries`, `accessories`, `cleaning`, `lights` |
| | Brands | `bosch`, `tvs`, `rolon`, `ngk`, `castrol`, `motul`, `mrf`, `ceat`, `exide`, `amaron`, `3m`, `philips` |
| | Offers | `offer-brake`, `offer-tyre`, `offer-oil` |
| | Coupons | `coupon-mecha10`, `coupon-mecha20`, `coupon-freeship` (Codes: `MECHA10`, `MECHA20`, `FREESHIP`) |
| | Products | `p-chain-kit`, `p-spark-plug`, `p-brake-pad`, `p-brake-shoe`, `p-engine-oil-10w40`, `p-engine-oil-5w30`, `p-brake-fluid`, `p-tyre-rear`, `p-tyre-car`, `p-battery-bike`, `p-battery-car`, `p-puncture-kit`, `p-tire-inflator`, `p-car-shampoo`, `p-microfiber`, `p-headlight-h4`, `p-horn-set`, `p-wiper-blades` |

---

### 6. Seed Data Ownership Strategy

* **Concept**: All pilot catalog records belong to the **Platform Catalog Namespace**.
* **Distinction Mechanism**:
  - Catalog entities do not carry a `user_id` column by design (they are public catalog data, not user-owned resources).
  - Seed records use the canonical, standardized identifier format (`m*`, `svc_*`, `station_*`, `p-*`, `cat_*`, `coupon-*`).
  - No user-created resources will ever use these reserved pilot identifiers.
  - Future live vendor onboarding / operator entries will use generated UUIDs or operational prefix conventions.

---

### 7. Idempotency Strategy

To ensure safe repeated execution without side effects:
1. **Parent Tables (Text PK)**:
   - Evaluated via `pg_insert(Model).on_conflict_do_update(...)` mapping non-key fields (e.g. updating pricing, availability, ratings) or `on_conflict_do_nothing()`.
   - Running the script a second time executes cleanly and reports `0 rows added, X rows refreshed`.
2. **Composite-Key Tables**:
   - `(mechanic_id, skill)`, `(mechanic_id, language)`, `(mechanic_id, day)`, `(mechanic_id, service_id)`, `(product_id, vehicle_type)`, `(product_id, compatible_with)`.
   - Evaluated via `pg_insert(Model).on_conflict_do_nothing(index_elements=[col1, col2])`.
3. **UUID Child Tables**:
   - `product_specifications`: `id = uuid.uuid5(uuid.NAMESPACE_DNS, f"{product_id}:spec:{sort_order}")`.
   - `product_reviews`: `id = uuid.uuid5(uuid.NAMESPACE_DNS, f"{product_id}:rev:{author}")`.
   - Using deterministic UUIDv5 guarantees that child rows retain identical primary keys across multiple runs, preventing row duplication on rerun.

---

### 8. PostgreSQL Upsert Strategy

All writes will be constructed using SQLAlchemy's PostgreSQL dialect builder:
```python
from sqlalchemy.dialects.postgresql import insert as pg_insert

stmt = (
    pg_insert(Mechanic)
    .values(...)
    .on_conflict_do_update(
        index_elements=[Mechanic.id],
        set_={
            "name": stmt.excluded.name,
            "rating": stmt.excluded.rating,
            "price_starting": stmt.excluded.price_starting,
            "is_available": stmt.excluded.is_available,
            ...
        }
    )
)
await session.execute(stmt)
```
This guarantees race-condition immunity, deterministic updates, and complete avoidance of `IntegrityError: duplicate key value violates unique constraint`.

---

### 9. Transaction Strategy

* **Atomicity**: The entire seeding operation executes in **one single asynchronous transaction** (`async with session.begin():`).
* **Failure Isolation**: If any error or constraint violation occurs at any point during the run, the transaction automatically rolls back.
* **Zero Partial State**: The database will either contain the full, validated pilot catalog or remain in its previous state. No half-populated catalogs will ever be committed.

---

### 10. Foreign-Key Insert Order (Topological Dependency Sequence)

The script must execute insertions in strict dependency order:

```
Step 1:  mechanic_categories   (Independent lookup)
Step 2:  mechanic_services     (Independent catalog)
Step 3:  fuel_stations         (Independent partner bunks)
Step 4:  fuel_partners         (Independent drivers)
Step 5:  categories            (Independent marketplace categories)
Step 6:  brands                (Independent manufacturer brands)
Step 7:  coupons               (Independent promo codes)
Step 8:  mechanics             (Independent garage profiles)
Step 9:  mechanic_skills       (FK -> mechanics)
Step 10: mechanic_languages    (FK -> mechanics)
Step 11: mechanic_working_hours(FK -> mechanics)
Step 12: mechanic_service_offered (FK -> mechanics, mechanic_services)
Step 13: mechanic_reviews      (FK -> mechanics)
Step 14: offers                (FK -> categories)
Step 15: products              (FK -> categories, brands)
Step 16: product_specifications(FK -> products)
Step 17: product_vehicle_types (FK -> products)
Step 18: product_compatibility (FK -> products)
Step 19: product_reviews       (FK -> products)
```

---

### 11. Data Validation Rules

Before constructing SQL values, the seeder will validate:
1. **Prices and MRP**: `price > 0`, `mrp >= price` (preventing negative discounts).
2. **Ratings and Counts**: `0.0 <= rating <= 5.0`, `review_count >= 0`.
3. **Availability Constraints**:
   - `fuel_stations.availability in ('available', 'low', 'outOfStock')`.
   - `coupons.type in ('percent', 'freeDelivery')`.
4. **Coordinates**:
   - `12.85 <= latitude <= 13.15` (Bengaluru metropolitan boundaries).
   - `77.45 <= longitude <= 77.75`.
5. **Stock Counts**: `stock >= 10` (ensuring products render with in-stock CTA).

---

### 12. Pilot Geography

* **Metropolitan Center**: Bengaluru (Bangalore), Karnataka, India.
* **Anchor Point**: `12.9716, 77.5946` (Vidhana Soudha / MG Road).
* **Locality Distribution**:
  - Central: MG Road, Brigade Road, Richmond Town (`12.9716, 77.5946`)
  - East: Indiranagar, Halasuru (`12.9784, 77.6408`), Whitefield (`12.9698, 77.7500`)
  - South: Koramangala (`12.9352, 77.6245`), HSR Layout (`12.9121, 77.6446`), Jayanagar (`12.9308, 77.5838`)
  - North: Hebbal, Outer Ring Road (`13.0358, 77.5970`)

---

### 13. Image / Asset Strategy

* **Product Images**: Product rows will use paths referencing the 18 bundled PNG/JPG assets in `frontend/assets/`:
  - `p-chain-kit` -> `assets/chain kit.png`
  - `p-spark-plug` -> `assets/spark plugs.png`
  - `p-brake-pad` -> `assets/break pads.png`
  - `p-engine-oil-10w40` -> `assets/engine oil.png`
  - `p-tyre-rear` -> `assets/bike tyre.jpg`
  - `p-battery-bike` -> `assets/battery.png`
  - `p-puncture-kit` -> `assets/tool kit.png`
  - `p-tire-inflator` -> `assets/tool kit.png`
  - `p-wiper-blades` -> `assets/wipers.png`
* **Zero Remote Image Risk**: By using local bundled assets, products render immediately on Android without network latency, broken URLs, or certificate errors. Missing or null paths trigger `ProductImage._iconFallback()` automatically.

---

### 14. API Contract Requirements

The seed dataset guarantees 100% contract compliance for:
* `GET /api/v1/mechanic/mechanics`: Returns list with nested `skills`, `languages`, `working_hours`, and `services`.
* `GET /api/v1/mechanic/mechanics/featured`: Returns `m4` (4.9★), `m1` (4.8★), `m5` (4.7★).
* `GET /api/v1/fuel/stations`: Returns 6 bunks with distance, ETA, price per litre, and availability.
* `GET /api/v1/marketplace/products`: Returns 18 items with brand name, category name, specifications, and compatibility.
* `GET /api/v1/marketplace/coupons`: Returns active coupons with valid discount parameters.

---

### 15. Flutter Contract Requirements

* **Nearby Mechanics**: Renders verified checkmarks, ratings, and active "Book Service" CTA.
* **Fuel Booking**: Allows station selection, litre quantity selection, and price breakdown calculation.
* **Marketplace Grid**: Displays discount percentages, brand pills, and "Add to Cart" functionality.
* **Unified Orders**: Cleanly renders past and new orders without empty catalog errors.

---

### 16. Production Safety Boundaries

```
ALLOWED SEED TARGETS (Catalog DML):
  ✅ mechanic_categories
  ✅ mechanic_services
  ✅ mechanics
  ✅ mechanic_skills
  ✅ mechanic_languages
  ✅ mechanic_working_hours
  ✅ mechanic_service_offered
  ✅ mechanic_reviews
  ✅ fuel_partners
  ✅ fuel_stations
  ✅ categories
  ✅ brands
  ✅ offers
  ✅ coupons
  ✅ products
  ✅ product_specifications
  ✅ product_vehicle_types
  ✅ product_compatibility
  ✅ product_reviews

STRICTLY FORBIDDEN TARGETS (User & Transactional Tables):
  ❌ users                (33 user accounts preserved)
  ❌ refresh_tokens       (71 active tokens preserved)
  ❌ vehicles             (5 registered customer vehicles preserved)
  ❌ addresses            (2 customer delivery addresses preserved)
  ❌ wallet               (7 customer wallets preserved)
  ❌ wallet_transactions  (2 wallet transactions preserved)
  ❌ reward_ledger        (Customer rewards preserved)
  ❌ notification_settings(3 customer preferences preserved)
  ❌ conversations        (11 AI chat sessions preserved)
  ❌ chat_messages        (18 chat turns preserved)
  ❌ diagnoses            (Saved vehicle diagnostic runs preserved)
  ❌ order_entries        (7 unified order feed items preserved)
  ❌ orders               (5 marketplace customer orders preserved)
  ❌ order_items          (5 order line items preserved)
  ❌ fuel_orders          (7 fuel delivery orders preserved)
  ❌ invoices             (Customer invoices preserved)
  ❌ mechanic_bookings    (Customer mechanic bookings preserved)
  ❌ booking_events       (Customer lifecycle events preserved)
  ❌ ratings              (Customer ratings preserved)
```

---

### 17. Failure Handling

1. **Missing `DATABASE_URL`**: Immediately exits with code 1 and helpful configuration error.
2. **Database Connection Failure**: Catches connection error, prints diagnostic message (with masked credentials), exits with code 2.
3. **Constraint or Validation Failure**: Automatically triggers `await session.rollback()`, logs the offending entity and constraint, and exits with code 3.
4. **Zero Partial Population**: Atomic single-transaction boundary guarantees the database is never left in an inconsistent state.

---

### 18. Logging / Observability

The seeder CLI output will provide clear, structured progress reporting:
```text
============================================================
MECHA CONNECT — PILOT CATALOG SEEDER
============================================================
Database: aws-0-ap-northeast-2.pooler.supabase.com:5432/postgres
Pilot Geography: Bengaluru, Karnataka (12.9716, 77.5946)
------------------------------------------------------------
[1/19] Seeding mechanic_categories ... 8 rows upserted.
[2/19] Seeding mechanic_services ... 8 rows upserted.
[3/19] Seeding fuel_stations ... 6 rows upserted.
[4/19] Seeding fuel_partners ... 4 rows upserted.
[5/19] Seeding categories ... 8 rows upserted.
[6/19] Seeding brands ... 10 rows upserted.
[7/19] Seeding coupons ... 3 rows upserted.
[8/19] Seeding mechanics ... 8 rows upserted.
[9/19] Seeding mechanic_skills ... 32 rows upserted.
[10/19] Seeding mechanic_languages ... 24 rows upserted.
[11/19] Seeding mechanic_working_hours ... 24 rows upserted.
[12/19] Seeding mechanic_service_offered ... 40 rows upserted.
[13/19] Seeding mechanic_reviews ... 12 rows upserted.
[14/19] Seeding offers ... 3 rows upserted.
[15/19] Seeding products ... 18 rows upserted.
[16/19] Seeding product_specifications ... 54 rows upserted.
[17/19] Seeding product_vehicle_types ... 36 rows upserted.
[18/19] Seeding product_compatibility ... 45 rows upserted.
[19/19] Seeding product_reviews ... 18 rows upserted.
------------------------------------------------------------
COMMITTING TRANSACTION ...
SUCCESS: Pilot catalog successfully seeded and verified.
============================================================
```
* Passwords, secrets, and sensitive tokens are strictly excluded from all logs.

---

### 19. Testing Strategy

1. **Execution Verification**:
   - Run seeder against live Supabase.
   - Run seeder a second time: Confirm execution succeeds with zero row inflation (idempotency verified).
2. **API Contract Verification**:
   - Query `/api/v1/mechanic/mechanics`, `/api/v1/fuel/stations`, `/api/v1/marketplace/products` and assert populated JSON responses.
3. **Automated Suite Regression**:
   - Run `.\venv\Scripts\python.exe -m pytest tests` (assert 700/700 pass).
   - Run `flutter analyze` (assert 0 issues).
   - Run `flutter test` (assert 238/238 pass).

---

### 20. Manual Android Verification Strategy

1. **Mechanic Discovery Flow**:
   - Launch app on Android emulator (`emulator-5554`).
   - Navigate to "Find Mechanic": Verify cards appear with ratings, distance, and verified badges.
   - Select "Rajesh Auto Garage": Verify services offered, languages, bio, and reviews are visible.
2. **Fuel Delivery Flow**:
   - Navigate to "Fuel Delivery": Verify Indian Oil, Shell, and BPCL stations render with price per litre.
   - Proceed to quantity estimate: Verify pricing calculations work with real station rates.
3. **Marketplace Flow**:
   - Navigate to "Marketplace": Verify horizontal categories scroll, offers banner renders, and products grid shows items with MRP discounts and stock badges.
   - Tap "Rolon Chain Sprocket Kit": Verify specifications and vehicle compatibility tables render without overflow.

---

### 21. Files To Create

* **`backend/scripts/seed_pilot_catalog.py`** [NEW]: The self-contained, idempotent, asynchronous pilot catalog seeder script.

---

### 22. Files That May Need Modification

* **None.** All domain models, routers, repositories, and UI widgets are already built and tested to handle these datasets.

---

### 23. Files That Must Remain Untouched

* `backend/alembic/versions/*` — No migration modifications.
* `backend/app/core/security.py` & `backend/app/api/v1/auth.py` — Authentication is locked.
* `backend/app/models/*` — All ORM models are locked.
* `frontend/lib/*` — Frontend application code is locked.

---

### 24. Risks & Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| **Accidental data wipe** | Critical | Seeder uses only `INSERT ... ON CONFLICT`. Zero `DELETE` or `TRUNCATE` calls exist in the codebase. |
| **Duplicate key on rerun** | High | PostgreSQL `on_conflict_do_update` / `on_conflict_do_nothing` handles repeated runs gracefully. |
| **Invalid Enum / Check Constraint** | High | All values are checked against model constraints (`ck_fuel_stations_availability`, `ck_coupons_type`). |
| **Foreign Key ordering failure** | Medium | Insertion follows strict topological dependency graph. |

---

### 25. Acceptance Criteria

1. `backend/scripts/seed_pilot_catalog.py` executes with exit code 0.
2. Second execution executes with exit code 0 and identical row counts.
3. Catalog table counts in Supabase reflect:
   - `mechanics` >= 8, `mechanic_services` >= 8, `mechanic_categories` >= 8
   - `fuel_stations` >= 6, `fuel_partners` >= 4
   - `categories` >= 8, `brands` >= 10, `products` >= 18, `coupons` >= 3
4. Existing 33 user records, 7 wallets, 7 unified order entries, and 5 vehicles remain untouched.
5. All 700 backend tests and 238 Flutter tests remain green.
6. Android emulator displays populated catalog cards on Nearby Mechanics, Fuel Delivery, and Marketplace screens.

---

### 26. Exact Implementation Sequence (for Step 2)

1. **Step 2A**: Create `backend/scripts/seed_pilot_catalog.py` containing:
   - Pilot dataset dictionaries for all 19 tables.
   - Deterministic UUIDv5 generator for child tables.
   - Topological async insert logic with `pg_insert` and conflict handling.
   - Clean logging and error management.
2. **Step 2B**: Execute seeder against live Supabase.
3. **Step 2C**: Execute seeder a second time to verify idempotency.
4. **Step 2D**: Verify API catalog responses via HTTP.
5. **Step 2E**: Run full regression test suites (pytest + flutter test + analyze).
6. **Step 2F**: Launch Android emulator and perform live manual verification of the three catalog journeys.

---

### 27. CEO / CTO Recommendation

**Architecture Decisions are COMPLETE, LOCKED, and APPROVED.**  
Proceed immediately to **STEP 2 — FULL IMPLEMENTATION** upon executive sign-off.
