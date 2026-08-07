# Authentication — Mecha Connect (Sprint 2)

> Design target for the Sprint 2 backend. At RC1 auth is local-only
> (`SharedPreferences is_logged_in`); no real credentials are stored.

## 1. Current State (RC1)

`AuthRepository` + `AuthService` + `AuthProvider` drive
Login/SignUp/ForgotPassword screens. Login state persists via the
SharedPreferences key `is_logged_in`, read by the splash router. There is no
real credential storage or server verification.

## 2. Target (Sprint 2)

### Mechanism
- **JWT access tokens** — 15 minute expiry
- **JWT refresh tokens** — 7 day expiry (stored in Redis session store)
- **bcrypt** password hashing (via passlib)
- Email/phone verification flow

### Authorization
- Role-based access control (RBAC): `customer`, `mechanic`, `admin`
- Resource-level permissions
- Auth middleware on protected routes + FastAPI `Depends` injection

### Endpoints (`/api/v1/auth/`)
| Method | Path | Description |
|---|---|---|
| POST | `/register` | Register new user |
| POST | `/login` | Login with email/phone |
| POST | `/refresh` | Refresh JWT token |
| POST | `/verify` | Verify account |
| POST | `/forgot-password` | Send reset link |
| POST | `/reset-password` | Reset password |

### Data Model
`users.password_hash` (nullable at RC1, populated Sprint 2) in
`docs/backend/Database.md`. `is_logged_in` and `theme_mode` remain on-device
(SharedPreferences), not in the DB.

### Env config
`JWT_SECRET_KEY`, `JWT_ALGORITHM`, `ACCESS_TOKEN_EXPIRE_MINUTES` added to
`backend/app/core/config.py` (Pydantic settings).

## 3. Security Controls (public)

- Security headers on all responses (nosniff, DENY frame, XSS protection, HSTS, CSP).
- Rate limiting — 10 requests/minute on auth endpoints.
- Restrict CORS from `*` to known origins.
- Follow established-library best practices for JWT (python-jose).

See `docs/backend/Architecture.md` §6 for the full security section.
