# Testing — Mecha Connect (Backend)

> pytest strategy for the Sprint 2 backend. No backend tests exist at RC1
> (P0 gap); the scaffold's AI services are production-quality but untested.

## 1. Test Types

| Type | Tooling | Covers |
|---|---|---|
| Unit | pytest | services, repositories, schemas |
| Integration | pytest-asyncio | DB layer, repositories against PostgreSQL |
| API | httpx | endpoint contracts, status codes, error handling |
| Database | pytest-postgresql | migrations, schema constraints |

## 2. Coverage Gates

- **80%** minimum for all modules
- **100%** for auth and payment
- **90%** for AI services

## 3. Structure

```
backend/tests/
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

## 4. Frontend Verification Gate (RC1)

`flutter analyze` = 0 issues · `flutter test` = 162/162 (AI 25 · Fuel 37 ·
Marketplace 43 · Profile 30 · Mechanic 10 · Vehicle location 8 · Home 3 ·
Integration 2 · Widget 4). Module tests drive real providers over mock
repositories including failure injection; the runtime integration test uses the
exact production provider graph. See `docs/frontend/Testing.md`.

## 5. Sprint 2 Rules

- Add tests BEFORE refactoring the AI services (they will be touched for DB
  persistence).
- Minimum coverage enforced in CI; coverage thresholds part of the
  verification gate (see `docs/backend/Architecture.md` §9).
