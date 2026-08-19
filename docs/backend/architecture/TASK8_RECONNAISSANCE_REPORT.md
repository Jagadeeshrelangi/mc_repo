# Task 8 Reconnaissance Report: Fuel Delivery & Marketplace

**Author**: Lead QA + Full-Stack Architect  
**Date**: 2026-08-19  
**Repository**: Mecha Connect (Sprint 2)  
**Status**: **RECONNAISSANCE ONLY — NO CODE MODIFIED**

---

## 1. Executive Summary

Task 7 established the connected core application across Authentication, User Profile, AI Diagnosis, AI Chat with multi-turn memory, and Mechanics Catalog with owner-scoped Booking. 

Two prominent user-facing domains remain entirely client-side:
1. **Fuel Delivery** (`features/fuel_delivery`): 5-step order builder, station selection, price estimation, simulated partner assignment, and invoice generation.
2. **Marketplace & Cart** (`features/marketplace` + `bottom_bar/order_screen`): Catalog browsing, filtering, cart management, checkout sheet, and shared order tab entries.

This reconnaissance thoroughly audits the current Flutter code, existing schema blueprints, database models, API structures, security implications, and contracts to provide a concrete, step-by-step roadmap for Task 8 backend implementation and frontend integration.

---

## 2. What Is What — Architecture Explanation

| Concept | Role in Mecha Connect |
|---|---|
| **Flutter Frontend** | Cross-platform UI application (Android/iOS/Web/Desktop) managing user interactions, state via `ChangeNotifierProvider`, and routing. |
| **FastAPI Backend** | Python asynchronous web framework serving REST endpoints under `/api/v1/*`, performing authentication, intent orchestration, and data validation. |
| **PostgreSQL** | Target relational database for durable storage of users, tokens, diagnoses, conversations, mechanics, bookings, orders, and products. |
| **schema.sql** | Historical DDL blueprint (`docs/backend/database/schema.sql`) defining the canonical table schemas and relationships for Sprint 2. |
| **Alembic Migrations** | Python migration scripts (`backend/alembic/versions/`) providing deterministic, incremental version control for database schemas. |
| **SQLAlchemy ORM Models** | Declarative Python classes (`backend/app/models/`) mapping relational tables to object properties with typed columns and relationships. |
| **Repositories** | Data-access layer (`backend/app/repositories/`) encapsulating database CRUD operations, query filters, and session handling. |
| **Business Services** | Domain logic orchestrators (`backend/app/services/`) enforcing business rules, access control, calculations, and transactional boundaries. |
| **API Routers** | FastAPI route definitions (`backend/app/api/v1/`) binding HTTP verbs/paths to request schemas, dependency injection, and service invocations. |
| **In-Memory Mock State** | Ephemeral client-side stores (`FuelRepository`, `MarketplaceRepository`, `ordersList` in `parts/order_data.dart`) used during prototype stages. |

---

## 3. Current Repository State

- **Connected & Verified Backend APIs**:
  - Auth (`/api/v1/auth/*`)
  - Users (`/api/v1/users/me`)
  - AI Diagnosis (`/api/v1/diagnosis/*`)
  - AI Conversation (`/api/v1/conversation/*`)
  - Mechanics & Bookings (`/api/v1/mechanic/*`)
- **Frontend-Only Features**:
  - Fuel Delivery (`frontend/lib/features/fuel_delivery/`)
  - Marketplace (`frontend/lib/features/marketplace/`)
  - Shared Orders List (`frontend/lib/parts/order_data.dart`)
- **Current Database Status**:
  - `LIVE POSTGRESQL: BLOCKED — DATABASE CREDENTIALS/INSTANCE REQUIRED` (no active database on port 5432, no Docker daemon, no `DATABASE_URL` in `.env`).

---

## 4. Fuel Delivery Audit

### Feature Matrix
| Feature | UI (`screens/`) | State (`providers/`) | Repository (`repositories/`) | Backend (`api/v1/`) | Database (ORM) | Status |
|---|---|---|---|---|---|---|
| **Fuel Type Selection** | `FuelBookingScreen` | `FuelProvider` | `FuelRepository.getFuelTypes()` | None | None | **FRONTEND ONLY** |
| **Station Discovery** | `FuelBookingScreen` | `FuelProvider` | `FuelRepository.getFuelStations()` | None | None | **FRONTEND ONLY** |
| **Vehicle Selection** | `FuelBookingScreen` | `FuelProvider` | `FuelRepository.getSavedVehicles()` | None | None | **FRONTEND ONLY** |
| **Price Estimation** | `PriceBreakdownCard` | `FuelProvider` | `FuelService.calculatePrice()` | None | None | **FRONTEND ONLY** |
| **Order Placement** | `FuelBookingScreen` | `FuelProvider` | `FuelRepository.createOrder()` | None | None | **FRONTEND ONLY** |
| **Status Progression** | `FuelTrackingScreen` | `FuelProvider` | `FuelRepository.advanceStatus()` | None | None | **FRONTEND ONLY** |
| **Order Cancellation** | `FuelTrackingScreen` | `FuelProvider` | `FuelRepository.cancelOrder()` | None | None | **FRONTEND ONLY** |
| **Invoice Generation** | `FuelTrackingScreen` | `FuelProvider` | `FuelRepository.generateInvoice()` | None | None | **FRONTEND ONLY** |
| **Order History** | `FuelHistoryScreen` | `FuelProvider` | `FuelRepository.getOrderHistory()` | None | None | **FRONTEND ONLY** |

---

## 5. Marketplace Audit

### Feature Matrix
| Feature | UI (`screens/`) | State (`providers/`) | Repository (`repositories/`) | Backend (`api/v1/`) | Database (ORM) | Status |
|---|---|---|---|---|---|---|
| **Category Browsing** | `CategoryProductsScreen` | `MarketplaceProvider` | `MarketplaceRepository.getCategories()` | None | None | **FRONTEND ONLY** |
| **Product Discovery** | `MarketplaceHomeScreen` | `MarketplaceProvider` | `MarketplaceRepository.getProducts()` | None | None | **FRONTEND ONLY** |
| **Product Details** | `ProductDetailScreen` | `MarketplaceProvider` | `MarketplaceRepository.getProductById()` | None | None | **FRONTEND ONLY** |
| **Cart Operations** | `CartScreen` | `MarketplaceProvider` | `MarketplaceRepository.getCart()` | None | None | **FRONTEND ONLY** |
| **Coupons / Discounts**| `CartScreen` | `MarketplaceProvider` | `MarketplaceRepository.applyCoupon()` | None | None | **FRONTEND ONLY** |
| **Checkout & Address** | `CheckoutScreen` | `MarketplaceProvider` | `MarketplaceRepository.createOrder()` | None | None | **FRONTEND ONLY** |
| **Order History** | `OrderHistoryScreen` | `MarketplaceProvider` | `MarketplaceRepository.getOrders()` | None | None | **FRONTEND ONLY** |
| **Global Orders Tab** | `Orderscreen` | `orderStore` | `ordersList` in `parts/order_data.dart` | None | None | **FRONTEND ONLY** |

---

## 6. Existing vs. Missing Database Components

### Existing SQLAlchemy Models & Alembic Migrations
- `users`, `refresh_tokens` (Migration `0002_authentication_foundation.py`)
- `conversations`, `chat_messages` (Migration `0003_conversation_ownership.py`)
- `diagnoses` (Model `app/models/diagnosis.py`)
- `mechanics`, `mechanic_services`, `mechanic_service_offered`, `mechanic_categories`, `mechanic_skills`, `mechanic_languages`, `mechanic_working_hours`, `mechanic_reviews`, `mechanic_bookings` (Migration `0004_mechanics.py`)

### Missing Database Components (To Be Built in Task 8)
1. **Fuel Delivery**:
   - `fuel_stations` (Catalog of partner pumps, pricing, availability)
   - `fuel_partners` (Delivery riders)
   - `fuel_orders` (Owner-scoped fuel requests)
   - `price_estimates` / `fuel_order_pricing` (Snapshot of fuel cost, delivery fee, taxes)
   - `fuel_invoices` (Settlement record)
   - `fuel_tracking_events` (Status logs)
2. **Marketplace & Orders**:
   - `categories` & `brands` (Marketplace taxonomy)
   - `products` (Catalog with stock, prices, MRP, ratings)
   - `product_specifications`, `product_vehicle_types`, `product_compatibility`
   - `coupons` / `offers` (Promotional discounts)
   - `marketplace_orders` & `marketplace_order_items` (Order snapshot with pricing immutability)
   - `order_entries` (Unified multi-domain order history view)

---

## 7. Proposed Data Model

```
[users] (id, name, email, phone)
  ├── 1:N ──> [fuel_orders] (id, user_id, fuel_type, quantity, status, station_id, vehicle_name, delivery_address, total_price, created_at)
  │             ├── 1:1 ──> [fuel_invoices] (id, fuel_order_id, fuel_cost, delivery_charge, taxes, grand_total)
  │             └── 1:N ──> [fuel_tracking_events] (id, fuel_order_id, status, lat, lng, eta_minutes, occurred_at)
  │
  ├── 1:N ──> [marketplace_orders] (id, user_id, status, subtotal, discount, delivery_fee, tax, grand_total, address, payment_method, created_at)
  │             └── 1:N ──> [marketplace_order_items] (id, order_id, product_id, product_name, brand, unit_price, quantity, line_total)
  │
  └── 1:N ──> [order_entries] (id, user_id, title, subtitle, amount, type, status, ref_id, occurred_at)
```

---

## 8. Proposed API Architecture

### Fuel Delivery Router (`/api/v1/fuel`)
1. `GET /api/v1/fuel/types` (Public / Authenticated: Returns supported fuel types and base rates)
2. `GET /api/v1/fuel/stations?lat={lat}&lng={lng}` (Returns nearby pumps with live availability)
3. `POST /api/v1/fuel/estimate` (Calculates dynamic quote: fuel cost + delivery charge + tax)
4. `POST /api/v1/fuel/orders` (Auth required: Creates fuel order bound to `user.id`)
5. `GET /api/v1/fuel/orders` (Auth required: Lists user's fuel orders)
6. `GET /api/v1/fuel/orders/{id}` (Auth required: Retrieves order tracking & status)
7. `POST /api/v1/fuel/orders/{id}/cancel` (Auth required: Owner-scoped cancellation)

### Marketplace Router (`/api/v1/marketplace`)
1. `GET /api/v1/marketplace/categories` (Returns browse categories)
2. `GET /api/v1/marketplace/products?category_id={id}&search={q}&page={p}` (Paginated product listing with filters)
3. `GET /api/v1/marketplace/products/{id}` (Product details, specs, compatibility, reviews)
4. `POST /api/v1/marketplace/coupons/validate` (Validates discount coupon against cart total)
5. `POST /api/v1/marketplace/orders` (Auth required: Converts cart into immutable order)
6. `GET /api/v1/marketplace/orders` (Auth required: Returns user's order history)
7. `GET /api/v1/marketplace/orders/{id}` (Auth required: Order details & line items)
8. `POST /api/v1/marketplace/orders/{id}/cancel` (Auth required: Owner-scoped order cancellation)

---

## 9. Flutter ↔ Backend Contract Analysis

| Domain | Frontend Model | Backend Pydantic Schema | Potential Mismatch & Reconciliation Strategy |
|---|---|---|---|
| **Fuel Station** | `FuelStation(distanceKm, pricePerLitre, availability)` | `FuelStationOut(distance_km, price_per_litre, availability)` | Convert snake_case JSON directly using `fromJson` factory. Map enum `available|low|outOfStock`. |
| **Fuel Order** | `FuelOrder(fuelType, priceEstimate, status)` | `FuelOrderOut(fuel_type, price_estimate, status)` | `priceEstimate` must serialize as nested JSON matching `PriceEstimate` model. |
| **Product** | `Product(mrp, price, vehicleTypes, specifications)` | `ProductOut(mrp, price, vehicle_types, specifications)` | `vehicle_types` must serialize as `List[str]`; `specifications` as `List[{"label": str, "value": str}]`. |
| **Marketplace Order** | `MarketplaceOrder(item, total, address)` | `MarketplaceOrderOut(items, grand_total, address)` | Support multi-item orders in backend while Flutter allows 1-to-1 line item display. |
| **Shared Orders** | `ordersList` in `parts/order_data.dart` | `OrderEntryOut(id, type, name, brand, price, quantity, status, date)` | Create a unified `GET /api/v1/users/me/orders` endpoint aggregating parts, fuel, mechanic, and AI reports. |

---

## 10. Security & Threat Modeling

1. **Client Price Manipulation**:
   - *Risk*: Client modifies `unitPrice` or `total` in request body.
   - *Defense*: Backend calculates all totals by querying database `products.price` and `fuel_stations.price_per_litre`. Client totals are ignored.
2. **IDOR & Foreign Order Tampering**:
   - *Risk*: Attendant/User modifies `order_id` in cancellation or status check URL.
   - *Defense*: All queries enforce `WHERE user_id = current_user.id`. Foreign IDs return `404 Not Found`.
3. **Inventory Race Conditions**:
   - *Risk*: Multiple users buy the last stock unit simultaneously.
   - *Defense*: Use `SELECT ... FOR UPDATE` row locks on `products` during checkout inside a single atomic transaction.
4. **Mass Assignment**:
   - *Risk*: Client sets `status = 'Delivered'` during order creation.
   - *Defense*: Order status is initialized exclusively to `Requested`/`Pending` by backend service logic.

---

## 11. Performance & Scalability Considerations

- **Spatial Proximity**: Fuel station distance queries should use PostGIS or Euclidean/Haversine bounding box indexing in PostgreSQL.
- **Product Search & Filtering**: Add B-tree indexes on `products(category_id)`, `products(brand_id)`, and trigram index on `products(name)`.
- **Order Immutability**: Store complete price and name snapshots in `order_items` so future product catalog updates do not alter historical invoices.

---

## 12. PostgreSQL Provisioning Status

- **Status**: **LIVE POSTGRESQL: BLOCKED — DATABASE CREDENTIALS/INSTANCE REQUIRED**
- **Action Required**: The developer/user needs to supply a working `DATABASE_URL` in `backend/.env` or start a local PostgreSQL service on port `5432`.

---

## 13. Proposed Task 8 Implementation Stages

| Stage | Title | Focus & Deliverables |
|---|---|---|
| **Stage 1** | **Data Models & Migrations** | Implement SQLAlchemy models for Fuel & Marketplace (`app/models/fuel.py`, `app/models/marketplace.py`) and generate Alembic migrations. |
| **Stage 2** | **Fuel Delivery Backend** | Repositories, Services, and FastAPI router (`/api/v1/fuel/*`) with pricing engine and unit tests. |
| **Stage 3** | **Marketplace Backend** | Repositories, Services, and FastAPI router (`/api/v1/marketplace/*`) with catalog, cart checkout, and unit tests. |
| **Stage 4** | **Fuel Frontend Integration** | Wire `FuelRepository` to `ApiClient`, connect live station fetching, order placement, and tracking. |
| **Stage 5** | **Marketplace Frontend Integration** | Wire `MarketplaceRepository` to `ApiClient`, connect catalog browsing, search, and checkout. |
| **Stage 6** | **Unified Orders Tab Integration** | Connect `Orderscreen` (`bottom_bar/order_screen.dart`) to unified backend order endpoint. |
| **Stage 7** | **End-to-End Verification & Audit** | Full pytest suite, Flutter test suite, `flutter analyze`, and live runtime verification. |

---

## 14. Final Recommendation

Proceed with **Task 8 Stage 1 (Data Models & Alembic Migrations)** upon user approval. The architecture is cleanly decoupled, adheres to established Sprint 2 patterns, and ensures zero regressions in existing Task 7 features.
