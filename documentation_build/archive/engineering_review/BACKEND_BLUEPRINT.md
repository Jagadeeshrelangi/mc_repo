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

### 3.4 Order
```python
class Order(Base):
    id: UUID (PK)
    user_id: UUID (FK)
    type: Enum (mechanic, fuel, marketplace)
    status: Enum (pending, accepted, in_progress, completed, cancelled)
    total_amount: float
    payment_status: Enum (pending, paid, failed)
    created_at: datetime
    updated_at: datetime
```

### 3.5 Product
```python
class Product(Base):
    id: UUID (PK)
    name: str
    category: str
    price: float
    stock: int
    image_url: str
    created_at: datetime
    updated_at: datetime
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

### 5.1 Tables
- users
- vehicles
- mechanics
- orders
- order_items
- products
- categories
- addresses
- payments
- reviews
- conversations
- messages

### 5.2 Indexes
- users(email)
- users(phone)
- vehicles(user_id)
- mechanics(location)
- orders(user_id, status)
- products(category)

### 5.3 Constraints
- UUID primary keys
- Foreign key constraints
- Unique constraints
- Check constraints
- Soft delete (deleted_at IS NULL)

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