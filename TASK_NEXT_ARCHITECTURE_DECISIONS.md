# MECHA CONNECT — ARCHITECTURE DECISION RECORD (ADR)
# Push Notifications Infrastructure (Firebase Cloud Messaging - FCM)

**Status:** LOCKED  
**Date:** September 9, 2026  
**Author:** Senior Software Architect, Backend Architect, Flutter Architect, Security Reviewer, QA Lead  
**Scope:** Device Token Storage, Notification Orchestration, FCM Provider, Booking Notification Lifecycle, Flutter Client & Deep-Linking  
**Preceding Document:** `TASK_NEXT_RECONNAISSANCE_REPORT.md` (Reconnaissance Complete)

---

## 1. Status
**LOCKED.**  
All architectural decisions, contracts, data models, error handling strategies, security policies, and regression boundaries in this document are finalized. No implementation may begin until external Firebase prerequisites are provisioned and explicit user implementation approval is granted.

---

## 2. Problem
Mecha Connect currently features a production-grade, 7-state booking lifecycle for mechanic services (`requested` → `accepted` → `mechanicAssigned` → `enRoute` → `arrived` → `completed`, terminal `cancelled`) as well as active fuel delivery and marketplace order flows. However, the system operates completely "silently":
- The existing backend `NotificationService` (46 lines) only persists user preference toggles (`push: bool = True`) to the `notification_settings` table.
- There is no device token storage mechanism.
- There is no Firebase Cloud Messaging (FCM) integration or delivery adapter.
- The Flutter client has no FCM receiver, permission handler, or push registration lifecycle.
- When a mechanic accepts a job, begins travel, or arrives, the customer receives no external push notification and must manually refresh the app to observe state progression.

---

## 3. Goal
Transform the notification subsystem into an end-to-end, multi-device push notification pipeline:

```
Flutter App (Android)
       ↓ (getToken / onTokenRefresh)
FCM Token
       ↓ (POST /api/v1/device-tokens)
Backend Device Token API (Bearer Auth)
       ↓
PostgreSQL `device_tokens` Table (Supabase)
       ↓
MechanicService State Transition (Post-Commit Event)
       ↓
NotificationService (Preference Enforcement: push == True)
       ↓
FCM Provider / Adapter (firebase-admin SDK)
       ↓
Firebase Cloud Messaging (Google Infrastructure)
       ↓
User Device (System Tray / Foreground Banner)
       ↓ (User Tap)
Mecha Connect Deep-Link Navigation (LiveTrackingScreen / Protected Routes)
```

---

## 4. Current Architecture

### 4.1 Backend
- **Framework:** FastAPI with async SQLAlchemy 2.0 and PostgreSQL (Supabase).
- **Settings:** `backend/app/core/config.py` contains `FIREBASE_CREDENTIALS_PATH: Optional[str] = None`.
- **Dependencies:** `backend/requirements.txt` contains `firebase-admin==7.5.0` pinned, but unused.
- **Service:** `NotificationService` in `backend/app/services/notification_service.py` manages only `NotificationSettingRepository.get_or_create()` and `push` toggle updates.
- **Router:** `backend/app/api/v1/notification_settings.py` exposes `GET /api/v1/notification-settings` and `PATCH /api/v1/notification-settings`.
- **Database Migrations:** Alembic at head `0006_persistence_foundation_indexes.py`.
- **Models:** `NotificationSetting` (`user_id: UUID PK`, `push: bool`).

### 4.2 Frontend (Flutter)
- **State & Architecture:** Provider + Repository + ApiClient.
- **Navigation:** Standard Flutter `MaterialApp` with `Navigator.push` / `PageRouteBuilder` and 5-tab `BottomNavigation` (Home, Services, Orders, AI, Profile). No `go_router` dependency.
- **Settings Screen:** `NotificationSettingsScreen` reads and toggles `push`, `email`, `sms` via `ProfileProvider`.
- **Firebase/Push:** Neither `firebase_core` nor `firebase_messaging` are configured in `pubspec.yaml`. `permission_handler: ^11.3.1` is already installed.
- **Android App:** Application ID is `com.example.mecha_connect` in `frontend/android/app/build.gradle.kts` (Kotlin DSL).

---

## 5. Proposed Architecture

The push notification infrastructure separates domain business logic from third-party push delivery mechanisms through a layered hexagonal / adapter pattern:

```
┌─────────────────────────────────────────────────────────────┐
│                       Domain Layer                          │
│   MechanicService  │   FuelService   │  MarketplaceService  │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Post-Commit Notification Request)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 NotificationService (Core)                  │
│  - Verifies User Notification Settings (push == True)       │
│  - Fetches target user's active tokens from DeviceTokenRepo │
│  - Builds Canonical NotificationPayload                     │
│  - Dispatches to FCMAdapter (Non-blocking / BackgroundTask) │
│  - Handles feedback: deletes stale/unregistered tokens      │
└───────────────┬─────────────────────────────┬───────────────┘
                │                             │
                ▼                             ▼
┌─────────────────────────────┐ ┌─────────────────────────────┐
│    DeviceTokenRepository    │ │       FCM Adapter           │
│  - Upsert on token          │ │  - FirebaseAdminAdapter     │
│  - Delete on logout/stale   │ │  - MockFCMAdapter (Tests)   │
│  - Fetch active by user_id  │ │  - Multicast Batch Dispatch │
└───────────────┬─────────────┘ └─────────────┬───────────────┘
                │                             │
                ▼                             ▼
┌─────────────────────────────┐ ┌─────────────────────────────┐
│ Supabase PostgreSQL DB      │ │ Firebase Cloud Messaging    │
│ (`device_tokens` table)     │ │ (Google Push Servers)       │
└─────────────────────────────┘ └─────────────────────────────┘
```

---

## 6. Device Token Architecture

### 6.1 Database Model (`device_tokens` table)
A user may use Mecha Connect on multiple devices (e.g., phone and tablet). Conversely, a single device may have multiple user accounts over time (user logout/login). 

```sql
CREATE TABLE device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    platform TEXT NOT NULL, -- 'android', 'ios', 'web'
    device_id TEXT NULL,    -- Hardware/Install UUID for idempotent client updates
    app_version TEXT NULL,  -- Client version (e.g. '1.0.0+1')
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_used_at TIMESTAMPTZ NULL
);

-- Constraints
ALTER TABLE device_tokens ADD CONSTRAINT uq_device_tokens_fcm_token UNIQUE (fcm_token);
ALTER TABLE device_tokens ADD CONSTRAINT ck_device_tokens_platform CHECK (platform IN ('android', 'ios', 'web'));

-- Indexes
CREATE INDEX ix_device_tokens_user_id ON device_tokens(user_id);
CREATE INDEX ix_device_tokens_user_active ON device_tokens(user_id, is_active);
```

### 6.2 Token Scoping & Uniqueness Strategy
- **Global Uniqueness on `fcm_token`:** An FCM registration token uniquely identifies an app instance on a physical device. A single token MUST NOT belong to multiple users simultaneously.
- **Upsert / Ownership Transfer:** When `POST /api/v1/device-tokens` is received:
  - If `fcm_token` already exists in `device_tokens`:
    - Update `user_id = current_user.id`, `platform = payload.platform`, `is_active = TRUE`, `updated_at = now()`.
    - This cleanly handles account switching on a shared device: the previous user loses push delivery to this device, and the active logged-in user gains it.
  - If `fcm_token` is new:
    - Insert new record with `user_id = current_user.id`.
- **Multiple Devices per User:** Supported natively. `user_id` is a 1-to-many relationship with `device_tokens`. When dispatching, all active tokens for `user_id` are targeted via FCM Multicast.

### 6.3 Token Refresh & Invalidation
- **Client-Side Refresh:** Flutter listens to `FirebaseMessaging.instance.onTokenRefresh` and automatically submits the new token to the backend.
- **Backend Cleanup of Stale Tokens:** If FCM responds with `registration-token-not-registered` (`NOT_FOUND`) or `invalid-registration-token` (`INVALID_ARGUMENT`), `NotificationService` calls `DeviceTokenRepository.delete_by_token(token)` immediately. Stale tokens are purged from PostgreSQL without manual intervention.

---

## 7. Backend Architecture

### 7.1 Component Responsibilities
1. **`DeviceToken` Model:** SQLAlchemy 2.0 mapping adhering to project conventions (`Uuid(as_uuid=False)` or `Uuid(as_uuid=True)` matching `users.id`, `DateTime(timezone=True)`).
2. **`DeviceTokenRepository`:** Encapsulates CRUD operations:
   - `upsert_token(user_id, fcm_token, platform, device_id, app_version) -> DeviceToken`
   - `get_active_tokens_for_user(user_id) -> List[str]`
   - `delete_token(fcm_token, user_id=None) -> bool`
   - `deactivate_token(fcm_token) -> bool`
3. **`NotificationService`:**
   - Unified interface for all notification dispatch across Mecha Connect.
   - Evaluates `NotificationSetting.push` for recipient `user_id`. If `push is False`, skips delivery and returns `DispatchResult(skipped=True, reason="user_push_disabled")`.
   - Fetches active tokens for recipient. If empty, returns `DispatchResult(skipped=True, reason="no_registered_devices")`.
   - Formats canonical `NotificationPayload` into FCM-compliant messages.
   - Invokes `FCMAdapter.send_multicast()`.
   - Processes delivery report: deletes dead tokens.
4. **`FCMAdapter` Protocol & Implementations:**
   - Abstract protocol defining `send_multicast(tokens: List[str], payload: NotificationPayload) -> FCMDeliveryReport`.
   - `FirebaseAdminAdapter`: Wraps `firebase_admin.messaging.send_each_for_multicast()` with lazy SDK initialization.
   - `MockFCMAdapter`: In-memory delivery recorder for unit, integration, and CI tests.

### 7.2 Dependency Injection & Mocking
`NotificationService` accepts an optional `FCMAdapterProtocol` in its constructor:
```python
def __init__(
    self,
    session: AsyncSession,
    notification_repository: Optional[NotificationSettingRepository] = None,
    device_token_repository: Optional[DeviceTokenRepository] = None,
    fcm_adapter: Optional[FCMAdapterProtocol] = None,
) -> None:
    ...
```
In production, `fcm_adapter` defaults to `get_firebase_adapter()` which inspects `settings.FIREBASE_CREDENTIALS_PATH`. In tests, `MockFCMAdapter` is injected directly.

---

## 8. FCM Adapter Architecture

### 8.1 Firebase Admin SDK Lifecycle
- **Lazy Initialization:** The Firebase Admin App is initialized on first use, not during module import.
- **Graceful Degradation:** If `settings.FIREBASE_CREDENTIALS_PATH` is null or the file is missing, the adapter logs a warning at startup and defaults to dry-run/mock mode instead of crashing FastAPI or blocking `/health`.
- **SDK Call:** Uses `messaging.send_each_for_multicast(MulticastMessage(...))` which transmits up to 500 tokens in a single HTTP batch to FCM backend.

### 8.2 Error Classification & Cleanup Contract
The adapter maps Firebase SDK responses to a standard `FCMDeliveryReport`:
```python
@dataclass
class FCMDeliveryReport:
    total_tokens: int
    success_count: int
    failure_count: int
    invalid_tokens: List[str]  # Tokens to be deleted from DB
    failed_tokens: List[Tuple[str, str]] # (token, error_code)
```
- When `response.exception.code` is `registration-token-not-registered` or `invalid-registration-token`: Token is added to `invalid_tokens`.
- `NotificationService` immediately calls `device_token_repo.delete_by_token(token)` for each token in `invalid_tokens`.

---

## 9. Canonical Notification Contract

All Mecha Connect notifications share a structured payload contract. Domain services NEVER construct raw Firebase dictionaries.

### 9.1 Payload Schema
```python
@dataclass
class NotificationPayload:
    title: str
    body: str
    notification_type: str       # e.g. "booking.status_changed"
    entity_type: str             # "booking", "fuel_order", "marketplace_order"
    entity_id: str               # UUID string
    deep_link: str               # e.g. "mecha://booking/{id}"
    metadata: Dict[str, str]     # Flat string-to-string dictionary for FCM data
```

### 9.2 Wire Format (FCM Message)
- **`notification` object:** Visible alert displayed by the Android OS system tray when app is backgrounded or terminated:
  ```json
  {
    "title": "Mechanic On The Way",
    "body": "Rajesh Kumar is en route to your location."
  }
  ```
- **`data` object:** Payload delivered directly to Flutter application logic in all states (foreground, background, cold start):
  ```json
  {
    "click_action": "FLUTTER_NOTIFICATION_CLICK",
    "notification_type": "booking.status_changed",
    "entity_type": "booking",
    "entity_id": "8f3b2a10-...",
    "status": "enRoute",
    "deep_link": "mecha://mechanic/booking/8f3b2a10-/tracking",
    "timestamp": "2026-09-09T13:40:00Z"
  }
  ```
*Rule: All keys and values in the FCM `data` map must be strings to comply with Google FCM specification.*

---

## 10. Booking Notification Flow

### 10.1 Booking State Machine Mapping
The existing 7-state booking state machine is preserved without alteration:

| Old Status | New Status | Trigger Method | Notification Recipient | Title | Body Template |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `requested` | `accepted` | `update_booking_status` | Customer | Booking Accepted | "Your service request #{id[:8]} has been accepted." |
| `accepted` | `mechanicAssigned`| `update_booking_status` | Customer | Mechanic Assigned | "{mechanic_name} has been assigned to your booking." |
| `mechanicAssigned` | `enRoute` | `update_booking_status` | Customer | Mechanic On The Way | "{mechanic_name} is en route to your vehicle." |
| `enRoute` | `arrived` | `update_booking_status` | Customer | Mechanic Arrived | "{mechanic_name} has arrived at your location." |
| `arrived` | `completed` | `update_booking_status` | Customer | Service Completed | "Your service has been completed. View summary & invoice." |
| *Any mutable* | `cancelled` | `cancel_booking` | Customer | Booking Cancelled | "Your booking #{id[:8]} has been cancelled." |

### 10.2 Transaction Boundaries & Isolation Rule
**CRITICAL ARCHITECTURAL INVARIANT:**  
*A database transaction must NEVER be rolled back or delayed due to a push notification failure.*

Notification dispatch occurs strictly **AFTER** `session.commit()`:
```python
# 1. Execute and commit the database state transition
await self.booking_repo.update_status(booking, new_status.value)
await self.event_repo.append(...)
await self.session.commit()

# 2. POST-COMMIT: Trigger push dispatch in background task or safe try/except block
try:
    await self.notification_service.dispatch_booking_status_notification(
        booking=booking,
        new_status=new_status,
        mechanic_name=mechanic_name,
    )
except Exception as exc:
    # Logged with full trace, but NEVER raises exception to client
    logger.error("Failed to dispatch push notification for booking %s: %s", booking.id, exc)

return BookingOut.model_validate(booking)
```

---

## 11. Fuel & Marketplace Extension Strategy

While implementation for Fuel and Marketplace is deferred to future stages, the architecture provides immediate zero-refactor extensibility:
- `NotificationService` exposes generic `dispatch_domain_notification(user_id, payload: NotificationPayload)`.
- Fuel Delivery will invoke:
  ```python
  payload = NotificationPayload(
      title="Fuel Delivery On The Way",
      body="Driver is en route with your fuel order.",
      notification_type="fuel.order_status_changed",
      entity_type="fuel_order",
      entity_id=order_id,
      deep_link=f"mecha://fuel/order/{order_id}",
      metadata={"status": "out_for_delivery"},
  )
  await notification_service.dispatch_domain_notification(user_id, payload)
  ```
- Marketplace will invoke:
  ```python
  payload = NotificationPayload(
      title="Part Order Shipped",
      body="Your order #MP-1024 has been shipped.",
      notification_type="marketplace.order_status_changed",
      entity_type="marketplace_order",
      entity_id=order_id,
      deep_link=f"mecha://marketplace/order/{order_id}",
      metadata={"status": "shipped"},
  )
  await notification_service.dispatch_domain_notification(user_id, payload)
  ```
Both use the identical device token lookup, preference filtering, and FCM multicast pipeline.

---

## 12. Flutter Architecture

### 12.1 Flutter State Management & Wiring
- Conforms strictly to the established Mecha Connect architecture: `Provider` + `Repository` + `ApiClient` + `MaterialApp Navigator`.
- New Service: `PushNotificationService` located in `frontend/lib/services/push_notification_service.dart`.
- Root Registration: Wired into `MultiProvider` via `app_wiring.dart` as a singleton service initialized in `main.dart`.

### 12.2 Lifecycle & Listeners
1. **Initialization (`main.dart`):**
   ```dart
   WidgetsFlutterBinding.ensureInitialized();
   await Firebase.initializeApp();
   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
   ```
2. **Permission Request:** Triggered post-login or on user opt-in prompt (see Section 13).
3. **Token Syncing:**
   - Retrieves token: `await FirebaseMessaging.instance.getToken()`.
   - Sends to backend: `POST /api/v1/device-tokens` via `ApiClient`.
   - Listens to token refresh:
     ```dart
     FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
       _apiClient.post('/api/v1/device-tokens', body: {'fcm_token': newToken, 'platform': 'android'});
     });
     ```
4. **Foreground Handling (`onMessage`):**
   - When app is active on screen, the system tray does not show FCM notifications by default.
   - `PushNotificationService` receives `onMessage`, verifies active context, and displays an animated in-app snackbar or banner with a "View" button that navigates directly to the target entity.
5. **Background / Terminated Handling:**
   - Background execution entry point: `@pragma('vm:entry-point') Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message)` ensures native Android engine wakes up cleanly.
   - User tap on notification tray opens the app and is processed via:
     - Terminated state: `FirebaseMessaging.instance.getInitialMessage()`.
     - Background state: `FirebaseMessaging.onMessageOpenedApp.listen(...)`.

---

## 13. Notification Permissions Strategy

### 13.1 Android 13+ (API 33+) Runtime Permissions
- Android 13 introduces `android.permission.POST_NOTIFICATIONS`.
- Mecha Connect will declare `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` in `AndroidManifest.xml`.
- Runtime request is triggered using `FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true)`.

### 13.2 Graceful Degradation on Permission Denial
- If the user denies notification permission:
  - App state remains completely functional.
  - App records denial locally in `SharedPreferences` (`notifications_permission_denied = true`).
  - No repeated intrusive permission popups on every screen navigation.
  - Profile notification settings screen displays an informative banner: "Notifications are disabled in system settings. Tap here to enable in Android Settings."
- Under no circumstances does permission denial prevent vehicle booking, fuel ordering, or AI chat.

---

## 14. Deep-Link & Navigation Contract

### 14.1 Route & Screen Resolution
Mecha Connect uses standard Flutter Navigator (`Navigator.push`, `MaterialPageRoute`, `BottomNavigation` indexed stack). Deep link resolution translates FCM payload data into concrete Flutter screens:

| `entity_type` | Payload Data | Target Flutter Screen | Navigation Action |
| :--- | :--- | :--- | :--- |
| `booking` | `entity_id: <bookingId>` | `LiveTrackingScreen(bookingId: bookingId)` | `Navigator.push(context, MaterialPageRoute(builder: (_) => LiveTrackingScreen(bookingId: bookingId)))` |
| `fuel_order` | `entity_id: <orderId>` | Fuel `LiveTrackingScreen()` | `Navigator.push(context, MaterialPageRoute(builder: (_) => const fuel.LiveTrackingScreen()))` |
| `marketplace_order` | `entity_id: <orderId>` | `Orderscreen(initialTab: 1)` | `Navigator.push(context, MaterialPageRoute(builder: (_) => const Orderscreen()))` |

### 14.2 Authentication Guard for Deep-Links
*Rule: Sensitive customer data and live tracking must NEVER be displayed without active authentication.*

When a user taps a notification:
1. `PushNotificationService` checks `authProvider.isLoggedIn` (or `SharedPreferences.getBool('is_logged_in')`).
2. **If Logged In:** Immediately navigates to `LiveTrackingScreen(bookingId: entityId)`.
3. **If Logged Out / Session Expired:**
   - Temporarily caches pending navigation payload: `SharedPreferences.setString('pending_notification_payload', jsonEncode(data))`.
   - Routes user to `LoginScreen()`.
   - Upon successful login completion, `LoginScreen` inspects `pending_notification_payload`, navigates to `LiveTrackingScreen`, and clears the cache.

---

## 15. Security Architecture

### 15.1 Authenticated Token Registration & IDOR Prevention
- `POST /api/v1/device-tokens` and `DELETE /api/v1/device-tokens` require valid JWT Bearer authentication (`Depends(get_current_user)`).
- The client does NOT supply `user_id` in the request body. The backend exclusively extracts `user_id` from `current_user.id`.
- A user can never register, view, or delete device tokens belonging to another user.

### 15.2 Logout & Unregistration Behavior
- When the user logs out from `ProfileScreen` / `AuthService`:
  - Flutter calls `DELETE /api/v1/device-tokens` with the current device's `fcm_token`.
  - Backend deletes or marks `is_active = FALSE` for that token.
  - This guarantees that subsequent notifications for the account are not delivered to a shared or handed-over physical phone.

### 15.3 Secrets & Credentials Management
- **Zero Secrets in Git:**
  - `firebase_credentials.json` (Service Account Private Key) is added to `backend/.gitignore`.
  - `google-services.json` is added to `frontend/.gitignore` (sample template `google-services.json.example` provided).
  - Path to service account is loaded dynamically via `FIREBASE_CREDENTIALS_PATH` in `backend/.env`.
- **FCM Token Privacy:** Device tokens are treated as confidential identifiers; they are never logged at INFO/ERROR level in production and are never exposed in public API responses.

---

## 16. Reliability & Failure Strategy

| Failure Scenario | System Behavior | Recovery / Mitigation |
| :--- | :--- | :--- |
| **Firebase API Down / Timeout** | FCM adapter times out after 3.0s, catches exception, logs error. | Domain operation (e.g. booking update) succeeds completely. No client-facing 500 error. |
| **Invalid / Unregistered Token** | FCM returns `registration-token-not-registered`. | `NotificationService` automatically deletes the token from `device_tokens`. |
| **Network Failure during Registration** | Flutter token upload fails. | Flutter retries registration on next app launch or network reconnection. |
| **Duplicate Token Registration** | User registers same token twice. | Database UPSERT updates timestamp; no duplicate rows created. |
| **User Has Multiple Devices** | Customer owns a phone and tablet. | Multicast sends to all active tokens for that user. |
| **User Disabled Push in Settings** | `NotificationSetting.push == False`. | Backend skips dispatch before calling FCM. Zero quota/bandwidth used. |
| **User Denied OS Notification Permission** | Android OS blocks alert. | Backend dispatches; FCM delivers to device; OS silently drops; app functions normally. |

---

## 17. Notification History Decision

### Decision: **Option A — `device_tokens` Only (Deferred History Table)**

### Evaluation & Rationale:
1. **Product Scope:** Mecha Connect currently does NOT have an in-app "Notification Center / Inbox" UI screen. The notification button in the drawer and home screen navigates to `NotificationSettingsScreen` (toggles for Push, Email, SMS).
2. **Database Overhead & Schema Hygiene:** Storing every transient push notification in a database table without an inbox feature introduces write amplification, row bloat, and unneeded table maintenance.
3. **Additive Roadmap:** When an In-App Notification Center UI is designed in a future stage, adding a `notifications` table with an Alembic migration is 100% additive and requires zero changes to the `device_tokens` or `FCMAdapter` foundation.

---

## 18. Dispatch Strategy Decision

### Decision: **Option B — Asynchronous Post-Commit via FastAPI `BackgroundTasks`**

### Evaluation & Rationale:
1. **Option A (Synchronous in Request):** Causes 150ms–500ms network latency to Google servers during booking updates. If Google is slow, the mobile client hangs. Unacceptable for real-time mobile UX.
2. **Option C/D (External Queue - Celery/RabbitMQ/Redis):** Adds external infrastructure, worker processes, broker monitoring, and Redis/RabbitMQ maintenance. Mecha Connect does not currently run Celery/Redis workers.
3. **Option B (FastAPI `BackgroundTasks` / `asyncio.create_task`):**
   - Dispatches immediately after the database commit and HTTP response.
   - Zero added external dependencies.
   - Total isolation: failures cannot affect HTTP status or DB transactions.
   - Smooth upgrade path to Celery or Redis Streams if traffic scales to >10,000 requests/sec.

---

## 19. Firebase Prerequisites (User / External Setup)

Before implementation can be executed or manually verified on Android, the user must provide the following external assets:

1. **Firebase Project:** Create a project in [Firebase Console](https://console.firebase.google.com/).
2. **Android Application Registration:**
   - Package Name: `com.example.mecha_connect` (matching `frontend/android/app/build.gradle.kts`).
   - App Nickname: Mecha Connect Android.
3. **Google Services Config File:**
   - Download `google-services.json` from Firebase Console.
   - Place in: `c:\mecha_connect - opencode\frontend\android\app\google-services.json`.
4. **Firebase Admin Service Account Key:**
   - In Firebase Console → Project Settings → Service Accounts → Generate new private key.
   - Place JSON in: `c:\mecha_connect - opencode\backend\firebase_credentials.json`.
   - Add path to `backend/.env`: `FIREBASE_CREDENTIALS_PATH=./firebase_credentials.json`.
5. **SHA-1 / SHA-256 Fingerprint (Optional for basic push, required for phone auth/app check):**
   - Add debug keystore SHA-1 to Firebase Android App settings if needed.

*Note: Code architecture is designed to boot cleanly with a `MockFCMAdapter` when credentials are not yet present, allowing all automated tests to pass.*

---

## 20. Exact File Plan

### 20.1 New Files
#### Backend
1. `backend/app/models/device_token.py` — `DeviceToken` SQLAlchemy 2.0 model.
2. `backend/app/repositories/device_token.py` — `DeviceTokenRepository` for CRUD and upsert.
3. `backend/app/schemas/device_token.py` — Pydantic schemas: `DeviceTokenCreate`, `DeviceTokenResponse`, `DeviceTokenDelete`.
4. `backend/app/services/fcm_adapter.py` — `FCMAdapterProtocol`, `FirebaseAdminAdapter`, and `MockFCMAdapter`.
5. `backend/app/api/v1/device_tokens.py` — Device token registration/unregistration API endpoints.
6. `backend/alembic/versions/0007_device_tokens.py` — Migration 0007 creating `device_tokens` table with constraints & indexes.
7. `backend/tests/test_device_tokens.py` — Unit & integration tests for token endpoints and repository.
8. `backend/tests/test_fcm_notifications.py` — Unit tests for notification service, preferences, and mock dispatch.

#### Frontend
9. `frontend/lib/services/push_notification_service.dart` — Core client push orchestration (permissions, token registration, foreground/background listeners, deep-link routing).
10. `frontend/test/push_notification_service_test.dart` — Widget & unit tests for push client logic.

### 20.2 Modified Files
#### Backend
1. `backend/app/core/config.py` — Add `ENABLE_PUSH_NOTIFICATIONS: bool = True`.
2. `backend/app/models/__init__.py` — Export `DeviceToken`.
3. `backend/app/api/router.py` — Include `device_tokens.router` under `/device-tokens`.
4. `backend/app/services/notification_service.py` — Extend to inject `DeviceTokenRepository` and `FCMAdapterProtocol`; add `dispatch_booking_status_notification`.
5. `backend/app/services/mechanic_service.py` — Call `notification_service.dispatch_booking_status_notification` post-commit in `update_booking_status` and `cancel_booking`.

#### Frontend
6. `frontend/pubspec.yaml` — Add `firebase_core: ^3.6.0`, `firebase_messaging: ^15.1.3`.
7. `frontend/lib/main.dart` — Call `Firebase.initializeApp()` and register background message handler.
8. `frontend/lib/app_wiring.dart` — Register `PushNotificationService` in root providers.
9. `frontend/android/build.gradle.kts` — Add `com.google.gms:google-services` buildscript classpath.
10. `frontend/android/app/build.gradle.kts` — Apply `com.google.gms.google-services` plugin.
11. `frontend/android/app/src/main/AndroidManifest.xml` — Add `POST_NOTIFICATIONS` permission and default notification channel metadata.

### 20.3 Unchanged Files
- All existing Alembic migrations (`0001` through `0006`).
- All existing domain models (`User`, `Mechanic`, `MechanicBooking`, `OrderEntry`, `Vehicle`, `Address`, `Wallet`).
- All existing Flutter UI screens, themes, assets, and providers.
- Booking state machine definitions and transition constraints.

---

## 21. API Contracts

### 21.1 Register / Upsert Device Token
- **Endpoint:** `POST /api/v1/device-tokens`
- **Security:** Bearer Token (`current_user`)
- **Request Body (`DeviceTokenCreate`):**
  ```json
  {
    "fcm_token": "eK3x...L9a0",
    "platform": "android",
    "device_id": "c4b3...9a",
    "app_version": "1.0.0+1"
  }
  ```
- **Response (`201 Created` / `DeviceTokenResponse`):**
  ```json
  {
    "id": "7a3e14f0-8c92-4b6e-9e7f-1d8c2e3f4a5b",
    "fcm_token": "eK3x...L9a0",
    "platform": "android",
    "device_id": "c4b3...9a",
    "app_version": "1.0.0+1",
    "is_active": true,
    "created_at": "2026-09-09T13:45:00Z",
    "updated_at": "2026-09-09T13:45:00Z"
  }
  ```
- **Error Responses:**
  - `401 Unauthorized`: Missing or invalid JWT.
  - `422 Unprocessable Entity`: Invalid platform (must be 'android', 'ios', or 'web') or empty token.

### 21.2 Delete / Unregister Device Token
- **Endpoint:** `DELETE /api/v1/device-tokens`
- **Security:** Bearer Token (`current_user`)
- **Request Body (`DeviceTokenDelete`):**
  ```json
  {
    "fcm_token": "eK3x...L9a0"
  }
  ```
- **Response:** `204 No Content`
- **Behavior:**
  - Deletes token if owned by `current_user.id`.
  - If token does not exist or belongs to another user, returns `204 No Content` (idempotent, prevents user enumeration).

---

## 22. Test Strategy

### 22.1 Backend Tests
1. **Token Registration Tests (`test_device_tokens.py`):**
   - Register token for authenticated user → `201 Created`.
   - Register duplicate token for same user → updates timestamp, maintains 1 row.
   - Register existing token for different user (device transfer) → reassigns `user_id` to new user.
   - Register multiple tokens for same user (multi-device) → stores distinct rows.
   - Delete token on logout → `204 No Content`, verified removed from DB.
   - Cross-user deletion attempt → cannot delete another user's token.
2. **Notification Dispatch Tests (`test_fcm_notifications.py`):**
   - Dispatch booking notification with `MockFCMAdapter` → message recorded in mock with correct title/body/data.
   - User with `push = False` → delivery skipped, zero calls to FCM adapter.
   - User with no device tokens → delivery skipped gracefully.
   - FCM returns invalid token error → `NotificationService` automatically deletes stale token from `device_tokens`.
   - FCM throws connection error → error caught and logged; booking status update still returns `200 OK`.

### 22.2 Flutter Tests
1. **`PushNotificationService` Unit Tests:**
   - Initialization without Firebase throws handled exception or operates in mock mode.
   - Permission status mapped correctly.
   - Token refresh triggers API client `POST /api/v1/device-tokens`.
   - Deep-link parser maps `booking` payload to `LiveTrackingScreen`.
   - Unauthenticated payload tap redirects to `LoginScreen` with payload preservation.

### 22.3 Accounting for Existing Flutter Test State
The one currently failing test (`test/features/marketplace/screens/marketplace_module_test.dart` — Quick Service Parts tile opens Marketplace) is in an unrelated feature module. Push notification tests will be isolated in `test/services/push_notification_service_test.dart` and will not touch or break marketplace tests.

---

## 23. Manual Verification Matrix (Android Emulator)

When implementation is approved and credentials are supplied, runtime verification must follow this 16-step matrix on a real Android emulator (API 34/35):

| Step | Action | Expected Result |
| :--- | :--- | :--- |
| **1** | Fresh install on Android Emulator | App boots cleanly to SplashScreen → Onboarding. |
| **2** | Firebase Initialization | `Firebase.initializeApp()` completes without error; debug logs confirm. |
| **3** | OS Permission Dialog | Android 13+ permission prompt displayed. User taps "Allow". |
| **4** | Login | User logs in as customer; JWT stored. |
| **5** | FCM Token Registration | Flutter retrieves FCM token and calls `POST /api/v1/device-tokens`; DB shows row in `device_tokens`. |
| **6** | Booking Creation | Customer books a mechanic service; status is `requested`. |
| **7** | Status: `accepted` | Backend advances booking to `accepted`; FCM dispatches post-commit. |
| **8** | App in Background | Customer presses Home button; Mecha Connect is backgrounded. |
| **9** | Status: `enRoute` | Backend advances booking to `enRoute`. |
| **10** | System Tray Notification | Android system tray shows: "Mechanic On The Way" with car icon. |
| **11** | Notification Tap | User taps notification in Android drawer. |
| **12** | Deep-Link Navigation | Mecha Connect opens directly to `LiveTrackingScreen(bookingId: ...)` showing active route. |
| **13** | App in Foreground | Status advances to `arrived` while user is viewing app; in-app banner appears. |
| **14** | Push Disabled | User toggles push off in Profile settings; status advances to `completed`; no notification sent. |
| **15** | Logout | User logs out; `DELETE /api/v1/device-tokens` called; token deactivated in DB. |
| **16** | Terminated State Tap | App swiped away (force closed); notification tapped; app boots through splash directly to booking tracking. |

---

## 24. Regression Boundaries

The following existing, verified components are strictly frozen and must remain unmodified:
1. **Booking State Machine:** Transitions remain `requested → accepted → mechanicAssigned → enRoute → arrived → completed` and `cancelled`.
2. **Catalog & Seeding:** Mechanic catalog, categories, services, and pricing remain untouched.
3. **Authentication & JWT:** Existing auth flows, token generation, password hashing, and user roles remain intact.
4. **Existing Migrations:** Migrations `0001` through `0006` are frozen. The new migration must be `0007_device_tokens.py` and must be strictly additive.
5. **AI Diagnostics & Conversation:** RAG, FAISS, XGBoost, and conversation ownership are unaffected.
6. **Vehicle & Address APIs:** Existing schemas and endpoints remain unchanged.

---

## 25. Risks & Mitigation

| Risk | Severity | Mitigation Strategy |
| :--- | :--- | :--- |
| **Firebase Credential Leak** | HIGH | Service account JSON and Google Services config added to `.gitignore`. Backend loads credentials from `.env` path. |
| **Notification Dispatch Latency** | MEDIUM | Post-commit asynchronous dispatch ensures zero impact on HTTP request latency for booking updates. |
| **Stale / Orphaned Tokens** | MEDIUM | Automatic token pruning triggered upon receiving Firebase `NOT_FOUND` / `INVALID_ARGUMENT` response codes. |
| **Android Gradle Version Conflict** | MEDIUM | Gradle buildscript classpath `com.google.gms:google-services` pinned to compatible version for Flutter 3.32+ / Kotlin DSL. |
| **App Crash on Missing Credentials** | HIGH | `FCMAdapter` uses safe fallback mock mode when credentials file is absent, preserving local development and CI testing. |

---

## 26. Explicit Decisions (Summary)

1. **Table Design:** New table `device_tokens` with UUID PK, `user_id` FK (CASCADE), `fcm_token` UNIQUE, `platform`, timestamps.
2. **Multi-Device Support:** 1-to-many relationship between users and devices; FCM multicast dispatch.
3. **Ownership Transfer:** Upsert reassigns token to new user on account switch on the same device.
4. **Isolation:** Notifications execute strictly POST-COMMIT; FCM failures cannot fail or rollback booking transactions.
5. **Notification History:** Deferred (Option A: `device_tokens` only) until In-App Notification Center UI is designed.
6. **Dispatch Mechanism:** FastAPI `BackgroundTasks` (Option B: asynchronous, non-blocking, zero external queue overhead).
7. **Adapter Pattern:** Domain services call `NotificationService`; `NotificationService` calls `FCMAdapterProtocol`; mocked in tests.
8. **Navigation:** Standard Flutter `MaterialPageRoute` deep-linking to `LiveTrackingScreen` with authentication guard.

---

## 27. Explicit Non-Decisions / Deferred Work

The following items are deliberately out of scope for this architecture and deferred to subsequent sprints:
1. **In-App Notification Center / Inbox Screen:** Creating an inbox UI and persistent `notifications` table is deferred until a dedicated UX design is provided.
2. **Fuel & Marketplace Dispatch Wiring:** Wiring push dispatches into Fuel and Marketplace service transitions will occur after Mechanic push is verified.
3. **Web Push (VAPID):** Browser push notifications for web platforms are deferred; scope is locked to Android (and future iOS).
4. **SMS / Email Gateway:** Existing toggles for email and SMS remain preference records; actual Twilio/SendGrid integration is out of scope.

---
**END OF ARCHITECTURE DECISION RECORD**
