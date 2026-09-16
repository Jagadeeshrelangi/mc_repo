# Mecha Connect — Authentication Registration Architecture Decisions
## Contract Alignment, Architecture Evaluation, and Verification Blueprint

---

# 1. Current Architecture

Mecha Connect operates a decoupled multi-tier architecture connecting a Flutter client to a FastAPI backend backed by Supabase PostgreSQL and Firebase Cloud Messaging (FCM):

- **Mobile Client:** Flutter (Dart 3.x) with Provider for reactive state management. Network communication flows through a centralized `ApiClient` (`lib/services/api_client.dart`) that manages base URL resolution, HTTP transport, authentication headers, and JWT persistence via `SharedPreferences`.
- **Backend API:** FastAPI (Python 3.13) under `/api/v1` structured in strict 4-layer separation:
  - **Routers:** Thin HTTP translation layer ([backend/app/api/v1/auth.py](file:///c:/mecha_connect%20-%20opencode/backend/app/api/v1/auth.py))
  - **Schemas:** Pydantic v2 data transfer models ([backend/app/schemas/auth.py](file:///c:/mecha_connect%20-%20opencode/backend/app/schemas/auth.py))
  - **Services:** Authentication logic and transaction control ([backend/app/services/auth_service.py](file:///c:/mecha_connect%20-%20opencode/backend/app/services/auth_service.py))
  - **Repositories:** SQLAlchemy 2.0 async data access ([backend/app/repositories/users.py](file:///c:/mecha_connect%20-%20opencode/backend/app/repositories/users.py))
- **Database:** Supabase PostgreSQL using `asyncpg`. Database models follow declarative mapping ([backend/app/models/user.py](file:///c:/mecha_connect%20-%20opencode/backend/app/models/user.py)).
- **Push Notification Infrastructure:** Firebase Admin SDK (Backend) and Firebase Messaging (Flutter), with token registration executing asynchronously post-authentication.

---

# 2. Confirmed Live Defects

During physical device testing on the **Realme Narzo 60 5G (`BYROWWZDNBUWGYFY`, Android 15 / API 35)**, two distinct contract defects were identified:

1. **Defect 1: Phone Field 422 Rejection on Empty Submission**
   - The Flutter UI labels the phone number input as `"Phone Number (optional)"` and the client validator permits empty input.
   - Submitting the form with an empty phone field sends `'phone': null` in the JSON body.
   - FastAPI rejects the request with **HTTP 422 Unprocessable Entity**:
     `[{"type":"string_type","loc":["body","phone"],"msg":"Input should be a valid string","input":null}]`.
   - This error is displayed directly to the user in a floating SnackBar.

2. **Defect 2: Post-Registration Token Absence Contract Mismatch**
   - FastAPI `POST /api/v1/auth/register` creates the user entity and returns `UserOut` (`HTTP 201 Created`), which contains only user profile fields (`id`, `name`, `email`, `phone`, `role`, `is_active`, `is_verified`, `created_at`).
   - Flutter's `AuthRepository.register` expects JWT tokens directly in the registration response:
     `if (res is Map<String, dynamic> && res['access_token'] != null)`.
   - Because `res['access_token']` is `null`, `AuthRepository.register` returns `false`, causing the UI to display `"Registration failed"` even when user creation succeeds in the database.

---

# 3. Root Cause of Phone 422

The root cause of the 422 error is a schema contract conflict between Flutter and FastAPI:

1. **Frontend Assumption:**
   - In `frontend/lib/features/auth/screens/sign_up_screen.dart`:
     ```dart
     AuthTextField(
       controller: _phoneController,
       hintText: 'Phone Number (optional)',
       validator: (v) => auth.validatePhone(v),
     )
     ```
   - In `frontend/lib/features/auth/services/auth_service.dart`:
     ```dart
     String? validatePhone(String? value) {
       if (value == null || value.trim().isEmpty) return null; // Allows empty
       ...
     }
     ```
   - In `frontend/lib/features/auth/repositories/auth_repository.dart`:
     ```dart
     'phone': phone.trim().isNotEmpty ? phone.trim() : null, // Sends null
     ```

2. **Backend Requirement:**
   - In `backend/app/schemas/auth.py`:
     ```python
     phone: str = Field(
         ...,  # Ellipsis means MANDATORY, non-nullable
         min_length=10,
         max_length=16,
         pattern=r"^\+?[0-9]{10,15}$",
         description="Login phone number (unique).",
     )
     ```
   - In `backend/app/models/user.py`:
     ```python
     phone: Mapped[str] = mapped_column(Text, nullable=False)
     __table_args__ = (UniqueConstraint("phone", name="uq_users_phone"), ...)
     ```
When `'phone': null` arrives, Pydantic v2 rejects it before it reaches any service or database code.

---

# 4. Root Cause of Registration/Token Mismatch

The root cause is a disagreement on the architectural boundary of `POST /api/v1/auth/register`:

1. **Backend Architectural Authority (`TASK3_AUTHENTICATION_DECISIONS.md`):**
   - Locked decision D13 & D14: `POST /api/v1/auth/register` creates the user identity record and returns `UserOut` (`201 Created`).
   - Session creation and JWT token issuance are strictly isolated to `POST /api/v1/auth/login` and `POST /api/v1/auth/refresh`.
   - This cleanly separates the **Identity Boundary** (`users` table) from the **Session Boundary** (`refresh_tokens` table).

2. **Frontend Implementation Misalignment:**
   - `AuthRepository.register` in `frontend/lib/features/auth/repositories/auth_repository.dart`:
     ```dart
     if (res is Map<String, dynamic> && res['access_token'] != null) {
       await _apiClient.saveTokens(...);
       return true;
     }
     return false;
     ```
   - `frontend/test/api_integration_test.dart` contained a synthetic mock where `/register` returned mock tokens, which masked this discrepancy during automated CI testing.

---

# 5. Existing Login/Token Architecture

The existing Mecha Connect authentication architecture operates with precision:

1. **Login Dispatch:**
   - Client sends `POST /api/v1/auth/login` with `identifier` (either email or phone) and `password`.
   - Router maps to `AuthService.login(identifier, password)`.
2. **Session Creation:**
   - `AuthService._find_by_identifier` locates the user via `UserRepository.get_by_email` or `get_by_phone`.
   - `security.verify_password` verifies bcrypt hash.
   - `user_repo.record_successful_login(user)` updates `last_login_at` and resets `failed_login_attempts`.
   - `_issue_tokens(user.id)` generates:
     - 15-minute Bearer JWT `access_token`
     - 7-day cryptographically random `refresh_token`
   - `RefreshTokenRepository.create_refresh_token` saves the **SHA-256 digest** of the refresh token to the database.
   - Commits transaction once.
   - Returns `TokenResponse(access_token, refresh_token, token_type="bearer", expires_in=900)`.
3. **Client Token Handling:**
   - `ApiClient.saveTokens` writes tokens to `SharedPreferences` keys:
     - `auth_access_token`
     - `auth_refresh_token`
   - `ApiClient._send` automatically injects `Authorization: Bearer <token>` into authenticated requests.
   - `ApiClient._send` automatically refreshes the token via `POST /api/v1/auth/refresh` upon receiving an HTTP 401.

---

# 6. Option A Analysis (Phone Required)

### Concept
Make phone number explicitly required across the entire Flutter application to align with the existing backend schema and database.

### Evaluation
- **Impact on Existing Database:** **ZERO**.
  `users.phone` is already `TEXT NOT NULL UNIQUE` in PostgreSQL. No database schema changes, no migration, no table locks.
- **Impact on Authentication:** **OPTIMAL**.
  Enables reliable dual-identifier login (`login` with email or phone) for 100% of accounts.
- **Impact on Registration UX:** **CLEAR & MINIMAL**.
  Change `'Phone Number (optional)'` to `'Phone Number'`. Require a valid 10–15 digit phone number matching `^\+?[0-9]{10,15}$`. Standard practice for on-demand vehicle/transportation apps (e.g. Uber, Ola, Rapido).
- **Impact on Mechanic/Service Booking:** **VITAL & PROTECTIVE**.
  In Mecha Connect, drivers request roadside assistance, emergency towing, and mechanic dispatch. Mechanics must be able to phone the driver directly. If phone were optional, mechanic bookings would fail or require a secondary phone-entry interceptor.
- **Impact on User Identification:** Guarantees unique, verified phone contact.
- **Migration Complexity:** None.
- **Regression Risk:** Very Low.
- **Testing Scope:** Frontend form validation, UI hints, and repository payload.

---

# 7. Option B Analysis (Phone Optional)

### Concept
Modify the backend API, Pydantic schemas, database model, and PostgreSQL constraints to allow `phone` to be null.

### Evaluation
- **Impact on Existing Database:** **HIGH**.
  Must alter column `users.phone` to `DROP NOT NULL`. In PostgreSQL, `UNIQUE` allows multiple nulls, but partial indexes (`CREATE UNIQUE INDEX ... WHERE phone IS NOT NULL`) would be required to prevent edge-case collisions.
- **Impact on Authentication:** Degraded. Users without phone numbers cannot log in using phone identifier; backend `_find_by_identifier` requires special-case null guards.
- **Impact on Registration UX:** Users can register with only email and password.
- **Impact on Mechanic/Service Booking:** **DESTRUCTIVE**.
  The mechanic booking module (`backend/app/schemas/mechanic.py`) expects user phone for coordination. A customer with a null phone would trigger downstream validation failures when booking roadside assistance.
- **Migration Complexity:** High (Alembic migration `0003_nullable_phone.py`, deploy to Supabase, update models, update seed data).
- **Regression Risk:** High across backend schemas, repositories, and 261 existing passing backend unit tests.
- **Testing Scope:** Full backend regression suite + database migration verification + frontend.

---

# 8. Recommended Architecture Based on Existing System Consistency

### Recommendation: OPTION A (Phone Required) + Auto-Login on Registration

1. **Phone Requirement (Option A):**
   The existing database, backend models, schemas, tests, and business domain (on-demand emergency vehicle assistance) all unanimously treat `phone` as a mandatory, unique attribute. Option A respects the system's foundational design with zero backend regression risk.

2. **Registration Response Contract Decision:**
   - Keep backend `POST /api/v1/auth/register` returning `UserOut` (`201 Created`), preserving D13/D14 architectural boundary.
   - In Flutter `AuthRepository.register`, upon successful user creation (`res is Map && res['id'] != null`), **immediately and automatically invoke `login(email, password)`**.
   - This automatically:
     - Authenticates the new user via the canonical login pipeline.
     - Issues access + refresh tokens and stores the refresh token digest in PostgreSQL.
     - Saves tokens into `SharedPreferences` via `ApiClient.saveTokens`.
     - Updates `AuthProvider._isLoggedIn = true`.
     - Triggers push notification token registration (`pushService.registerCurrentToken()`).
     - Seamlessly navigates the user to `BottomNavigation()` without asking them to re-enter credentials.

---

# 9. Exact API Contract After the Decision

### Registration Request (`POST /api/v1/auth/register`)
- **Headers:** `Content-Type: application/json`
- **Body:**
  ```json
  {
    "name": "Full Name (min 2, max 100)",
    "email": "user@example.com (valid email)",
    "phone": "+919876543210 (10 to 15 digits, optional leading +)",
    "password": "Password123 (min 8, max 128)"
  }
  ```
- **Response Status:** `201 Created`
- **Response Body:**
  ```json
  {
    "id": "uuid-string",
    "name": "Full Name",
    "email": "user@example.com",
    "phone": "+919876543210",
    "role": "customer",
    "is_active": true,
    "is_verified": false,
    "created_at": "2026-09-16T15:00:00Z"
  }
  ```

### Automatic Post-Registration Login (`POST /api/v1/auth/login`)
- **Headers:** `Content-Type: application/json`
- **Body:**
  ```json
  {
    "identifier": "user@example.com",
    "password": "Password123"
  }
  ```
- **Response Status:** `200 OK`
- **Response Body:**
  ```json
  {
    "access_token": "jwt-access-token",
    "refresh_token": "raw-refresh-token",
    "token_type": "bearer",
    "expires_in": 900
  }
  ```

---

# 10. Exact Files That Will Need Modification

### 1. [frontend/lib/features/auth/screens/sign_up_screen.dart](file:///c:/mecha_connect%20-%20opencode/frontend/lib/features/auth/screens/sign_up_screen.dart)
- Line 150: Change `hintText: 'Phone Number (optional)'` to `hintText: 'Phone Number'`.

### 2. [frontend/lib/features/auth/services/auth_service.dart](file:///c:/mecha_connect%20-%20opencode/frontend/lib/features/auth/services/auth_service.dart)
- Line 24: Update `validatePhone` to reject empty input (`if (value == null || value.trim().isEmpty) return 'Enter your phone number';`) and enforce 10-digit minimum.

### 3. [frontend/lib/features/auth/repositories/auth_repository.dart](file:///c:/mecha_connect%20-%20opencode/frontend/lib/features/auth/repositories/auth_repository.dart)
- Line 51: Pass `'phone': phone.trim()` (guaranteed non-empty string).
- Lines 57–64: Update registration response parsing:
  ```dart
  if (res is Map<String, dynamic> && res['id'] != null) {
    return await login(email, password);
  }
  return false;
  ```

### 4. [frontend/test/api_integration_test.dart](file:///c:/mecha_connect%20-%20opencode/frontend/test/api_integration_test.dart)
- Lines 226–248: Update unit test mock to return `UserOut` (`201 Created`) on `/register` and `TokenResponse` (`200 OK`) on `/login`, aligning test assertions with the real production flow.

---

# 11. Database Changes Required, If Any

- **Changes Required:** **NONE**.
- The existing database table `users` already enforces `phone TEXT NOT NULL UNIQUE`, which is fully preserved.

---

# 12. Migration Requirements, If Any

- **Migrations Required:** **NONE**.
- Current migration head in Supabase remains unaltered.

---

# 13. Security Considerations

1. **Password Safety:**
   - Passwords are never logged, printed, or saved in plaintext in repository files or reports.
   - Bcrypt hashing with cost factor 12 is executed on the backend before database insertion.
2. **Token Storage:**
   - Plaintext refresh tokens are never persisted in the database; only SHA-256 digests are stored in `refresh_tokens`.
   - Access tokens reside in mobile private app storage (`SharedPreferences`).
3. **Enumeration Protection:**
   - Duplicate email or phone registration cleanly raises generic `InvalidInputException` ("An account with this email/phone already exists").

---

# 14. Regression Risks

| Risk Area | Severity | Mitigation |
| :--- | :--- | :--- |
| **Auth Rate Limiting** | Low | D10 allows 10 requests/minute per client. The register + auto-login flow uses exactly 2 requests. |
| **Offline Test Resilience** | Low | Existing fallback mock in `AuthRepository` remains intact for offline testing. |
| **FCM Token Registration** | None | Token registration remains `unawaited` and executes post-login as intended. |

---

# 15. Testing Plan

1. **Automated Unit Tests:**
   - Run `flutter test test/api_integration_test.dart`.
   - Verify `register dispatches new user data, auto-authenticates, and stores tokens` passes.
2. **Backend Regression Testing:**
   - Run `python -m pytest backend/tests -k auth`.
   - Ensure all 261 backend tests pass without modification.

---

# 16. Real Android Verification Plan

1. **Target Physical Device:** Realme Narzo 60 5G (`BYROWWZDNBUWGYFY`, Android 15 / API 35).
2. **Verification Steps:**
   - Launch app on physical device.
   - Navigate to Sign Up screen.
   - Confirm UI displays `'Phone Number'` without `(optional)`.
   - Test validation: empty phone field triggers client-side validation error without network dispatch.
   - Fill valid registration data:
     - Name: `Test Driver`
     - Email: Test account email
     - Phone: Valid test phone number (e.g. `+919876543210`)
     - Password: Valid password
   - Tap "Create Account".
   - Verify:
     - FastAPI receives `POST /api/v1/auth/register` (returns `201 Created`).
     - FastAPI immediately receives `POST /api/v1/auth/login` (returns `200 OK`).
     - Flutter saves JWT tokens.
     - App transitions smoothly to `BottomNavigation` (Home Dashboard).

---

# 17. Explicit List of Files That Must NOT Be Changed

To prevent scope creep and maintain architectural stability, the following files must remain untouched:
- `backend/app/api/v1/auth.py`
- `backend/app/schemas/auth.py`
- `backend/app/services/auth_service.py`
- `backend/app/repositories/users.py`
- `backend/app/models/user.py`
- `backend/app/models/refresh_token.py`
- `backend/app/core/security.py`
- `backend/app/core/database.py`
- `backend/app/main.py`
- `backend/migrations/*`
- `frontend/android/*`
- `frontend/lib/services/api_client.dart`
- `frontend/lib/services/push_notification_service.dart`
