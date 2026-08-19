# Mecha Connect — Supabase PostgreSQL Database Setup Guide

**Architecture**: Mecha Connect utilizes Supabase exclusively for real **PostgreSQL Database Infrastructure & Observability Dashboard**.  
**Backend**: FastAPI handles all business logic, JWT authentication, and ML/LLM orchestration.  
**Frontend**: Flutter mobile, web, and desktop application.

---

## 1. System Architecture Overview

```
[Flutter Client]
       │
       ▼ (HTTP / Bearer JWT)
[FastAPI Backend Engine]
       ├── (Gemini API & XGBoost ML)
       │
       ▼ (SQLAlchemy 2.x Async / asyncpg)
[Supabase PostgreSQL Infrastructure]
       ├── users & refresh_tokens
       ├── conversations & chat_messages
       ├── diagnoses
       └── mechanics, services & bookings
```

* **Supabase** = Cloud PostgreSQL database, automatic backups, extensions (`uuid-ossp`, `pgcrypto`), and Table Editor.
* **FastAPI** = Monolithic REST API gateway, JWT issuance/validation, domain repositories, business services.
* **Flutter** = Presentation layer using `ApiClient` with automated Bearer token attachment and refresh interceptors.

---

## 2. Supabase Connection Configuration

Configure your database connection string in `backend/.env` (never commit this file).

### Direct Connection (Recommended for Alembic & FastAPI)
```env
# Session mode (Port 5432)
DATABASE_URL=postgresql+asyncpg://postgres.<project-ref>:<db-password>@aws-0-<region>.pooler.supabase.com:5432/postgres
```

### Connection Pooler (Supavisor Transaction Mode)
```env
# Transaction mode (Port 6543)
DATABASE_URL=postgresql+asyncpg://postgres.<project-ref>:<db-password>@aws-0-<region>.pooler.supabase.com:6543/postgres?statement_cache_size=0
```
> [!NOTE]
> When using Supavisor in Transaction Mode (port 6543), set `statement_cache_size=0` on `asyncpg` to prevent prepared statement cache collisions across multiplexed connections.

---

## 3. Applying Migrations with Alembic

Once `DATABASE_URL` is set in `backend/.env`, run the migration chain from the `backend/` directory:

```bash
# Check current migration status
alembic current

# Check pending migrations
alembic heads

# Apply all migrations to Supabase PostgreSQL
alembic upgrade head
```

### Migration Chain
1. `0001_baseline`: Migration chain root.
2. `0002_authentication_foundation`: Creates `users` and `refresh_tokens` tables.
3. `0003_conversation_ownership`: Creates `conversations` and `chat_messages` tables.
4. `0004_mechanics`: Creates `mechanics`, `mechanic_skills`, `mechanic_languages`, `mechanic_working_hours`, `mechanic_services`, `mechanic_service_offered`, `mechanic_categories`, `mechanic_reviews`, `mechanic_bookings`, `booking_events`, `ratings`.
5. `0005_diagnoses`: Creates `diagnoses` persistence table.

---

## 4. Database Observability in Supabase Dashboard

To inspect live data without SQL queries:
1. Open the [Supabase Dashboard](https://supabase.com/dashboard/project/_/editor).
2. Select your project: `djoygcystzpftckaduqp`.
3. In the left sidebar, click on **Table Editor** to view and search records:
   - **`users`**: Customer and mechanic account profiles, hashed credentials, emergency contacts.
   - **`diagnoses`**: Vehicle fault predictions, severity levels, estimated repair costs, and symptoms.
   - **`conversations` & `chat_messages`**: Chat sessions and multi-turn message history.
   - **`mechanic_bookings`**: Customer bookings, scheduled dates, service requests, and live statuses.
   - **`mechanics`**: Active mechanic profiles, ratings, and service capabilities.

---

## 5. Security & Secret Protection

- **Never Commit Secrets**: Ensure `backend/.env` is listed in `.gitignore`.
- **JWT Key**: Set `JWT_SECRET_KEY` in `backend/.env` using `python -c "import secrets; print(secrets.token_urlsafe(64))"`.
- **Service Role Key**: Do NOT expose Supabase `service_role` keys in client-side Flutter code or repository files.
