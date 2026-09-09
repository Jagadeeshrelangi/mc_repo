# Phase 1 Task 2: Service Booking Lifecycle & Live Tracking Integration — Reconnaissance Report

**Date:** 2026-09-09  
**Corpus:** Jagadeeshrelangi/mc_repo  
**Environment:** Flutter 3.32+ / Dart 3.8+ / FastAPI 0.115+ / SQLAlchemy 2.x async / PostgreSQL (Supabase)  
**Author:** Senior Staff Engineer / Technical Architect

---

## 1. Current Booking Architecture

### Backend Layer
- **API Router:** `backend/app/api/v1/mechanic.py` (prefix `/mechanic`, tags `["Mechanics"]`).
- **Service Orchestration:** `backend/app/services/mechanic_service.py` (`MechanicService`) manages transaction boundaries, ownership assertions, and lifecycle transitions.
- **Data Access Repositories:** `backend/app/repositories/mechanics.py`:
  - `MechanicBookingRepository`: Owner-scoped reads (`get_owned`, `list_for_user`) and writes (`create_booking`, `update_status`, `cancel`, `complete`).
  - `BookingEventRepository`: Persists chronological snapshots to `booking_events` (`append`, `list_for_booking`).
  - `RatingRepository`: Manages 1-1 post-service ratings (`create_rating`, `get_by_booking_id`).
- **Data Models:**
  - `MechanicBooking` (`backend/app/models/mechanic_booking.py`): Maps `mechanic_bookings` table with UUID primary key, `user_id` FK -> `users.id`, `mechanic_id` FK -> `mechanics.id`, `service_id` FK -> `mechanic_services.id`, nullable `vehicle_id`, and status CHECK constraint.
  - `BookingEvent` (`backend/app/models/mechanic_booking.py`): Maps `booking_events` table with JSONB `payload` and `occurred_at`.
  - `Rating` (`backend/app/models/mechanic_booking.py`): Maps `ratings` table 1-1 with booking.
  - `OrderEntry` (`backend/app/models/order_entry.py`): Unified cross-domain order table synced on create, cancel, and complete.

### Frontend Layer
- **Repository:** `frontend/lib/features/mechanic/repositories/mechanic_repository.dart` connects via `ApiClient` with local in-memory fallback.
- **State Management:** `frontend/lib/features/mechanic/providers/mechanic_provider.dart` (`MechanicProvider`) coordinates discovery, selection, active booking state, and booking history.
- **UI Screens:**
  - `mechanic_home_screen.dart`: Discovery, categories, featured/nearby mechanics.
  - `select_service_screen.dart`: Service selection and custom issue entry.
  - `booking_summary_screen.dart`: Review mechanic, service, vehicle, price, address.
  - `booking_confirmation_screen.dart`: Confirmation feedback and action buttons.
  - `live_tracking_screen.dart`: Map placeholder, mechanic card, status timeline, action buttons.
  - `job_completed_screen.dart`: Completion summary and invoice card.
  - `rating_review_screen.dart`: Post-service rating and review submission.
  - `booking_history_screen.dart`: Past bookings filterable by All, Active, Completed, Cancelled.

---

## 2. Existing Booking Lifecycle

### Canonical Lifecycle States
Single frozen contract defined in `backend/app/models/mechanic_status.py` and `frontend/lib/features/mechanic/models/mechanic_models.dart`:
```
requested → accepted → mechanicAssigned → enRoute → arrived → completed (+ cancelled)
```

### Current Status Handling
- **Creation:** Starts at `requested`. An initial `requested` event is logged in `booking_events`, and an `OrderEntry` with status `"In Progress"` is created.
- **Cancellation:** Transition to `cancelled` is permitted from any non-terminal state. Sets `cancelled` on booking, logs event, and updates `OrderEntry` to `"Cancelled"`.
- **Completion:** Transition to `completed` is permitted from non-terminal state. Sets `completed` on booking, logs event, and updates `OrderEntry` to `"Completed"`.
- **Missing Transition Endpoints:** The backend currently lacks an endpoint to transition through the intermediate operational states (`accepted`, `mechanicAssigned`, `enRoute`, `arrived`).
- **Frontend Disconnect:** `_ProgressTimeline` in `live_tracking_screen.dart` used a client-side `Timer.periodic(Duration(seconds: 3))` to simulate step progression instead of reflecting the actual backend state and event log.

---

## 3. Existing Database Schema

Migration `0004_mechanics.py` is at Alembic head `0006` on the live database.

### Table: `mechanic_bookings`
| Column | Type | Constraints |
|---|---|---|
| `id` | UUID | PRIMARY KEY, default `gen_random_uuid()` |
| `user_id` | UUID | NOT NULL, FK -> `users(id)` ON DELETE CASCADE |
| `mechanic_id` | TEXT | NOT NULL, FK -> `mechanics(id)` |
| `service_id` | TEXT | NULLABLE, FK -> `mechanic_services(id)` |
| `vehicle_id` | UUID | NULLABLE (no FK) |
| `status` | TEXT | NOT NULL, CHECK in 7 canonical statuses |
| `address` | TEXT | NULLABLE |
| `lat` | NUMERIC(9,6) | NULLABLE |
| `lng` | NUMERIC(9,6) | NULLABLE |
| `scheduled_at` | TIMESTAMPTZ | NULLABLE |
| `created_at` | TIMESTAMPTZ | NOT NULL, server_default `now()` |

### Table: `booking_events`
| Column | Type | Constraints |
|---|---|---|
| `id` | UUID | PRIMARY KEY, default `gen_random_uuid()` |
| `booking_id` | UUID | NOT NULL, FK -> `mechanic_bookings(id)` ON DELETE CASCADE |
| `status` | TEXT | NULLABLE |
| `occurred_at` | TIMESTAMPTZ | NOT NULL, server_default `now()` |
| `payload` | JSONB | NULLABLE |

### Table: `ratings`
| Column | Type | Constraints |
|---|---|---|
| `booking_id` | UUID | PRIMARY KEY, FK -> `mechanic_bookings(id)` ON DELETE CASCADE |
| `rating` | NUMERIC(3,2) | NULLABLE |
| `review` | TEXT | NULLABLE |

**Note:** The database schema is complete, valid, and fully migrated. No schema modifications or table migrations are needed.

---

## 4. Existing API Endpoints

### Public
- `GET /api/v1/mechanic/mechanics`: List all mechanics
- `GET /api/v1/mechanic/mechanics/featured`: List top-rated mechanics
- `GET /api/v1/mechanic/mechanics/{mechanic_id}`: Detail + services + hours
- `GET /api/v1/mechanic/mechanics/{mechanic_id}/services`: Offered services
- `GET /api/v1/mechanic/mechanics/{mechanic_id}/reviews`: Public reviews
- `GET /api/v1/mechanic/services`: Global catalog services
- `GET /api/v1/mechanic/categories`: Categories

### Protected (User Authenticated)
- `GET /api/v1/mechanic/bookings`: List authenticated user's bookings
- `POST /api/v1/mechanic/bookings`: Create booking (sets `requested`)
- `GET /api/v1/mechanic/bookings/{booking_id}`: Get booking by ID (owner-guarded)
- `POST /api/v1/mechanic/bookings/{booking_id}/cancel`: Cancel booking (owner-guarded)
- `POST /api/v1/mechanic/bookings/{booking_id}/complete`: Complete booking (owner-guarded)
- `GET /api/v1/mechanic/bookings/{booking_id}/events`: List chronological lifecycle events
- `POST /api/v1/mechanic/bookings/{booking_id}/rating`: Submit rating for completed booking
- `GET /api/v1/mechanic/bookings/{booking_id}/rating`: Read rating for booking

---

## 5. Existing Flutter Booking UX

1. **Discovery:** `MechanicHomeScreen` with categories and featured/nearby cards.
2. **Mechanic Selection:** Tapping a mechanic opens their profile and services list.
3. **Service Selection:** `SelectServiceScreen` presents offered services with prices and time estimates, plus a "Custom Issue" dialog.
4. **Booking Summary:** `BookingSummaryScreen` presents mechanic name, vehicle details, service breakdown, GST calculation, arrival ETA, and "Confirm Booking" button.
5. **Confirmation:** `BookingConfirmationScreen` provides visual confirmation with booking ID, ETA, and buttons to call mechanic or track live.
6. **Live Tracking:** `LiveTrackingScreen` displays map placeholder, mechanic card, status progression timeline, and action buttons (Call, Chat, Cancel, Service Completed).
7. **Completion & Rating:** `JobCompletedScreen` shows payment receipt and routes to `RatingReviewScreen` where star ratings and reviews are submitted.
8. **History:** `BookingHistoryScreen` displays historical cards with search and category filter chips.

---

## 6. Existing State-Management Flow

- `MechanicProvider` is initialized in app providers.
- `createBooking()` invokes repository, stores `_activeBooking`, and notifies listeners.
- `loadActiveBooking(id)` fetches single booking and updates `_activeBooking`.
- `cancelActiveBooking()` and `completeActiveBooking()` call API and update local state.
- **Gap:** `loadBookingHistory()` only accessed the local `_bookings` list and never called `refreshHistory()`.

---

## 7. What Already Works

- Seeded pilot catalog (8 mechanics, 8 services, categories, working hours, reviews) loaded cleanly in Supabase.
- Core booking creation, cancellation, completion, and rating API endpoints are 100% functional (285/285 backend tests passing).
- Unified `OrderEntry` synchronization for mechanics operates correctly.
- Post-service rating flow works and is covered by extensive widget tests.

---

## 8. What Is Incomplete

- **No Status Transition API:** There is no API route to progress a booking through `accepted`, `mechanicAssigned`, `enRoute`, or `arrived`.
- **Mock Timeline in Frontend:** `LiveTrackingScreen` advances via an isolated 3-second Dart timer instead of polling or reading the backend status and event log.
- **Incomplete Schema Serialization:** `BookingOut` returns only foreign key strings (`mechanic_id`, `service_id`), omitting nested summary objects (`mechanic`, `service`), causing Flutter to fall back to placeholder names when fetched by ID or list.
- **Unconsumed Events API:** Frontend does not query `GET /api/v1/mechanic/bookings/{id}/events` to render historical milestones with real timestamps.

---

## 9. What Is Broken

1. **Booking History Fetch Bug:** `MechanicProvider.loadBookingHistory()` calls `_repository.getBookingHistory()`, which returns only in-memory records. It never invokes `refreshHistory()`, so navigating to the Booking History screen yields an empty list when loading fresh from the backend.
2. **Custom Issue Service ID 404:** `SelectServiceScreen` generates a `MechanicService` with `id: 'svc_custom'`. When sent to `POST /api/v1/mechanic/bookings`, the backend attempts to look up `svc_custom` in `mechanic_services` and throws 404 "Service not found". Per the backend contract, custom issues require `service_id: null`.
3. **Hardcoded Confirmation Status Badge:** `BookingConfirmationScreen` displays a hardcoded "Mechanic Assigned" badge upon creation, even though the initial status is `Requested`.
4. **Data Loss on Re-fetch:** When `Booking.fromJson` parses backend responses without `mechanic` and `service` maps, mechanic phone, name, and service price revert to defaults.

---

## 10. What Must NOT Be Changed

- **Database Migrations:** Do not modify or roll back existing Alembic migrations.
- **Unrelated Domains:** Authentication, wallet, marketplace, fuel delivery, and AI diagnosis remain untouched.
- **Canonical Status Contract:** Keep the 7 frozen status strings: `requested`, `accepted`, `mechanicAssigned`, `enRoute`, `arrived`, `completed`, `cancelled`.
- **GPS Truthfulness:** Do not fake GPS streaming or WebSocket infrastructures. Implement honest milestone and status tracking.

---

## 11. Required Backend Changes

1. **Add Status Transition Endpoint:** Implement `PATCH /api/v1/mechanic/bookings/{booking_id}/status` accepting `BookingStatusUpdate` (`status: BookingStatus`, optional `payload: Optional[Dict[str, Any]]`).
2. **Validate State Machine Transitions:**
   - `requested` → `accepted`, `cancelled`
   - `accepted` → `mechanicAssigned`, `cancelled`
   - `mechanicAssigned` → `enRoute`, `cancelled`
   - `enRoute` → `arrived`, `cancelled`
   - `arrived` → `completed`, `cancelled`
   - Terminal states (`completed`, `cancelled`) cannot be modified.
3. **Log Milestones Atomically:** In `update_status`, record a `BookingEvent` in `booking_events` with the new status and timestamp, and update `OrderEntry.status`.
4. **Enrich Booking Response:** Eager-load `mechanic` and `service` relationships in `MechanicBookingRepository` and include `mechanic: Optional[MechanicOut]` and `service: Optional[MechanicServiceOut]` in `BookingOut`.

---

## 12. Required Database Changes

- **None.** Existing PostgreSQL schema on Supabase fully satisfies all data storage requirements.

---

## 13. Required Flutter Changes

1. **`MechanicRepository`:**
   - Fix `createBooking` to pass `null` for `service_id` when `service.id == 'svc_custom'`.
   - Implement `updateBookingStatus(String bookingId, BookingStatus status)`.
   - Implement `fetchBookingEvents(String bookingId)` to fetch `List<BookingEventModel>`.
   - Update `refreshHistory()` to populate full `Booking` objects using nested `mechanic` and `service` payloads.
2. **`MechanicProvider`:**
   - Update `loadBookingHistory()` to await `_repository.refreshHistory()`.
   - Add `updateBookingStatus(BookingStatus status)` to advance status via backend.
   - Add `fetchBookingEvents(String bookingId)` for milestone rendering.
3. **`LiveTrackingScreen`:**
   - Replace the fake 3-second `Timer.periodic` with real state progression derived from backend data and events.
   - Display milestone history with formatted timestamps.
   - Provide interactive capability for pilot simulation/verification (e.g. testing status progression).
4. **`BookingConfirmationScreen`:**
   - Update badge to reflect actual booking status (`Requested`).
5. **`Booking.fromJson`:**
   - Safely deserialize nested `mechanic` and `service` maps from `BookingOut`.

---

## 14. Required UX/UI Changes

- Ensure booking summary displays accurate costs, GST, vehicle summary, and selected address.
- Ensure all network actions have progress spinners and disabled submit buttons during flight to prevent duplicate submissions.
- Ensure empty state in booking history displays an inviting CTA ("No bookings yet - Book a mechanic").
- Ensure all screens handle small screens, scroll cleanly, and avoid layout overflows.

---

## 15. Security Risks & Mitigation

- **IDOR Risk:** User accessing another user's booking.
  - *Mitigation:* All booking queries (`get_owned`, `update_status`, `cancel`, `complete`, `events`, `ratings`) enforce SQL-level owner filter `user_id == current_user.id`. Foreign bookings return generic 404.
- **Mass Assignment:**
  - *Mitigation:* `BookingCreate` forbids extra fields (`extra="forbid"`) and does not take `user_id` or `status` from client.
- **Illegal State Transitions:**
  - *Mitigation:* Transition validation rejects unauthorized skips or modifications to terminal bookings.

---

## 16. Data Consistency Risks & Mitigation

- Multi-table writes (updating `mechanic_bookings`, inserting `booking_events`, updating `order_entries`) must be wrapped in a single database transaction. If any write fails, `session.rollback()` ensures zero partial commits.

---

## 17. Concurrency Risks & Mitigation

- Concurrent cancellation and completion requests:
  - Enforce status assertion against current database state. Once in `TERMINAL_STATUSES`, subsequent mutation attempts raise `InvalidInputException`.

---

## 18. Manual Android Verification Plan

1. **Authentication:** Log in with pilot user on emulator.
2. **Mechanic Discovery:** Navigate to Mechanics tab, select `Rajesh Auto Garage` (`m1`).
3. **Service Selection:** Select `General Service` (`svc_1`).
4. **Review & Book:** Verify summary details on `BookingSummaryScreen` and tap "Confirm Booking".
5. **Confirmation Verification:** Confirm booking created on live DB, verify status is `Requested`.
6. **Live Tracking:** Navigate to `LiveTrackingScreen`. Verify mechanic card, vehicle info, and progress timeline.
7. **Status Progression:** Advance status to `accepted` -> `mechanicAssigned` -> `enRoute` -> `arrived`. Verify timeline updates.
8. **Completion & Invoice:** Mark service completed, verify `JobCompletedScreen` with invoice breakdown.
9. **Rating Submission:** Submit 5-star rating and comment, verify "Thank You!" screen.
10. **History Verification:** Open `BookingHistoryScreen`, pull to refresh, verify the booking appears with "Completed" badge.
11. **Cancellation Test:** Create a second booking and cancel it. Verify it transitions to "Cancelled" in history and tracking.

---

## 19. Regression Risks & Mitigation

- **Backend Test Suite (700 tests):** All tests must pass before and after changes.
- **Flutter Test Suite (238 tests):** All tests must pass before and after changes.
- **Flutter Analyzer:** 0 warnings and 0 errors required.
- **Catalog & Orders Continuity:** Unified orders tab must continue to display mechanic orders accurately.
