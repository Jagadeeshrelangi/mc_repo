# Mecha Connect

Smart on-demand vehicle care & AI diagnostics — a **Flutter** mobile/web app
plus a **FastAPI** backend, shipped as a monorepo.

Mecha Connect connects drivers with verified mechanics, doorstep fuel
delivery, an auto-parts marketplace, and AI-driven vehicle diagnosis — all in
one app with real-time tracking.

![Platform: Android | iOS | Web](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-blue)
![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?logo=fastapi)

---

## Repository Layout

```text
mecha_connect/
├── frontend/    # Flutter application (lib/, android/, ios/, web/, test/)
├── backend/     # FastAPI service (app/, ai/, requirements.txt)
├── docs/        # Repository documentation (see docs/README.md)
├── scripts/     # Development / automation tooling
└── .github/     # CI workflow, issue & PR templates
```

- **Frontend** — see [frontend/README.md](frontend/README.md).
- **Backend** — see [backend/README.md](backend/README.md).
- **Documentation** — see [docs/README.md](docs/README.md).

## Local Development

### Frontend (Flutter)

```bash
cd frontend
flutter pub get
flutter analyze      # must be 0 issues
flutter test         # full unit + integration suite
flutter run -d chrome
```

### Backend (FastAPI)

```bash
cd backend
python -m venv venv
# activate venv, then:
pip install -r requirements.txt
uvicorn app.main:app --reload
```

See [docs/common/INSTALLATION.md](docs/common/INSTALLATION.md) for details.

## Backend Capabilities & Domain Status

The Mecha Connect backend is powered by FastAPI, SQLAlchemy async, and Supabase PostgreSQL.
- **Task 8 Stage 1 — Fuel Delivery & Marketplace Models & Schemas**:
  - **Fuel Domain**: 6 SQLAlchemy ORM models (`FuelOrder`, `PriceEstimate`, `FuelStation`, `FuelPartner`, `TrackingEvent`, `Invoice`) and corresponding Pydantic v2 schemas.
  - **Marketplace Domain**: 12 SQLAlchemy ORM models (`Category`, `Brand`, `Product`, `ProductSpecification`, `ProductVehicleType`, `ProductCompatibility`, `ProductReview`, `Offer`, `Coupon`, `Order`, `OrderItem`, `OrderEntry`) and corresponding Pydantic v2 schemas.
  - **Database Foundation**: 18 live PostgreSQL tables, 14 foreign keys, 32 indexes verified against live Supabase PostgreSQL (Alembic head `0006`).
  - **API Contract**: Pydantic v2 schemas integrated with OpenAPI components (80 schemas, `/health` database: ok).

## Documentation Index

- **[docs/README.md](docs/README.md)** — documentation map and reading order.
- **[docs/CANONICAL_DOCUMENT_MAP.md](docs/CANONICAL_DOCUMENT_MAP.md)** —
  single source of truth for every documentation topic.
- **[Security Policy](SECURITY.md)** — vulnerability reporting.
- **[Contributing](CONTRIBUTING.md)** — contribution guidelines.

## Security & Confidentiality

Do **not** commit secrets, credentials, API keys, certificates, or `.env`
files. Internal/business documentation is excluded from version control.
See [SECURITY.md](SECURITY.md) and [.gitignore](.gitignore).

## License

All Rights Reserved. See [LICENSE](LICENSE) and
[docs/common/LICENSE_GUIDE.md](docs/common/LICENSE_GUIDE.md).