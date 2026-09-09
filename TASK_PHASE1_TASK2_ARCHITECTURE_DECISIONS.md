# Phase 1 Task 2: Service Booking Lifecycle & Live Tracking Integration — Architecture Decisions

**Date:** 2026-09-09  
**Status:** LOCKED & APPROVED  
**Author:** Senior Staff Engineer / Technical Architect  
**Corpus:** Jagadeeshrelangi/mc_repo  

---

## 1. Executive Summary

This document establishes the authoritative architectural specifications for the Mecha Connect Service Booking Lifecycle and Live Tracking Integration for the Bengaluru pilot. It locks the canonical state machine, API contracts, transaction boundaries, security policies, and Flutter UX/UI state representations.

---

## 2. Canonical Booking Lifecycle & State Machine

### 2.1 The Seven Canonical States
The system strictly enforces the seven frozen status strings defined in `BookingStatus` (`backend/app/models/mechanic_status.py` and `frontend/lib/features/mechanic/models/mechanic_models.dart`):

1. `requested` — Initial state created by the customer.
2. `accepted` — Mechanic shop or partner accepts the service request.
3. `mechanicAssigned` — Specific field mechanic is dispatched/allocated.
4. `enRoute` — Mechanic is traveling toward the customer location.
5. `arrived` — Mechanic has reached the vehicle location.
6. `completed` — Service inspection and repair completed; invoice finalized.
7. `cancelled` — Booking terminated prior to completion.

### 2.2 Allowed State Transition Matrix
```
[requested] ───────────► [accepted] ───────────► [mechanicAssigned]
     │                        │                         │
     ▼                        ▼                         ▼
 [cancelled]              [cancelled]               [cancelled]
                              ▲                         ▲
                              │                         │
[enRoute] ─────────────► [arrived] ─────────────► [completed]
     │                        │                         │
     ▼                        ▼                         ▼
 [cancelled]              [cancelled]               (Terminal)
```

| Current Status | Allowed Next Statuses |
|---|---|
| `requested` | `accepted`, `cancelled` |
| `accepted` | `mechanicAssigned`, `cancelled` |
| `mechanicAssigned` | `enRoute`, `cancelled` |
| `enRoute` | `arrived`, `cancelled` |
| `arrived` | `completed`, `cancelled` |
| `completed` | *None* (Terminal State — Immutable) |
| `cancelled` | *None* (Terminal State — Immutable) |

### 2.3 Invalid Transitions
Any transition not explicitly listed in the matrix above (such as reversing status, modifying terminal bookings, or jumping steps) is rejected with `InvalidInputException` mapping to HTTP 400.

---

## 3. Security & Authorization Architecture

### 3.1 Identity Binding
- Client-supplied user identifiers are **NEVER** trusted.
- The caller's `user_id` is exclusively derived server-side from the verified JWT access token via `get_current_user` (`app.api.deps`).

### 3.2 IDOR Prevention
- Every booking query and mutation executes an owner-scoped SQL clause:
  ```sql
  WHERE mechanic_bookings.id = :booking_id AND mechanic_bookings.user_id = :current_user_id
  ```
- If the booking does not exist OR belongs to another user, the backend returns a generic 404 (`EntityNotFoundException("Booking not found.")`). No existence or ownership information is ever leaked.

### 3.3 Mass Assignment Prevention
- `BookingCreate` and `BookingStatusUpdate` schemas enforce `extra="forbid"`. Neither `user_id` nor unauthorized properties can be injected.

---

## 4. Transaction Boundaries & Data Consistency

Every write operation executes inside an atomic SQLAlchemy `AsyncSession` transaction:
1. Lock/fetch target record and assert state mutability.
2. Update `mechanic_bookings.status`.
3. Append a persistent audit record into `booking_events` with `occurred_at = now()`, `status`, and optional JSONB `payload`.
4. Update the cross-domain `order_entries` record (`status = "In Progress" | "Completed" | "Cancelled"`).
5. Execute `await session.commit()`. On any failure, `await session.rollback()` guarantees zero partial updates.

---

## 5. API Contracts & Serialization Architecture

### 5.1 Endpoint: Update Booking Status
- **Method:** `PATCH`
- **Path:** `/api/v1/mechanic/bookings/{booking_id}/status`
- **Auth:** Required (JWT)
- **Request Schema:** `BookingStatusUpdate`
  ```json
  {
    "status": "enRoute",
    "payload": {
      "note": "Mechanic on the way",
      "lat": 12.9716,
      "lng": 77.5946
    }
  }
  ```
- **Response:** `BookingOut` (HTTP 200)

### 5.2 Endpoint: Get Lifecycle Events
- **Method:** `GET`
- **Path:** `/api/v1/mechanic/bookings/{booking_id}/events`
- **Auth:** Required (JWT)
- **Response:** `List[BookingEventOut]` (HTTP 200) sorted by `occurred_at ASC`.

### 5.3 Enriched `BookingOut` Schema
To eliminate placeholder fallbacks in Flutter, `BookingOut` is enriched with eagerly-loaded catalog summaries:
```python
class BookingOut(_DecimalJsonMixin):
    id: UUID
    mechanic_id: str
    service_id: Optional[str] = None
    vehicle_id: Optional[UUID] = None
    status: BookingStatus
    address: Optional[str] = None
    lat: Optional[Decimal] = None
    lng: Optional[Decimal] = None
    scheduled_at: Optional[datetime] = None
    created_at: datetime
    mechanic: Optional[MechanicOut] = None
    service: Optional[MechanicServiceOut] = None
```
`MechanicBookingRepository` eager-loads relationships:
```python
options(
    selectinload(MechanicBooking.mechanic).options(*_mechanic_catalog_options()),
    selectinload(MechanicBooking.service)
)
```

---

## 6. Frontend State & UX/UI Architecture

### 6.1 Truthful Live Tracking Screen
- **No Faked Timer:** Remove the local 3-second Dart timer.
- **Truthful Progress Timeline:** Render the 5 sequential service stages (`requested`, `accepted`, `mechanicAssigned`, `enRoute`, `arrived`):
  - Completed milestones: marked with green checkmarks and real recorded event timestamps.
  - Active milestone: highlighted in brand orange with animated pulse/badge.
  - Future milestones: muted gray pending state.
  - If status is `completed` or `cancelled`: clearly display terminal banner and available actions (e.g. view invoice, rate service, or return to home).
- **Pilot Lifecycle Controller:** Include an intuitive, pilot-friendly action panel in `LiveTrackingScreen` enabling verification of status advancement directly against the live backend API.

### 6.2 Booking History Screen
- `loadBookingHistory()` must call `_repository.refreshHistory()` on initial load and pull-to-refresh to fetch live bookings from FastAPI.
- Tapping any card loads the enriched booking details and displays full mechanic profile, vehicle summary, price, and event timeline.

### 6.3 Booking Confirmation Screen
- Display the actual initial status (`Requested — Awaiting Mechanic Acceptance`) instead of a hardcoded "Mechanic Assigned" badge.

### 6.4 Custom Issue Fix
- In `select_service_screen.dart` / `mechanic_repository.dart`, ensure custom issues pass `service_id = null` to the backend, avoiding FK lookups on nonexistent service IDs.

---

## 7. Concurrency & Failure Recovery

1. **Double Submission:** All submit buttons (`Confirm Booking`, `Submit Review`, `Cancel Booking`) are disabled while `isSubmitting` is true.
2. **Terminal Invariance:** If two concurrent requests attempt to cancel and complete simultaneously, the first to commit locks the terminal state; the second is cleanly rejected with a 400 error.
3. **Network Retries:** Failed network requests display a non-blocking floating snackbar or error banner with an explicit "Retry" button.

---

## 8. Verification Strategy

1. **Automated Backend Tests:** Add unit and integration tests covering:
   - Status transition validation (valid vs invalid transitions).
   - Event persistence and timestamp ordering.
   - Owner-scoped authorization enforcement.
2. **Automated Frontend Tests:** Update repository and widget tests to verify:
   - Event fetching and milestone rendering.
   - Status update dispatch.
   - History refresh integration.
3. **Manual Android Verification:** Execute complete user journey on real Android emulator (`emulator-5554`) with adb screenshots validating each lifecycle transition.
