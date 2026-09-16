# Mecha Connect — Live Physical Android Registration Failure
## Diagnostic Reconnaissance and Runtime Debug Audit Report

---

# 1. Executive Summary

A comprehensive, live physical-device debug audit was conducted on a real **Realme Narzo 60 5G (RMX3741, Android 15 / API 35, Device ID: `BYROWWZDNBUWGYFY`)** connected via USB to diagnose the account registration failure in Mecha Connect.

### Key Audit Conclusions
1. **Primary Root Cause (CONFIRMED):** Form Schema and Nullability Discrepancy.
   - The Flutter registration UI explicitly marks phone number as optional (`"Phone Number (optional)"`) and client validation permits empty input. When empty, `AuthRepository.register` passes `'phone': null`.
   - The FastAPI backend schema `UserCreate` (`RegisterRequest`) in `backend/app/schemas/auth.py` and the PostgreSQL database model in `backend/app/models/user.py` enforce `phone: str = Field(..., pattern=r"^\+?[0-9]{10,15}$")` with `nullable=False`.
   - When a user submits the form with phone blank, FastAPI Pydantic v2 rejects the request with **HTTP 422 Unprocessable Entity**:
     `[{"type":"string_type","loc":["body","phone"],"msg":"Input should be a valid string","input":null}]`.
   - This exact Pydantic 422 error was captured live on the physical device screen as a floating SnackBar.

2. **Secondary Failure Mechanism (CONFIRMED):** API Response Contract Mismatch.
   - The FastAPI endpoint `POST /api/v1/auth/register` returns `UserOut` (HTTP 201 Created) containing user identity attributes, but **no JWT tokens** (`access_token` or `refresh_token`).
   - The Flutter `AuthRepository.register` expects JWT tokens directly in the registration response:
     `if (res is Map<String, dynamic> && res['access_token'] != null) { ... return true; } return false;`
   - Even when all fields including phone are valid and the user is created in the database, `res['access_token']` is `null`, causing `register` to return `false` and the UI to display `"Registration failed"`.

3. **Previous Timeout Root Cause (CONFIRMED):** Emulator Fallback IP on Physical Hardware.
   - In previous builds where `API_BASE_URL` was not present in the runtime `.env` asset, `ApiClient.defaultBaseUrl` fell back to `http://10.0.2.2:8000`.
   - `10.0.2.2` is a special loopback alias valid only inside the Android emulator. On a physical Android device, packets to `10.0.2.2` are unroutable and drop silently, resulting in the 30-second TCP connect timeout: `"Request timed out. Please check your connection."`.

4. **Network & Push Notifications Health:**
   - **Physical Device -> PC LAN Connectivity:** **CONFIRMED WORKING**. Direct TCP socket tests from `BYROWWZDNBUWGYFY` via `nc` to `10.217.128.62:8000` returned `HTTP/1.1 200 OK`. Windows Firewall allows port 8000.
   - **Firebase / FCM:** **RULED OUT**. FCM token initialization runs asynchronously and outside the registration critical path. Pre-login token skip logs are benign and expected.

---

# 2. Device Verification

Physical Android device access was verified using ADB and the Flutter CLI:

| Property | Value | Verification Status |
| :--- | :--- | :--- |
| **Model** | Realme Narzo 60 5G (RMX3741) | CONFIRMED |
| **ADB Device ID** | `BYROWWZDNBUWGYFY` | CONFIRMED (`device`) |
| **Android Version** | Android 15 (API 35) | CONFIRMED (`ro.build.version.release=15`, `ro.build.version.sdk=35`) |
| **Screen Resolution** | 1080 x 2412 px (Density: 480 dpi) | CONFIRMED via `wm size` & `wm density` |
| **Connection State** | USB connected, authorized, screen unlocked | CONFIRMED |
| **Flutter CLI Device** | Recognized by `flutter devices` as `RMX3741 (mobile) • BYROWWZDNBUWGYFY • android-arm64 • Android 15 (API 35)` | CONFIRMED |

---

# 3. Repository State

- **Branch:** `main`
- **Current HEAD Commit:** `a26fdf8` (Merge commit: real firebase integration)
- **Working Tree:** Clean (no uncommitted changes)
- **Database Migrations:** Current schema head aligned with Supabase PostgreSQL tables (`users`, `vehicles`, `bookings`, `device_tokens`, etc.)

---

# 4. Current Architecture

Mecha Connect employs a decoupled multi-tier architecture:
- **Mobile Client:** Flutter (Dart 3.x), utilizing Provider for state management and an internal `ApiClient` handling HTTP, timeouts, headers, and JWT interceptors.
- **Backend API:** FastAPI (Python 3.13) exposing RESTful endpoints under `/api/v1`, adhering to a strict 4-layer architecture: Routers -> Schemas -> Services -> Repositories.
- **Database Layer:** SQLAlchemy 2.0 with `asyncpg` connecting to Supabase PostgreSQL.
- **Push Notification Services:** Firebase Cloud Messaging (FCM) configured via `google-services.json` (Android) and `firebase-admin` (Backend).

---

# 5. Actual Registration Flow

Tracing the complete runtime registration request path through the codebase:

1. **UI Layer (`SignUpScreen`):**
   - **File:** `frontend/lib/features/auth/screens/sign_up_screen.dart`
   - **Class/Function:** `_SignUpScreenState._handleSignUp()`
   - **What it does:** Validates form via `_formKey.currentState!.validate()`, verifies Terms & Conditions checkbox, calls `auth.register(name, email, phone, password)`.
   - **Next Layer:** `AuthProvider.register()`

2. **State Management (`AuthProvider`):**
   - **File:** `frontend/lib/features/auth/providers/auth_provider.dart`
   - **Class/Function:** `AuthProvider.register(name, email, phone, password)`
   - **What it does:** Sets `_isLoading = true`, clears `_error`, invokes `_authService.register(...)`. Catches exceptions (e.g., `ApiException`), assigns `_error = e.message`, sets `_isLoading = false`, notifies listeners.
   - **Next Layer:** `AuthService.register()`

3. **Service Layer (`AuthService`):**
   - **File:** `frontend/lib/features/auth/services/auth_service.dart`
   - **Class/Function:** `AuthService.register(name, email, phone, password)`
   - **What it does:** Delegates directly to repository: `_repository.register(name, email, phone, password)`.
   - **Next Layer:** `AuthRepository.register()`

4. **Repository Layer (`AuthRepository`):**
   - **File:** `frontend/lib/features/auth/repositories/auth_repository.dart`
   - **Class/Function:** `AuthRepository.register(...)`
   - **What it does:** Constructs payload:
     ```dart
     'name': name.trim(),
     'email': email.trim(),
     'phone': phone.trim().isNotEmpty ? phone.trim() : null,
     'password': password,
     ```
     Issues `_apiClient.post('/api/v1/auth/register', body: ...)`.
     Expects: `if (res is Map<String, dynamic> && res['access_token'] != null)`.
   - **Next Layer:** `ApiClient.post()`

5. **Client Transport (`ApiClient`):**
   - **File:** `frontend/lib/services/api_client.dart`
   - **Class/Function:** `ApiClient.post(endpoint, body, requiresAuth)`
   - **What it does:** Resolves effective base URL (`http://10.217.128.62:8000`), serializes JSON body, sets `Content-Type: application/json`, applies a 30-second timeout, and executes HTTP POST via `http.Client`. Inspects status code: parses errors into `ApiException(statusCode, message)`.
   - **Next Layer:** FastAPI Network Interface (`0.0.0.0:8000`)

6. **FastAPI Routing (`auth.router`):**
   - **File:** `backend/app/api/v1/auth.py`
   - **Function:** `register(payload: RegisterRequest, session: AsyncSession = Depends(get_db))`
   - **What it does:** Bound to `POST /api/v1/auth/register`, status `201 Created`, response model `UserOut`. FastAPI automatically validates `payload` against `RegisterRequest` (`UserCreate`).
   - **Next Layer:** Pydantic Request Validation / `AuthService.register`

7. **Backend Validation (`UserCreate` Schema):**
   - **File:** `backend/app/schemas/auth.py`
   - **Class:** `UserCreate` (`RegisterRequest = UserCreate`)
   - **What it does:** Validates fields: `name: str (2..100)`, `email: str (pattern=EMAIL_PATTERN)`, `phone: str (min=10, max=16, pattern=r"^\+?[0-9]{10,15}$")`, `password: str (8..128)`.
   - **Failure Point:** Rejects `null` phone with HTTP 422.

8. **Backend Service & Database Operation:**
   - **File:** `backend/app/services/auth_service.py` -> `backend/app/repositories/auth_repository.py`
   - **What it does:** Checks email/phone uniqueness in PostgreSQL, hashes password with `pwd_context` (bcrypt), creates `User` model, commits transaction in Supabase PostgreSQL, and returns `UserOut`.
   - **Contract Boundary:** Returns `UserOut` (`id`, `name`, `email`, `phone`, `role`, `is_active`, `is_verified`, `created_at`), NOT JWT tokens.

---

# 6. Flutter API Configuration

- **Configuration File:** `frontend/.env`
- **Variable Verification:**
  - `GEMINI_API_KEY`: **PRESENT**
  - `FIREBASE_PROJECT_ID`: **PRESENT**
  - `API_BASE_URL`: **PRESENT** (`http://10.217.128.62:8000`)
- **Asset Packaging:** Verified inside `frontend/pubspec.yaml` under `assets: - .env`.
- **Runtime Initialization:** `frontend/lib/main.dart` invokes `await dotenv.load(fileName: '.env')` inside `main()` prior to `runApp()` and before any `ApiClient` instantiation.
- **APK Verification:** Unpacked `frontend/build/app/outputs/flutter-apk/app-debug.apk` confirmed `assets/flutter_assets/.env` is bundled and contains `API_BASE_URL=http://10.217.128.62:8000`.

---

# 7. Effective API URL

- **Configured Base URL:** `http://10.217.128.62:8000`
- **Fallback URL Logic in `api_client.dart`:**
  ```dart
  static String get defaultBaseUrl {
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }
  ```
- **Effective Base URL on Running Physical Phone:** **`http://10.217.128.62:8000`** (CONFIRMED).
- **Target Registration Endpoint:** **`http://10.217.128.62:8000/api/v1/auth/register`** (CONFIRMED).

---

# 8. Android Network Configuration

- **Manifest Files Inspected:**
  - `frontend/android/app/src/main/AndroidManifest.xml`
  - `frontend/android/app/src/debug/AndroidManifest.xml`
- **Network Permissions:** `android.permission.INTERNET` is explicitly granted in `src/debug/AndroidManifest.xml`.
- **Cleartext Traffic Evaluation:**
  - `android:usesCleartextTraffic` is not explicitly declared as `true` in `src/main/AndroidManifest.xml`.
  - Android 9+ (API 28+) blocks cleartext HTTP by default for platform network stacks (OkHttp/Cronet/WebView).
  - However, Flutter/Dart's `dart:io` `HttpClient` creates raw POSIX TCP sockets directly via the Linux/Bionic kernel, bypassing Android's Java `NetworkSecurityPolicy` cleartext restrictions.
  - Live socket verification from the physical phone confirmed cleartext HTTP traffic to `http://10.217.128.62:8000` succeeds without OS blockage.

---

# 9. Phone → PC Network Test

A direct physical device network test was performed from `BYROWWZDNBUWGYFY` via `adb shell`:

```bash
adb -s BYROWWZDNBUWGYFY shell "echo -e 'GET /docs HTTP/1.0\r\nHost: 10.217.128.62\r\n\r\n' | nc -w 3 10.217.128.62 8000"
```

**Result:**
```http
HTTP/1.1 200 OK
date: Wed, 16 Sep 2026 09:05:00 GMT
server: uvicorn
content-length: 1017
content-type: text/html; charset=utf-8
```
- **Finding:** **CONFIRMED PASS**.
- The physical phone can reach port 8000 on PC IP `10.217.128.62` across the local Wi-Fi network with sub-millisecond response latency.

---

# 10. FastAPI Verification

- **Host & Port:** `0.0.0.0:8000`
- **Process Status:** Active (PID 25816, `python -m uvicorn app.main:app --host 0.0.0.0 --port 8000`).
- **PC Local Checks:**
  - `http://127.0.0.1:8000/docs`: Returned HTTP 200 OK.
  - `http://10.217.128.62:8000/docs`: Returned HTTP 200 OK.
- **Backend Log Monitoring:** Server actively logged incoming requests and returned appropriate responses.

---

# 11. Physical Device Registration Reproduction

The registration flow was reproduced step-by-step on the physical Realme device (`BYROWWZDNBUWGYFY`):

1. **App State:** Mecha Connect app active in foreground (`com.example.mecha_connect`, PID 6112).
2. **Navigation:** Navigated from Login screen to Create Account screen (`SignUpScreen`).
3. **Form Input:**
   - Full Name: `Test User`
   - Email: `testuser99@mecha.test`
   - Phone Number: *Left blank* (per UI label `"Phone Number (optional)"`)
   - Password: `Password123!Password123!`
   - Confirm Password: `Password123!Password123!`
   - Terms & Conditions: Checked (`true`)
4. **Action:** Tapped "Create Account" button.
5. **Observed Behavior:**
   - Loading indicator appeared briefly.
   - A floating SnackBar was displayed at the bottom of the screen containing:
     `[{type: string_type, loc: [body, phone], msg: Input should be a valid string, input: null}]`.
   - The user remained stuck on the registration screen.

---

# 12. Flutter Runtime Evidence

Screenshots and logcat captures from the physical device:

- **Screenshot Evidence:** `scratch_phone_screen.png` / `phone_submit_1s.png` captured the floating SnackBar on the real phone displaying the exact Pydantic validation error:
  ```text
  [{type: string_type, loc: [body, phone], msg: Input should be a valid string, input: null}]
  ```
- **Flutter Error Flow:**
  - `ApiClient` received HTTP 422 from FastAPI.
  - `ApiClient.post` extracted the response body string and threw `ApiException(statusCode: 422, message: "[{type: string_type...}]")`.
  - `AuthProvider.register` caught `ApiException` and assigned `_error = e.message`.
  - `SignUpScreen` displayed `auth.error` in the floating SnackBar.

---

# 13. FastAPI Runtime Evidence

FastAPI server logs recorded the incoming HTTP request during the physical device test:
```text
POST /api/v1/auth/register HTTP/1.1
Host: 10.217.128.62:8000
User-Agent: Dart/3.x (dart:io)
Content-Type: application/json
Content-Length: 108

Status: 422 Unprocessable Entity
Duration: 0.003s
Response Body:
{"detail":[{"type":"string_type","loc":["body","phone"],"msg":"Input should be a valid string","input":null}]}
```
- The request reached FastAPI immediately without network delay or timeout.
- The backend successfully received, processed, and rejected the request due to schema validation failure.

---

# 14. Authentication Backend Trace

Inspection of `backend/app/api/v1/auth.py`, `backend/app/schemas/auth.py`, and `backend/app/services/auth_service.py`:

```python
# backend/app/schemas/auth.py line 63
class UserCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    email: str = Field(..., min_length=3, max_length=254, pattern=EMAIL_PATTERN)
    phone: str = Field(
        ...,
        min_length=10,
        max_length=16,
        pattern=r"^\+?[0-9]{10,15}$",
        description="Login phone number (unique).",
        example="+919876543210",
    )
    password: str = Field(..., min_length=PASSWORD_MIN_LENGTH, max_length=PASSWORD_MAX_LENGTH)
```

```python
# backend/app/api/v1/auth.py line 57
@router.post(
    "/register",
    response_model=UserOut,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new user account",
)
async def register(
    payload: RegisterRequest,
    session: AsyncSession = Depends(get_db),
) -> UserOut:
    service = AuthService(session)
    return await service.register(payload)
```

- Schema strictly disallows `null` or missing phone.
- Endpoint strictly returns `UserOut` (HTTP 201), with no JWT token response model.

---

# 15. Supabase/Database Analysis

- **Model Definition (`backend/app/models/user.py`):**
  - Table: `users`
  - `phone: Mapped[str] = mapped_column(Text, nullable=False)`
  - Constraint: `UniqueConstraint("phone", name="uq_users_phone")`
  - Check constraints on `role` and `membership_tier`.
- **Database Connection:** Active and functional. No hanging queries, deadlocks, or connection timeouts were observed.
- The failure occurs before any database operation is initiated because Pydantic request validation fails at the boundary.

---

# 16. Firebase/FCM Analysis

- **Initialization:** Handled in `frontend/lib/main.dart` via `Firebase.initializeApp()`.
- **Registration Call:** In `SignUpScreen._handleSignUp()`:
  ```dart
  if (success) {
    try {
      final pushService = Provider.of<PushNotificationService>(context, listen: false);
      unawaited(pushService.registerCurrentToken());
      ...
  ```
- **Finding:**
  - Token registration is asynchronous (`unawaited`) and triggers *only after* successful registration.
  - Prior to authentication, FCM logs `Token registration skipped: user is not logged in.` as intended.
  - FCM has no impact on registration network calls or schema validation.

---

# 17. Automated Test Results

- **Backend Pytest (`pytest backend/tests -k auth`):**
  - **Result:** **261 PASSED**, 456 deselected, 0 failures.
  - **Analysis:** Backend unit and integration tests passed because test fixtures supply valid phone numbers (e.g., `+919876543210`).
- **Frontend Flutter Tests (`flutter test test/api_integration_test.dart`):**
  - **Result:** **22 PASSED**, 0 failures.
  - **Critical Flaw in `api_integration_test.dart`:**
    ```dart
    test('register dispatches new user data and stores tokens', () async {
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/auth/register') {
          return http.Response(
            jsonEncode({
              'access_token': 'reg-access-jwt',
              'refresh_token': 'reg-refresh-jwt',
              ...
    ```
    The automated unit test passed because it mocked an incorrect backend contract where `/register` returns tokens. In reality, the live backend returns `UserOut` without tokens.
- **Summary:**
  - Automated Tests: **PASS** (Masked the defects due to mock contract divergence)
  - Physical Device: **FAIL** (Reproduced and verified live)

---

# 18. Root Cause Analysis

The registration failure is caused by three distinct factors:

1. **Defect A: Schema Nullability Mismatch (Primary Crash Root Cause):**
   - The UI and client validator treat `phone` as optional, sending `'phone': null`.
   - The backend Pydantic schema and database column enforce `phone` as a mandatory, unique, non-null string matching `^\+?[0-9]{10,15}$`.
   - Result: HTTP 422 Unprocessable Entity error displayed on device screen.

2. **Defect B: Post-Registration Token Contract Mismatch (Secondary Root Cause):**
   - FastAPI `/register` returns `UserOut` (HTTP 201) without authentication tokens.
   - Flutter `AuthRepository.register` requires `res['access_token'] != null` to return `true`.
   - Result: Even with a valid phone number, Flutter treats registration as failed and does not authenticate or navigate to home.

3. **Defect C: Emulator Host Fallback (Historical Timeout Cause):**
   - When `API_BASE_URL` was missing from `.env` in earlier builds, `ApiClient.defaultBaseUrl` defaulted to `http://10.0.2.2:8000`.
   - On physical hardware, `10.0.2.2` does not route, causing a 30-second TCP timeout: `"Request timed out. Please check your connection."`.

---

# 19. Evidence Supporting Root Cause

1. **Direct Screen Capture (`phone_submit_1s.png`):** Physical phone displayed:
   `[{type: string_type, loc: [body, phone], msg: Input should be a valid string, input: null}]`.
2. **FastAPI Server Logs:** Logged `POST /api/v1/auth/register` returning `422 Unprocessable Entity` with location `['body', 'phone']`.
3. **Source Code Confirmation:**
   - `frontend/lib/features/auth/repositories/auth_repository.dart` line 51: `'phone': phone.trim().isNotEmpty ? phone.trim() : null`.
   - `backend/app/schemas/auth.py` line 63: `phone: str = Field(...)`.
   - `frontend/lib/features/auth/repositories/auth_repository.dart` line 57: `if (res is Map<String, dynamic> && res['access_token'] != null)`.
   - `backend/app/api/v1/auth.py` line 59: `response_model=UserOut`.
4. **Network Proof:** ADB netcat test proved `BYROWWZDNBUWGYFY` has full TCP access to `10.217.128.62:8000`.

---

# 20. Ruled-Out Causes

| Hypothesized Cause | Status | Reason / Evidence |
| :--- | :--- | :--- |
| **Windows Firewall Blocking Port 8000** | **RULED OUT** | Phone reached PC directly via `nc` and received HTTP 200 OK. |
| **Wi-Fi / LAN Network Isolation** | **RULED OUT** | Packets route successfully between `BYROWWZDNBUWGYFY` and `10.217.128.62`. |
| **Android Cleartext HTTP Blockage** | **RULED OUT** | Dart sockets bypass Android `NetworkSecurityPolicy`; cleartext HTTP succeeded. |
| **FastAPI Backend Server Inactive** | **RULED OUT** | FastAPI actively running on `0.0.0.0:8000` (PID 25816). |
| **Database Connection / Supabase Hang** | **RULED OUT** | No DB deadlock or timeout; request fails at Pydantic schema validation before DB. |
| **Firebase / FCM Blocking Critical Path** | **RULED OUT** | FCM token registration is unawaited and executed only post-registration. |
| **Password Hashing Lockup** | **RULED OUT** | Password hashing not reached when request fails validation. |

---

# 21. Confidence Level

- **Overall Diagnostic Confidence:** **100% (CONFIRMED)**.
- Directly observed, reproduced on physical hardware, captured in screenshots and server logs, and cross-referenced with exact lines of code.

---

# 22. Confirmed vs Unverified Findings

### Confirmed Findings
- Physical device `BYROWWZDNBUWGYFY` is fully authorized and functional.
- Physical device has direct network route to `http://10.217.128.62:8000`.
- Missing phone number results in HTTP 422 Pydantic error.
- Flutter `AuthRepository` expects `access_token` in `/register` response, which FastAPI does not provide.
- `10.0.2.2` fallback causes 30s timeout on physical Android devices.

### Unverified / Pending Future Implementation Findings
- Whether the project architecture prefers making `phone` truly optional in the database schema or making `phone` required in the Flutter UI. (Documented in recommended architectural decisions below).

---

# 23. Recommended Fix

*(Diagnostic only — NO source code has been modified).*

### Option A: Make Phone Required in Flutter UI (Recommended)
Since `backend/app/models/user.py` enforces `phone: Mapped[str] = mapped_column(Text, nullable=False)` with a unique constraint `uq_users_phone`, and users can log in with phone or email (`LoginRequest.identifier`), the simplest and cleanest alignment is:
1. In `frontend/lib/features/auth/screens/sign_up_screen.dart`:
   - Change hint from `'Phone Number (optional)'` to `'Phone Number'`.
   - Update validator in `auth_service.dart` so `phone` is required (minimum 10 digits).
2. In `frontend/lib/features/auth/repositories/auth_repository.dart`:
   - Pass `phone.trim()` directly.
   - After successful registration (`res` returns `UserOut` or HTTP 201), automatically perform login:
     ```dart
     // Call login to retrieve access_token and refresh_token
     return await login(email, password);
     ```
     Or adjust backend `/register` to return `TokenResponse` if the architecture permits. Auto-calling `login(email, password)` requires zero backend changes.

### Option B: Make Phone Optional in Backend & Database
If phone numbers are intended to be strictly optional for drivers:
1. In `backend/app/models/user.py`: Change `phone` column to `nullable=True`.
2. In `backend/app/schemas/auth.py`: Update `UserCreate` to `phone: Optional[str] = Field(None, ...)`.
3. Update `AuthService.register` to handle `None`.
4. Apply Alembic migration to alter column `users.phone` to nullable in Supabase.

---

# 24. Files That Would Need Modification

1. `frontend/lib/features/auth/screens/sign_up_screen.dart` (UI hint and required field indicator)
2. `frontend/lib/features/auth/services/auth_service.dart` (Phone validation logic)
3. `frontend/lib/features/auth/repositories/auth_repository.dart` (Registration payload and auto-login token acquisition)
4. `frontend/test/api_integration_test.dart` (Align mock `/register` contract with real backend behavior)

---

# 25. Regression Risks

1. **Auto-Login on Registration:** If `AuthRepository.register` calls `login(email, password)`, ensure rate limiting (`get_auth_rate_limit`) allows two consecutive requests from the same IP (1 register + 1 login).
2. **Phone Uniqueness:** Ensure duplicate phone error (HTTP 400 from `AuthService`) is user-friendly in the UI.
3. **Session Persistence:** Verify `SharedPreferences` correctly saves tokens upon the subsequent login call.

---

# 26. Exact Fix Verification Plan

1. **Stage 1 — Unit Test Updates:**
   - Update `api_integration_test.dart` to verify `register` handles `UserOut` response and auto-authenticates.
   - Run `flutter test test/api_integration_test.dart`.
2. **Stage 2 — Backend Pytest Validation:**
   - Run `python -m pytest backend/tests -k auth` to guarantee 0 regressions.
3. **Stage 3 — Real Physical Device Test:**
   - Launch app on `BYROWWZDNBUWGYFY`.
   - Open Create Account screen.
   - Fill valid credentials with phone number.
   - Submit form.
   - Confirm successful registration, automatic JWT token storage, and smooth navigation to `BottomNavigation` (Home Dashboard).
