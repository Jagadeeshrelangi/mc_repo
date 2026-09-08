# Backend Blueprint — Mecha Connect

> **Sprint 2 Phase 1: Backend Audit & Architecture Freeze · 2026-08-05**
> Final backend architecture blueprint.

## 1. Architecture Overview

```
Flutter App
    │
    ▼
FastAPI API Gateway
    │
 ┌──┼──────────┐
 │  │          │
 ▼  ▼          ▼
Auth  Business   AI Engine
     Services

 │        │         │
 ▼        ▼         ▼
Repositories     RAG Engine

 │        │         │
 └────────┼─────────┘
          ▼
     PostgreSQL
          │
          ▼
        Redis
```

## 2. Layer Architecture

### 2.1 API Layer
- FastAPI routers (v1)
- Pydantic schemas for request/response
- Dependency injection for auth
- Rate limiting middleware

### 2.2 Service Layer
- Business logic
- AI orchestration
- External API calls
- Background job dispatch

### 2.3 Repository Layer
- SQLAlchemy async sessions
- Abstract base repository
- Concrete repositories per entity
- Soft delete support

### 2.4 Data Layer
- PostgreSQL 15 (primary)
- Redis (cache + session store)
- FAISS (vector search)
- File system (knowledge base)

## 3. Entity Model

### 3.1 User
```python
class User(Base):
    id: UUID (PK)
    email: str (unique)
    phone: str (unique, optional)
    name: str
    role: Enum (customer, mechanic, admin)
    is_verified: bool
    created_at: datetime
    updated_at: datetime
    deleted_at: datetime (nullable)
```

### 3.2 Vehicle
```python
class Vehicle(Base):
    id: UUID (PK)
    user_id: UUID (FK)
    make: str
    model: str
    year: int
    fuel_type: str
    license_plate: str
    created_at: datetime
    updated_at: datetime
```

### 3.3 Mechanic
```python
class Mechanic(Base):
    id: UUID (PK)
    user_id: UUID (FK)
    name: str
    rating: float
    specialties: list[str]
    is_available: bool
    location: Point
    created_at: datetime
    updated_at: datetime
```

### 3.4 Order & Activity
```python
class Order(Base):
    id: UUID (PK)
    user_id: UUID (FK -> users.id)
    external_id: str (unique)
    source_domain: str (mechanic, fuel, marketplace, etc.)
    domain_order_id: str
    order_type: str
    status: str (pending, confirmed, in_progress, completed, cancelled)
    total_amount: Decimal (10, 2)
    currency: str (default 'INR')
    notes: Optional[str]
    created_at: datetime (timezone-aware)
    updated_at: datetime (timezone-aware)
```

### 3.5 Fuel Delivery Domain Models

```python
class FuelOrder(Base):
    id: UUID (PK)
    user_id: UUID (FK -> users.id)
    fuel_type: str (petrol, diesel, cng, etc.)
    quantity_litres: Decimal (10, 2)
    unit_price: Decimal (10, 2)
    total_amount: Decimal (10, 2)
    delivery_latitude: Decimal (10, 7)
    delivery_longitude: Decimal (10, 7)
    delivery_address: str
    vehicle_registration: Optional[str]
    time_slot: Optional[str]
    contact_phone: Optional[str]
    payment_method: Optional[str]
    status: str (pending, assigned, in_transit, completed, cancelled)
    assigned_partner_id: Optional[UUID]
    created_at: datetime (timezone-aware)
    updated_at: datetime (timezone-aware)

class PriceEstimate(Base):
    id: UUID (PK)
    fuel_order_id: UUID (FK -> fuel_orders.id)
    base_fuel_cost: Decimal (10, 2)
    delivery_fee: Decimal (10, 2)
    tax_amount: Decimal (10, 2)
    total_estimated: Decimal (10, 2)
    created_at: datetime (timezone-aware)

class FuelStation(Base):
    id: UUID (PK)
    name: str
    brand: str
    latitude: Decimal (10, 7)
    longitude: Decimal (10, 7)
    address: str
    city: str
    state: str
    phone: Optional[str]
    is_active: bool
    created_at: datetime (timezone-aware)
    updated_at: datetime (timezone-aware)

class FuelPartner(Base):
    id: UUID (PK)
    user_id: Optional[UUID]
    company_name: str
    contact_name: str
    contact_phone: str
    service_radius_km: Decimal (5, 2)
    is_active: bool
    created_at: datetime (timezone-aware)
    updated_at: datetime (timezone-aware)

class TrackingEvent(Base):
    id: UUID (PK)
    order_id: UUID (FK -> fuel_orders.id)
    event_type: str
    latitude: Optional[Decimal (10, 7)]
    longitude: Optional[Decimal (10, 7)]
    description: Optional[str]
    event_time: datetime (timezone-aware)
    created_at: datetime (timezone-aware)

class Invoice(Base):
    id: UUID (PK)
    order_id: UUID (FK -> fuel_orders.id, unique)
    invoice_number: str
    subtotal: Decimal (10, 2)
    tax_rate: Decimal (5, 2)
    tax_amount: Decimal (10, 2)
    total: Decimal (10, 2)
    pdf_url: Optional[str]
    issued_at: datetime (timezone-aware)
    created_at: datetime (timezone-aware)
```

### 3.6 Marketplace Domain Models

```python
class Category(Base):
    id: UUID (PK)
    name: str
    description: Optional[str]
    image_url: Optional[str]

class Brand(Base):
    id: UUID (PK)
    name: str

class Product(Base):
    id: UUID (PK)
    category_id: UUID (FK -> categories.id)
    brand_id: UUID (FK -> brands.id)
    title: str
    sku: Optional[str]
    part_number: Optional[str]
    short_description: Optional[str]
    long_description: Optional[str]
    price: Decimal (10, 2)
    list_price: Optional[Decimal (10, 2)]
    in_stock: bool
    stock_quantity: int
    rating: Decimal (3, 2)
    reviews_count: int
    image_urls: list[str]
    created_at: datetime (timezone-aware)
    updated_at: datetime (timezone-aware)

class ProductSpecification(Base):
    id: UUID (PK)
    product_id: UUID (FK -> products.id)
    spec_key: str
    spec_value: str
    display_order: int

class ProductVehicleType(Base):
    product_id: UUID (PK, FK -> products.id)
    vehicle_type: str (PK)

class ProductCompatibility(Base):
    product_id: UUID (PK, FK -> products.id)
    make_model: str (PK)

class ProductReview(Base):
    id: UUID (PK)
    product_id: UUID (FK -> products.id)
    author_name: str
    rating: int (1..5)
    review_title: Optional[str]
    review_body: Optional[str]
    is_verified_purchase: bool
    created_at: datetime (timezone-aware)

class Offer(Base):
    id: UUID (PK)
    title: str
    banner_url: Optional[str]
    deeplink: Optional[str]
    badge_text: Optional[str]
    category_id: Optional[UUID] (FK -> categories.id)
    is_active: bool

class Coupon(Base):
    id: UUID (PK)
    code: str (unique)
    title: str
    description: Optional[str]
    discount_type: str (percentage, fixed)
    discount_value: Decimal (10, 2)
    min_order_amount: Optional[Decimal (10, 2)]
    max_discount_amount: Optional[Decimal (10, 2)]
    is_active: bool
    expires_at: Optional[datetime]

class OrderItem(Base):
    id: UUID (PK)
    order_id: UUID (FK -> orders.id)
    product_id: Optional[UUID]
    product_name: str
    unit_price: Decimal (10, 2)
    quantity: int
    line_total: Decimal (10, 2)
    image_url: Optional[str]
    created_at: datetime (timezone-aware)

class OrderEntry(Base):
    id: UUID (PK)
    user_id: UUID (FK -> users.id)
    status: str
    total_price: Decimal (10, 2)
    total_tax: Decimal (10, 2)
    subtotal: Decimal (10, 2)
    delivery_address: Optional[str]
    payment_method: Optional[str]
    created_at: datetime (timezone-aware)
    updated_at: datetime (timezone-aware)
```

## 4. API Endpoints

### 4.1 Auth (`/api/v1/auth/`)
| Method | Path | Description |
|---|---|---|
| POST | `/register` | Register new user |
| POST | `/login` | Login with email/phone |
| POST | `/refresh` | Refresh JWT token |
| POST | `/verify` | Verify account |
| POST | `/forgot-password` | Send reset link |
| POST | `/reset-password` | Reset password |

### 4.2 Users (`/api/v1/users/`)
| Method | Path | Description |
|---|---|---|
| GET | `/` | List users (admin) |
| GET | `/{id}` | Get user profile |
| PUT | `/{id}` | Update user profile |
| DELETE | `/{id}` | Delete user |

### 4.3 Vehicles (`/api/v1/vehicles/`)
| Method | Path | Description |
|---|---|---|
| GET | `/` | List user vehicles |
| POST | `/` | Add vehicle |
| GET | `/{id}` | Get vehicle |
| PUT | `/{id}` | Update vehicle |
| DELETE | `/{id}` | Delete vehicle |

### 4.4 Mechanics (`/api/v1/mechanics/`)
| Method | Path | Description |
|---|---|---|
| GET | `/` | List mechanics |
| GET | `/{id}` | Get mechanic profile |
| GET | `/nearby` | Find nearby mechanics |
| POST | `/{id}/book` | Book mechanic |

### 4.5 Fuel (`/api/v1/fuel/`)
| Method | Path | Description |
|---|---|---|
| GET | `/providers` | List fuel providers |
| POST | `/order` | Place fuel order |
| GET | `/order/{id}` | Track fuel order |

### 4.6 Marketplace (`/api/v1/marketplace/`)
| Method | Path | Description |
|---|---|---|
| GET | `/products` | List products |
| GET | `/products/{id}` | Get product |
| POST | `/order` | Place order |
| GET | `/order/{id}` | Track order |

### 4.7 Orders (`/api/v1/orders/`)
| Method | Path | Description |
|---|---|---|
| GET | `/` | List user orders |
| GET | `/{id}` | Get order details |
| PUT | `/{id}/cancel` | Cancel order |

### 4.8 AI (`/api/v1/ai/`)
| Method | Path | Description |
|---|---|---|
| POST | `/chat` | Chat with AI assistant |
| POST | `/diagnose` | Diagnose vehicle |
| POST | `/knowledge` | Query knowledge base |

## 5. Database Schema

### 5.1 Live Domain Tables (Supabase PostgreSQL)
- **Core / Auth / User**:
  - `users` — User profiles, credentials, role
  - `user_profiles` — Extended profile attributes
  - `vehicles` — Registered customer vehicles
  - `addresses` — Saved delivery/service addresses
- **Mechanics & Bookings**:
  - `mechanics` — Mechanic directory & credentials
  - `bookings` — Scheduled mechanic service bookings
- **Fuel Delivery Domain**:
  - `fuel_orders` — Fuel delivery requests & tracking status
  - `price_estimates` — Itemized price estimates per fuel order
  - `fuel_stations` — Fuel station locations & inventory metadata
  - `fuel_partners` — Verified fuel delivery partners
  - `tracking_events` — Real-time delivery status & coordinate telemetry
  - `invoices` — Tax invoices with subtotal, tax rate, and total amounts
- **Marketplace Domain**:
  - `categories` — Product taxonomy & navigation
  - `brands` — Manufacturer/brand entities
  - `products` — Auto-parts catalogue, pricing, and inventory
  - `product_specifications` — Key-value technical specifications
  - `product_vehicle_types` — Vehicle type association (Car, Bike, etc.)
  - `product_compatibility` — Specific make/model compatibility
  - `product_reviews` — Verified customer ratings & reviews
  - `offers` — Promotional banners & active campaigns
  - `coupons` — Discount codes, rules, and expiry
  - `orders` — Unified activity & cross-domain order records
  - `order_items` — Itemized line items per marketplace order
  - `order_entries` — Customer checkout entries & history
- **Wallet & Loyalty**:
  - `wallet_transactions` — Transaction ledgers & balances
  - `reward_points` — Reward points & loyalty ledgers
- **AI & Messaging**:
  - `conversations` — AI chat session lifecycle
  - `messages` — Chat message history
  - `diagnoses` — AI diagnostic runs & OBD analysis

### 5.2 Indexes & Performance Constraints
- **Primary Keys**: UUID v4 on all entities.
- **Foreign Keys**:
  - `fuel_orders.user_id` -> `users.id`
  - `invoices.order_id` -> `fuel_orders.id` (unique)
  - `price_estimates.fuel_order_id` -> `fuel_orders.id`
  - `tracking_events.order_id` -> `fuel_orders.id`
  - `products.category_id` -> `categories.id`
  - `products.brand_id` -> `brands.id`
  - `product_specifications.product_id` -> `products.id`
  - `product_vehicle_types.product_id` -> `products.id`
  - `product_compatibility.product_id` -> `products.id`
  - `product_reviews.product_id` -> `products.id`
  - `offers.category_id` -> `categories.id`
  - `orders.user_id` -> `users.id`
  - `order_items.order_id` -> `orders.id`
  - `order_entries.user_id` -> `users.id`
- **Performance Indexes (Alembic Head `0006`)**:
  - `ix_fuel_orders_user_id`, `ix_fuel_orders_status`
  - `ix_tracking_events_order_id`
  - `ix_products_category_id`, `ix_products_brand_id`
  - `ix_product_specifications_product_id`
  - `ix_product_reviews_product_id`
  - `ix_orders_user_id`, `ix_orders_status`
  - `ix_order_items_order_id`
  - `ix_order_entries_user_id`
  - `coupons_code_key` (unique)
  - `orders_external_id_key` (unique)
  - `invoices_order_id_key` (unique)

## 6. Security

### 6.1 Authentication
- JWT access tokens (15 min expiry)
- JWT refresh tokens (7 day expiry)
- bcrypt password hashing
- Email/phone verification

### 6.2 Authorization
- Role-based access control (RBAC)
- Customer, Mechanic, Admin roles
- Resource-level permissions

### 6.3 Security Headers
- X-Content-Type-Options: nosniff
- X-Frame-Options: DENY
- X-XSS-Protection: 1; mode=block
- Strict-Transport-Security
- Content-Security-Policy

### 6.4 Rate Limiting
- 100 requests/minute per IP
- 10 requests/minute for auth endpoints
- 60 requests/minute for AI endpoints

## 7. Caching Strategy

### 7.1 Redis Usage
- Session storage (JWT refresh tokens)
- Rate limiting counters
- Cache for frequently accessed data
- Background job queue (Celery)

### 7.2 Cache Keys
- `user:{id}` — User profile
- `mechanic:{id}` — Mechanic profile
- `products:{category}` — Product listings
- `nearby_mechanics:{lat}:{lng}` — Nearby mechanics

## 8. Background Jobs

### 8.1 Celery Tasks
- `send_email` — Send emails
- `send_notification` — Push notifications
- `process_payment` — Payment processing
- `update_order_status` — Order status updates
- `generate_invoice` — Invoice generation

### 8.2 Task Queue
- Redis as broker
- Redis as result backend
- Retry with exponential backoff
- Dead letter queue

## 9. Testing Strategy

### 9.1 Test Types
- Unit tests (pytest)
- Integration tests (pytest-asyncio)
- API tests (httpx)
- Database tests (pytest-postgresql)

### 9.2 Test Coverage
- 80% minimum for all modules
- 100% for auth and payment
- 90% for AI services

### 9.3 Test Structure
```
tests/
├── conftest.py
├── unit/
│   ├── test_auth.py
│   ├── test_users.py
│   ├── test_vehicles.py
│   └── test_mechanics.py
├── integration/
│   ├── test_orders.py
│   ├── test_marketplace.py
│   └── test_ai.py
└── api/
    ├── test_auth_endpoints.py
    ├── test_user_endpoints.py
    └── test_order_endpoints.py
```

## 10. Deployment

### 10.1 Docker
- Multi-stage Dockerfile
- Separate containers for app, db, redis
- Environment-specific configs

### 10.2 CI/CD
- GitHub Actions
- Automated testing
- Automated deployment to Railway/Render

### 10.3 Environment Variables
- DATABASE_URL
- REDIS_URL
- JWT_SECRET_KEY
- GEMINI_API_KEY
- FIREBASE_CREDENTIALS_PATH

## 11. Monitoring

### 11.1 Logging
- Structured JSON logs
- Request/response logging
- Error tracking
- Performance metrics

### 11.2 Health Checks
- `/health` — Basic health
- `/health/db` — Database connectivity
- `/health/redis` — Redis connectivity
- `/health/ai` — AI service status

## 12. Implementation Order

### Phase 1: Foundation (Week 1)
1. Database setup (SQLAlchemy, Alembic)
2. Authentication (JWT, bcrypt)
3. Repository pattern
4. Dependency injection
5. Security middleware

### Phase 2: Core APIs (Week 2)
1. User management
2. Vehicle management
3. Mechanic management
4. Orders API

### Phase 3: Business APIs (Week 3)
1. Fuel delivery
2. Marketplace
3. Payment integration

### Phase 4: AI Integration (Week 4)
1. Connect existing AI services to database
2. Add user context to AI responses
3. Add conversation history persistence

### Phase 5: Production (Week 5)
1. Dockerfile
2. CI/CD pipeline
3. Tests
4. Deployment configuration
</tool_call>