# Phase 1 / Task 3: Service Booking UX/UI & Production Flow Hardening
## Comprehensive Reconnaissance Report

**Date:** September 9, 2026  
**Author:** Senior Full-Stack Engineer, Architect, QA & Release Lead  
**Corpus:** Jagadeeshrelangi/mc_repo  
**Branch:** main  

---

### 1. Current Architecture
Mecha Connect is a multi-tier automotive service and marketplace application:
- **Frontend:** Flutter (v3.29.0 / Dart 3.7.0) on Android, using Provider for state management, Material 3 theming, GoRouter-based navigation, and an `ApiClient` abstraction with auth interceptors and secure token storage.
- **Backend:** FastAPI (Python 3.12), SQLAlchemy 2.x async, asyncpg, Alembic migrations, Supabase PostgreSQL, Pydantic v2 schemas, JWT Bearer authentication, and ownership-scoped queries.
- **AI/ML:** Google Gemini 2.5 Flash for diagnosis and automotive Q&A; XGBoost + FAISS for recommendation and retrieval.
- **Wiring & Communication:** Frontend talks to backend via HTTP REST endpoints under `/api/v1/mechanic/*`, `/api/v1/vehicles/*`, `/api/v1/auth/*`, etc. Local Android emulator connects over `adb reverse tcp:8000 tcp:8000` to `http://127.0.0.1:8000`.

---

### 2. Current Booking Flow
The canonical end-to-end journey intended by the product is:
1. **Discovery:** User searches or filters mechanics by category/query (`MechanicHomeScreen`).
2. **Details:** User views profile, rating, skills, working hours, and offered services (`MechanicDetailScreen`).
3. **Service Selection:** User picks an offered catalog service or specifies a custom problem (`SelectServiceScreen`).
4. **Vehicle Form:** User specifies or confirms the vehicle (make, model, year, fuel, license plate) and service address with contact details (`VehicleFormScreen`).
5. **Booking Summary:** Review all parameters, pricing, arrival ETA, and scheduled appointment (`BookingSummaryScreen`).
6. **Confirmation:** System creates booking with backend and displays reference number and summary (`BookingConfirmationScreen`).
7. **Live Tracking:** User tracks lifecycle stages (`requested` → `accepted` → `mechanicAssigned` → `enRoute` → `arrived` → `completed` or `cancelled`) with event timeline snapshots (`LiveTrackingScreen`).
8. **Completion & Invoice:** Displays completed summary, labor charge, parts/supplies, taxes, and total payable (`JobCompletedScreen`).
9. **Rating & Review:** User rates the completed service (1-5 stars + text) persisted to backend (`RatingReviewScreen`).
10. **Booking History:** User reviews past and active bookings, inspects details, invoices, or resumes tracking (`BookingHistoryScreen`).

---

### 3. Current Frontend Flow
- Routes registered in `lib/app_wiring.dart`:
  - `/mechanic` → `MechanicHomeScreen`
  - `/mechanic/detail` → `MechanicDetailScreen`
  - `/mechanic/select-service` → `SelectServiceScreen`
  - `/mechanic/vehicle-form` → `VehicleFormScreen`
  - `/mechanic/booking-summary` → `BookingSummaryScreen`
  - `/mechanic/booking-confirmation` → `BookingConfirmationScreen`
  - `/mechanic/live-tracking` → `LiveTrackingScreen`
  - `/mechanic/job-completed` → `JobCompletedScreen`
  - `/mechanic/rating-review` → `RatingReviewScreen`
  - `/mechanic/booking-history` → `BookingHistoryScreen`
- State Management: `MechanicProvider` (with `MechanicRepository`) manages `_mechanics`, `_categories`, `_services`, `_bookings`, `_activeBooking`, `_bookingEvents`, `_bookingRating`, loading flags, and error strings.
- Flow passes data through both Provider (`setActiveBooking`, `createBooking`) and route `extra` parameters for deep-linking resilience.

---

### 4. Current Backend Flow
Backend handles mechanic and booking operations in `backend/app/api/v1/mechanic.py` via `MechanicService` and `MechanicRepository`:
- Catalog queries: `GET /mechanics`, `GET /mechanics/{id}`, `GET /mechanics/{id}/services`, `GET /services`, `GET /categories`.
- Booking operations (all owner-scoped via `get_current_user`):
  - `GET /bookings`: lists current user's bookings (ordered descending by creation).
  - `POST /bookings`: validates payload, inserts `Booking` in `requested` state, initializes first `BookingEvent`, syncs an `Order` entry if applicable.
  - `GET /bookings/{id}`: returns booking details if owned by user, else 404.
  - `POST /bookings/{id}/cancel`: verifies state != `completed` or `cancelled`, transitions to `cancelled`, creates cancellation event.
  - `POST /bookings/{id}/complete`: transitions to `completed`, creates completion event.
  - `PATCH /bookings/{id}`: handles transitions (`accepted`, `mechanicAssigned`, `enRoute`, `arrived`, `completed`, `cancelled`) with validation and event appending.
  - `GET /bookings/{id}/events`: returns snapshots in chronological order.
  - `POST /bookings/{id}/rating`: validates booking is `completed`, unrated, owned, saves `Rating`, updates mechanic aggregate score.
  - `GET /bookings/{id}/rating`: returns persisted rating for booking.

---

### 5. Current Database Flow
- Tables: `mechanics`, `mechanic_categories`, `mechanic_services`, `mechanic_service_junction`, `mechanic_reviews`, `bookings`, `booking_events`, `ratings`, `orders`, `order_entries`.
- All foreign keys and cascading rules are managed with Alembic migrations.
- `bookings` has columns for `id`, `user_id`, `mechanic_id`, `service_id`, `vehicle_details` (JSON), `address_details` (JSON), `status`, `total_price`, `scheduled_at`, `created_at`, `updated_at`.
- `booking_events` contains `id`, `booking_id`, `status`, `notes`, `payload` (JSON), `created_at`.
- Transaction boundaries are strictly atomic in `MechanicService`.

---

### 6. Current State-Management Flow
- `MechanicProvider` encapsulates calls to `MechanicRepository`.
- Exposes `isLoading`, `error`, `selectedMechanic`, `selectedService`, `activeBooking`, `bookingEvents`, `activeBookingRating`.
- `MechanicRepository` accepts an optional `ApiClient`. When authenticated, `ApiClient` executes REST calls.

---

### 7. Existing Reusable Components
- `CustomButton`: styled action buttons with loading indicators and variant styling.
- `CustomTextField`: standardized text input with validation and icons.
- `StatusBadge`: semantic badge for booking and order statuses.
- `ShimmerLoading`: animated skeleton loader for discovery and details screens.
- `EmptyStateView`: icon, title, description, and action button for zero-data views.
- `PriceTag`: formatted Indian Rupee (₹) currency display.
- `RatingBar`: interactive and display-only star ratings.

---

### 8. Existing UX Problems
1. **Silent Fallback into Fake Booking:** In `MechanicRepository.createBooking`, if the API returns an error (401, 422, 500), it catches the exception and constructs a fake local booking (`MEC${timestamp}`) with mock data! The user thinks a booking was made on the server, but it only exists in volatile device memory and never reached the mechanic or database.
2. **Pilot Controls Intermingled with Customer Tracking:** On `LiveTrackingScreen`, operational simulation buttons (`Acknowledge Request (Pilot)`, `Assign Mechanic (Pilot)`, etc.) are rendered prominently at the bottom of the customer tracking screen without separation.
3. **Missing Exit Route on `JobCompletedScreen`:** The completed screen lacks an AppBar or home navigation button. If the user doesn't want to rate immediately, they can feel trapped.
4. **Disconnection Between History and Invoices:** Clicking a completed booking in `BookingHistoryScreen` opens a modal bottom sheet with basic metadata and a simple "Close" button. Users cannot view the detailed breakdown invoice or rate the booking from history.
5. **Hardcoded Fallbacks in `BookingSummaryScreen`:** If navigation `request` extra is null, summary falls back to hardcoded sample data (`Honda Activa 6G`, `Surampalem`, `KA 01 AB 1234`) instead of failing safely or loading the user's real vehicle/address.
6. **No Date/Time Slot Selection:** Booking creation hardcodes `scheduled_at` to `DateTime.now().toUtc().toIso8601String()`. The UI does not provide an option to select a scheduled appointment time.

---

### 9. Existing Functional Bugs
1. **Repository Error Swallowing:** `getBookingById`, `updateBookingStatus`, `cancelBooking`, and `completeBooking` all catch exceptions and fall back to searching local in-memory lists rather than propagating the error to let the UI display actionable retry/error state.
2. **Duplicate Booking Submission Risk:** On `BookingSummaryScreen`, although `_isSubmitting` prevents duplicate taps while spinning, network timeouts or rapid back-and-forth navigation could trigger multiple bookings.
3. **Rating Submission Flow Glitch:** `RatingReviewScreen` submits to backend, but upon success, only navigates to `/mechanic/booking-history` without refreshing the provider's active booking rating state.
4. **Android Back Button on Completed Screen:** Pressing Android back button on `JobCompletedScreen` could pop back to `LiveTrackingScreen` which showed completed status or create an awkward navigation loop.

---

### 10. Existing API/State Inconsistencies
- Backend expects ISO 8601 UTC strings for `scheduled_at`, which the client handles.
- Backend `BookingOut` returns status strings in lowerCamelCase (`mechanicAssigned`, `enRoute`). Frontend models match this enum correctly.
- `booking_events` are ordered chronologically; client renders them in reverse chronological or timeline order.

---

### 11. Security / Authorization Concerns
- All booking endpoints in `backend/app/api/v1/mechanic.py` are owner-scoped via `get_current_user`.
- No IDOR: Trying to read, cancel, complete, or rate another user's booking returns HTTP 404 (generic entity not found).
- Frontend securely attaches Bearer tokens via `AuthInterceptor`.
- **Security hardening required:** The client must NEVER silently fabricate server-side resources (like bookings or ratings) when API requests fail with 401/403/500.

---

### 12. Pilot/Demo Concerns
- The backend allows the owner to trigger status transitions via `PATCH /mechanic/bookings/{id}` for pilot verification purposes.
- In production, these status updates would be driven by the mechanic mobile app or dispatcher console.
- In the customer Flutter app, pilot simulation controls must be visually isolated in an expandable, clearly-marked "Pilot Simulator" panel so the primary customer experience remains clean, truthful, and representative of real-world usage.

---

### 13. Screens / Files Affected
- `frontend/lib/features/mechanic/repositories/mechanic_repository.dart`
- `frontend/lib/features/mechanic/providers/mechanic_provider.dart`
- `frontend/lib/features/mechanic/screens/booking_summary_screen.dart`
- `frontend/lib/features/mechanic/screens/live_tracking_screen.dart`
- `frontend/lib/features/mechanic/screens/job_completed_screen.dart`
- `frontend/lib/features/mechanic/screens/booking_history_screen.dart`
- `frontend/lib/features/mechanic/screens/rating_review_screen.dart`
- `frontend/lib/features/mechanic/screens/vehicle_form_screen.dart`
- `frontend/test/features/mechanic/*` (all relevant widget and unit tests)

---

### 14. Files That MUST NOT Be Touched Unnecessarily
- Backend models and migrations (database schema is already complete and verified).
- Unrelated feature modules: `marketplace`, `fuel`, `auth`, `diagnosis`, `wallet`.
- Core network client: `frontend/lib/core/network/api_client.dart`.

---

### 15. Required Changes
1. **Harden `MechanicRepository`:**
   - Remove silent fallback to fake `MEC...` mock bookings when an `ApiClient` is present.
   - Propagate API exceptions cleanly so the UI can show user-friendly error banners with retry capability.
   - Maintain offline fallback only when no API client is injected (for unit tests / mock mode).
2. **Harden `MechanicProvider`:**
   - Add clear error handling, resetting flags, and updating `_bookings` accurately upon cancel/complete/rating.
3. **Harden `BookingSummaryScreen`:**
   - Add scheduled date/time selection card allowing immediate ("ASAP / Within 45 mins") or scheduled appointment ("Select Date & Time").
   - Guard against null request state; prevent duplicate submission.
   - Validate and display accurate pricing, fees, and total.
4. **Harden `LiveTrackingScreen`:**
   - Isolate pilot advancement controls inside an expandable, collapsible "Bengaluru Pilot Simulator Controls" panel with a disclaimer tag.
   - Enhance the customer-facing view: live status banner, animated pulse, mechanic profile card with call/chat buttons, arrival ETA, timeline with timestamps, pull-to-refresh, and a safe cancellation dialog.
5. **Harden `JobCompletedScreen`:**
   - Add standard `AppBar` with title and "Close / Done" action.
   - Add "Rate Service" primary button and "Back to Home" outline button.
   - Provide an itemized invoice card (Labor, Consumables, Diagnostic Fee, Taxes, Total).
6. **Harden `BookingHistoryScreen`:**
   - Allow users to tap any completed booking card to open its full Invoice & Job Summary, or navigate to rate if unrated.
   - Allow active bookings to immediately open `LiveTrackingScreen`.
7. **Harden `RatingReviewScreen`:**
   - Handle already-rated bookings gracefully with read-only state.
   - On successful submission, refresh provider state and pop cleanly.

---

### 16. Optional Improvements That Should NOT Be Included
- No custom live GPS map rendering with fake moving car markers (no deceptive timers).
- No new database tables or migration scripts (existing tables cover all required fields).
- No visual redesign of discovery or category grids.

---

### 17. Testing Strategy
- **Backend Tests:** Run complete regression test suite (`pytest tests/ -q`) ensuring 704/704 pass.
- **Flutter Unit & Widget Tests:** Update existing mechanic tests and add tests for hardened error handling, pilot panel isolation, date/time scheduling, and invoice viewing.
- **Flutter Analyze:** Ensure 0 errors, 0 warnings, 0 lints.

---

### 18. Manual Android Verification Strategy
- Execute live verification on `emulator-5554`:
  1. Login with verified credentials.
  2. Discover mechanic from catalog.
  3. Select service and proceed to vehicle form.
  4. Fill vehicle details and choose scheduled date/time.
  5. Review summary with itemized costs.
  6. Confirm booking and receive genuine backend booking ID.
  7. Verify live tracking timeline with backend snapshots.
  8. Test pull-to-refresh.
  9. Exercise pilot progression to `completed`.
  10. Inspect itemized invoice on `JobCompletedScreen`.
  11. Submit star rating and review; verify persistence in backend.
  12. Navigate to `BookingHistoryScreen` and verify booking listed with status `completed` and rating.
  13. Test Android system back button behavior at each step.

---

### 19. Risks & Mitigation
- *Risk:* Removing silent repository mock fallback might break tests expecting mock data when no server is running.
  *Mitigation:* Retain fallback strictly when `_apiClient == null` or in mock testing mode; in all real authenticated runs, surface network/server exceptions cleanly.
- *Risk:* Changes to `LiveTrackingScreen` might hide pilot controls needed for integration tests.
  *Mitigation:* Keep the pilot controls accessible in a clean collapsible expansion tile, ensuring both human testers and automated flows can advance statuses seamlessly.

---

### 20. Recommended Implementation Order
1. Lock architecture decisions in `TASK_PHASE1_TASK3_ARCHITECTURE_DECISIONS.md`.
2. Harden `MechanicRepository` and `MechanicProvider` (exception propagation, error states).
3. Harden `BookingSummaryScreen` (date/time picker, duplicate prevention, clean summary).
4. Harden `LiveTrackingScreen` (pilot isolation, pull-to-refresh, cancellation confirmation).
5. Harden `JobCompletedScreen` and invoice rendering.
6. Harden `BookingHistoryScreen` (tap-to-track, tap-to-invoice/rate).
7. Harden `RatingReviewScreen` (already-rated handling, state synchronization).
8. Run Flutter unit & widget tests and fix any test discrepancies.
9. Run `flutter analyze` to ensure clean code.
10. Run complete backend regression suite (`pytest`).
11. Perform manual Android verification on emulator and capture screenshots.
12. Review all changed files.
13. Generate and read `TASK_PHASE1_TASK3_FINAL_VERIFICATION_REPORT.md`.
14. Create single commit and push to `origin/main`.
