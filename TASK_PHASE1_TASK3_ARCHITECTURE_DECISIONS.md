# Phase 1 / Task 3: Service Booking UX/UI & Production Flow Hardening
## Architecture Decisions & System Design

**Date:** September 9, 2026  
**Status:** LOCKED & APPROVED  
**Corpus:** Jagadeeshrelangi/mc_repo  
**Branch:** main  

---

### 1. Booking Flow UX
- The user journey must remain a single, unbroken narrative:
  `Mechanic Discovery → Mechanic Details → Select Service → Vehicle & Address Form → Booking Summary → Booking Confirmation → Live Tracking → Service Completed → Invoice → Rating & Review → Booking History`.
- All screens will share uniform padding, semantic color palettes (Emerald Green, Amber, Blue, Slate Gray), and elevation conventions.

### 2. Navigation
- GoRouter remains the declarative routing engine in `lib/app_wiring.dart`.
- Screens will receive both direct parameters (where passed via `extra`) and fallback to active state in `MechanicProvider`.
- Transitions will not trap the user:
  - From `BookingConfirmationScreen`: "Track Live Service" pushes `/mechanic/live-tracking`, and "Back to Home" resets back to `/home`.
  - From `JobCompletedScreen`: An explicit "Rate Experience" primary button and a secondary "Back to Home" button ensure clear forward and exit paths.
  - From `RatingReviewScreen`: Successful submission or skip pops back or routes to `/mechanic/booking-history`.

### 3. State Management
- `MechanicProvider` is the authoritative single source of truth for in-flight booking data on the client.
- When an action is taken (e.g. status transition, cancellation, rating submission), the provider updates its internal list `_bookings` and `_activeBooking` immediately with the response from the server, preventing stale views when navigating to history.

### 4. Loading States
- In-flight network operations (`createBooking`, `cancelBooking`, `updateBookingStatus`, `submitRating`) must toggle explicit boolean flags (`_isSubmitting` or `isLoading`) in the UI.
- Buttons must display a localized circular progress indicator without collapsing button dimensions or shifting page layout.

### 5. Error Handling
- **No silent error swallowing:** When an `ApiClient` is active (i.e. user is authenticated and talking to the backend), network or HTTP errors (401, 403, 404, 422, 500) will NOT be caught and replaced with mock objects. They must throw cleanly to the provider.
- In `MechanicProvider`, exceptions are captured into `_error` and surfaced via SnackBar / Banner to the user with understandable, non-technical messages.

### 6. Retry Behavior
- Screens with failed data fetching (such as loading tracking events or booking history) will provide a clear `Retry` CTA button in their error view.

### 7. Duplicate-Submit Prevention
- On `BookingSummaryScreen`:
  - `_isSubmitting` disables the "Confirm & Book Mechanic" button immediately upon click.
  - Form validation occurs before any asynchronous request.
  - Navigation immediately replaces the view to prevent double taps on device back.

### 8. Booking Confirmation Behavior
- `BookingConfirmationScreen` displays genuine server data: `booking.id`, `mechanic.name`, `service.name`, `scheduledAt`, and `totalPrice`.
- Status will display the actual server status badge (`requested` by default).

### 9. Tracking Behavior
- `LiveTrackingScreen` operates strictly on server-backed state:
  - No client-side timers pretending the mechanic is driving.
  - Pull-to-refresh (`RefreshIndicator`) triggers `provider.getBookingById` and `provider.getBookingEvents`.
  - The event timeline reflects chronologically ordered `booking_events` recorded by PostgreSQL.

### 10. Booking History Behavior
- Pulls live list from `GET /api/v1/mechanic/bookings`.
- Card interactions:
  - Tapping an active booking (`requested`, `accepted`, `mechanicAssigned`, `enRoute`, `arrived`) routes directly to `LiveTrackingScreen`.
  - Tapping a completed booking opens an enhanced modal bottom sheet with full cost breakdown and a button to view the official Invoice / Job Summary or Rate.

### 11. Cancellation Behavior
- Cancellation is permitted only when status is in `['requested', 'accepted', 'mechanicAssigned']`.
- Destructive action requires an explicit confirmation dialog ("Cancel Booking?").
- On confirmed cancellation, `POST /api/v1/mechanic/bookings/{id}/cancel` is invoked; the UI displays a SnackBar, updates status to `cancelled`, and disables further tracking progression.

### 12. Invoice Behavior
- `JobCompletedScreen` renders an itemized, mathematically consistent breakdown:
  - Base Service Labor: derived from catalog price.
  - Supplies & Consumables: transparently listed.
  - Taxes (GST 18%): calculated and displayed clearly.
  - Total: equals `booking.totalPrice`.
- The invoice includes the booking reference, timestamp, mechanic contact, and paid/pending indicator.

### 13. Rating Behavior
- 1 to 5 star interactive selection with quick feedback tags (e.g. "Punctual", "Expert Diagnosis", "Clean Work").
- Optional written review text.
- If a booking has already been rated, the screen displays the existing rating in read-only mode and informs the user.

### 14. Back Navigation
- `WillPopScope` / `PopScope` will be placed on sensitive screens (`BookingSummaryScreen`, `JobCompletedScreen`) to prevent accidental form re-submission or skipping out of completed flows ungracefully.

### 15. Android System-Back Behavior
- Pressing Android system back on `JobCompletedScreen` will route back to `/home` or `/mechanic/booking-history` rather than looping back into active tracking.

### 16. Empty States
- `BookingHistoryScreen` shows an illustrative empty view with a "Book a Service" CTA if no bookings exist.
- `MechanicHomeScreen` shows clear zero-results view if filters yield no mechanics.

### 17. Small-Screen Behavior
- All scrollable screens wrapped in `SingleChildScrollView` or `ListView` with responsive `SafeArea` padding.
- No fixed-width cards or rigid Row children that cause `RenderFlex` overflows on small Android phone viewports (e.g. 360dp width).

### 18. Accessibility
- All buttons have minimum 48x48dp touch targets.
- Star ratings provide semantic tooltips and labels.
- Text contrast complies with WCAG AA standards over dark/light themes.

### 19. Pilot / Demo Controls
- **Clear Isolation:** Pilot controls for triggering status progression (`Acknowledge`, `Assign Mechanic`, `En Route`, `Arrive`, `Complete`) are contained inside an expandable `ExpansionTile` titled `"Bengaluru Pilot Simulator Controls"` with a warning badge.
- **Production Separation:** The primary customer screen focuses entirely on viewing live tracking, mechanic details, call/chat actions, and invoice.

### 20. Production Role Separation
- Customer app: consumer of status, can cancel if eligible, rates when completed.
- Mechanic / Operations app (Pilot simulated): updates operational lifecycle states.

### 21. API Changes
- **No changes required:** The existing endpoints in `backend/app/api/v1/mechanic.py` provide complete functionality with owner-scoping, event logging, and status transitions.

### 22. Database Changes
- **No changes required:** Supabase PostgreSQL schema already has `bookings`, `booking_events`, `ratings`, `mechanics`, `mechanic_services`, etc.

### 23. Regression Risks & Mitigation
- Retain mock fallback in `MechanicRepository` *only* when `_apiClient == null` so headless unit tests without an active server continue to function as expected.
- Run complete 704 backend tests and all Flutter tests after modifications.

### 24. Manual Verification Plan
- Launch app on `emulator-5554`.
- Walk step-by-step through discovery, booking creation with custom date/time, confirmation, live tracking timeline, pilot progression, completion invoice, rating submission, and booking history inspection.
