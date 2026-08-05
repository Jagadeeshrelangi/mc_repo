# Mecha Connect — Complete Sprint Audit

**Date:** 2026-07-30  
**Scope:** Full repository audit — all 173 Dart files across 9 sprints  
**Method:** Source code verification only. No assumptions. Every claim backed by file inspection.

---

## Sprint 1.1 — Splash Screen (100%)

### Completed
- 3-layer animation: background radial fade → logo fade+scale → ambient glow breathing
- `CustomPaint` with `_RadialLightPainter` and `_AmbientGlowPainter`
- Logo asset `assets/no_bg.png` declared in `pubspec.yaml`
- SharedPreferences `onboarding_completed` check (default `false`)
- 450ms `FadeTransition` to next screen
- Dev flag `forceShowOnboarding` (`false` in production)
- Responsive logo sizing via `AppResponsive`
- Proper `AnimationController` lifecycle (3 controllers, all disposed)

### Missing
- Test coverage (none)

### Navigation
SplashScreen → reads `onboarding_completed` → LoginScreen (if true) or OnboardingScreen (if false)

### Files
`lib/main.dart:69-311` (SplashScreen + painters)

---

## Sprint 1.2 — Onboarding (100%)

### Completed
- 4 slides with distinct themes: Smart Vehicle Companion (orange), Roadside Help (blue), Everything Your Vehicle Needs (green), Ready to Drive Smarter? (orange)
- Floating icon clusters (Material `IconData`, positioned via `dx`/`dy` offsets)
- Glow background circles behind clusters
- Animated pill indicators (8px → 32px active width, 400ms easeInOut)
- Skip button (top-right, always visible)
- Next button (slides 0–2) → `pageController.nextPage()`
- Get Started button (slide 3) → writes `onboarding_completed = true` → LoginScreen
- Continue as Guest (last slide only) → writes `onboarding_completed = true` → LoginScreen
- SharedPreferences written on all 3 exit paths
- Dark mode support across all 7 widget files
- Responsive layout (font, icon, spacing scaling)
- `OnboardingModel` with `static const` slides (zero runtime overhead)
- Modular architecture: 5 widgets + 1 model + 1 screen file = 7 files, 663 lines

### Missing
- Test coverage (none)
- `Space Grotesk` font not declared in `pubspec.yaml` fonts section (falls back to system font)

### Navigation
OnboardingScreen → LoginScreen (Skip / Get Started / Continue as Guest)

### Files
`lib/starting_screen/screens.dart` (148 lines), `models/onboarding_model.dart` (177 lines), `widgets/*` (5 files, 338 lines)

---

## Sprint 1.3 — Login (75%)

### Completed
- Email/Username + Password fields with validation
- Password show/hide toggle
- Login button with loading spinner
- Forgot Password screen (UI + mock "reset link sent")
- Continue as Guest → writes `onboarding_completed = true` → BottomNavigation
- Reusable auth widgets: `auth_scaffold`, `auth_header`, `auth_divider`, `auth_text_field`, `password_field`, `primary_button`, `bottom_link`, `social_button`
- Dark/light mode support
- Responsive layout

### Partial
- **Auth logic is mock only**: `Future.delayed(1s)`, no credential verification, any input succeeds
- **No email format validation**: field labeled "Email or Username" checks only `trim().isEmpty`
- **Social login buttons rendered but `onPressed: null`**: Google + Apple buttons are decorative only
- **No user data persisted**: only `onboarding_completed` bool flag saved — no token, no user model, no session

### Missing
- Real authentication backend
- User session state management (`AuthProvider` does not exist)
- Error handling for network/auth failures
- Test coverage

### Dead Code
- `lib/starting_screen/login.dart` (335 lines) — older login screen with hardcoded credentials, **not used in navigation**

### Navigation
LoginScreen → BottomNavigation (via pushReplacement)  
LoginScreen → ForgotPasswordScreen → pop back  
LoginScreen → SignUpScreen → pop back

### Files
`lib/auth/login_screen.dart` (206 lines), `lib/auth/forgot_password_screen.dart` (117 lines), `lib/auth/*` (8 supporting files)

---

## Sprint 1.4 — Registration (65%)

### Completed
- Full Name field (non-empty validation)
- Email field (`@` presence check)
- Phone Number field (optional, **zero validation**)
- Password field (min 6 chars) + Confirm Password (match check)
- Password Strength indicator (4-level: weak/fair/good/strong with colored bars)
- Terms & Conditions checkbox (SnackBar if unchecked)
- Create Account button with loading state
- Reuses all auth widgets from Sprint 1.3

### Partial
- **Registration discards all data**: after `Future.delayed(1s)`, simply pops back to login screen
- **No auto-login**: user must re-enter credentials on login screen
- **Phone field has no validation**: not even digit-only check

### Missing
- **Vehicle info fields**: no name/model/registration number fields (sprint spec calls for this)
- User data persistence (no SharedPreferences, database, or backend call)
- Social sign-up buttons (`onPressed: null`)
- Backend registration API
- Test coverage

### Navigation
SignUpScreen → pop back to LoginScreen

### Files
`lib/auth/sign_up_screen.dart` (208 lines), `lib/auth/password_strength.dart` (103 lines)

---

## Sprint 1.5 — Home Dashboard (40%)

**Critical issue**: Two conflicting home screen implementations exist.

| Screen | Tab | File | Lines |
|---|---|---|---|
| `HomeDashboard` | Tab 0 | `lib/home/home_screen.dart` | 135 |
| `ServiceSelectionScreen` | Tab 1 (labeled "Services") | `lib/starting_screen/home.dart` | 731 |

Both display different user names (Jagadeesh vs Arjun), different layouts, and duplicate mock data.

### Completed
- HomeHeader: avatar, greeting ("Good Afternoon"), user name ("Jagadeesh"), notification bell icon
- LocationCard: "Delivering to Surampalem, Andhra Pradesh"
- VehicleCard: "Honda Activa 6G", health bar 92%, fuel bar 65%, battery/insurance indicators
- QuickServicesGrid: 6 service cards with icons (Mechanic, Fuel, AI Diagnosis, Parts, Battery, Towing)
- NearbyServicesList: 5 mock services (horizontal scroll)
- MarketplaceList: 4 mock products with prices
- RecentActivityList: 4 mock activities with status badges
- OfferBanner: "20% OFF" with promo code "MECHA20"
- Drawer (ProfileDrawer): 8 menu items + logout
- Dark mode support throughout all 12 home widgets
- Responsive layout (mobile + desktop via `AppResponsive`)

### Partial
- **Mechanic + Fuel quick services** navigate to real screens
- Drawer items mostly show "coming soon" SnackBars or navigate to wrong screen

### Missing / Non-functional
- **Emergency SOS card**: `onTap: null` — completely non-functional
- **AI Assistant card**: `onTap: null` on "Start AI Diagnosis" button
- **Search bar**: navigates to placeholder "Search coming soon!" page
- **Notification bell**: `onPressed: () {}` — no-op
- **Location card dropdown**: `onTap` has no handler
- **Vehicle card**: no interactivity (not tappable)
- **Nearby Services**: all items show "coming soon" SnackBars
- **Marketplace**: "Shop All" + product taps show "coming soon"
- **Recent Activity**: `onTap: () {}` — no-op
- **Offer banner**: shows "coming soon" SnackBar
- **Loading/Error/Empty states**: `HomeDashboard` is a `StatelessWidget` — **zero** state handling
- **Real data**: 100% mock from `lib/home/home_data.dart` (hardcoded constants)
- **Notifications system**: no push, no backend, bell icon does nothing
- **Wallet**: profile shows wallet cards but all navigation = "coming soon"
- Test coverage

### Navigation
Partial — only Mechanic → `VehicleFormPage` and Fuel → `FuelHomeScreen` navigate anywhere real

### Files
`lib/home/home_screen.dart` (135 lines), `lib/home/home_data.dart` (224 lines), `lib/home/widgets/` (12 files), `lib/homescreen/drawerscreen.dart` (184 lines), `lib/starting_screen/home.dart` (731 lines)

---

## Sprint 1.6 — Mechanic (55%)

### Completed
- AI Diagnosis + Vehicle Form: real `AIRepository.diagnoseVehicle()` call, loading dialog, results bottom sheet with fault/cost/time/safety
- MechanicHomeScreen: 8 categories grid, featured mechanics, nearby mechanics, skeleton loading (800ms simulated)
- NearbyMechanicsScreen: filter (Available Now), sort (Nearest/Highest Rated/Lowest Price), empty state
- MechanicDetailsScreen: SliverAppBar with gradient, stats, services with prices, working hours
- SelectServiceScreen: animated selection, continue only when selected
- BookingSummaryScreen: cost breakdown with GST 18%, emergency surcharge
- BookingConfirmationScreen: checkmark animation, booking ID, partner badge
- JobCompletedScreen: invoice card, "Payment Successful • Cash" (hardcoded)
- RatingReviewScreen: animated stars, comment field, thank-you screen
- End-to-end navigation: all 9 screens connect correctly
- 7 reusable mechanic widgets (`MechanicCard`, `ServiceChip`, `BookingSummaryCard`, `InvoiceCard`, `PrimaryActionButton`, `ReviewStar`, `TimelineTile`)

### Missing / Non-functional
- **Live tracking map**: placeholder text "(Map integration coming soon)" — no flutter_map or any map
- **Real-time tracking**: static timeline with manual "Service Completed" button
- **Photo capture**: both Camera + Gallery show "opened" SnackBars only — no actual image handling
- **Geolocation**: hardcoded "Surampalem, Andhra Pradesh" throughout
- **Search**: "coming soon" SnackBar
- **Backend mechanic API**: zero endpoints — no listing, booking, tracking, or assignment
- **100% mock data**: all mechanics, services, prices from `lib/mechanic/mock_data.dart`
- **Error states**: none of the 9 screens have error handling
- **Test coverage**: none

### Navigation
Working — complete 9-screen flow end-to-end

### Files
`lib/mechanic/` (9 screens + 7 widgets + mock_data = 17 files, ~2,200 lines)

---

## Sprint 1.7 — Fuel Delivery (75%)

### Completed
- **Architecture**: models → providers → services → repository → screens → widgets (36 files, 8 directories)
- **Models (9)**: `fuel_type` (4 types with `IconData`), `fuel_order`, `fuel_partner`, `delivery_location`, `price_estimate`, `tracking_info`, `order_status` (12 states), `invoice`, `vehicle`
- **Providers (3)**: `FuelProvider` (7-state `FuelScreenState`), `OrderProvider` (8-state `OrderState`), `TrackingProvider` (5s polling)
- **Services (4)**: `FuelService`, `LocationService`, `PricingService` (**dead code**), `MockTrackingService`
- **Repository (1)**: `FuelRepository` — 172 lines, in-memory mock data generator
- **Widgets (9)**: `FuelTypeCard`, `QuantitySelector`, `PriceBreakdown`, `FuelActionButton` (loading/disabled states), `FuelEmptyState`, `FuelErrorState`, `RecentOrderCard`, `DeliveryLocationCard`, `PaymentMethodTile`
- **Screens (5)**: `FuelHomeScreen` (dashboard), `FuelBookingScreen` (4-step wizard), `PaymentScreen` (5 methods, simulated processing), `OrderConfirmationScreen`, `LiveTrackingScreen`
- **LiveTrackingScreen**: real `flutter_map` with OpenStreetMap tiles, partner marker (truck icon + ETA badge), customer marker (orange pin), status/distance/elapsed timer, cancel dialog, refresh
- **Error/loading/empty states**: present in `FuelProvider`/`OrderProvider` state machines; screens consume most states
- **Navigation**: end-to-end from home → booking → payment → confirmation → tracking

### Critical Bugs
1. **HIGH** — `tracking_provider.dart:28`: `_repository.trackOrder('')` passes **empty string** as order ID. Will always throw "Order not found" for any real order ID.
2. **HIGH** — `live_tracking_screen.dart` cancel dialog: calls `Navigator.popUntil(isFirst)` but **never calls `_orderProvider.cancelOrder()`**. Order remains in `partnerAssigned` state in repository.
3. **MEDIUM** — `payment_screen.dart`: no error handling if `assignPartner()` fails — user stuck on payment screen forever.
4. **LOW** — `pricing_service.dart` completely unused (dead code, 22 lines)
5. **LOW** — Pricing formula duplicated 3× (`FuelService` vs `FuelRepository` vs `PricingService`)
6. **LOW** — Haversine formula duplicated 3× (`location_utils.dart` vs `location_service.dart` vs repo)
7. **LOW** — No dependency injection: each screen creates its own providers, state not shared

### Missing
- Backend fuel API (ordering, pricing, partner assignment, tracking)
- Real GPS (always Bengaluru `12.9716, 77.5946`)
- Real payment gateway (2-second fake delay)
- `flutter_map` attribution line (OSM license requirement)
- Route polyline between partner and customer on tracking map
- Map does not follow partner marker on updates

### Navigation
Working — Home → FuelHomeScreen → FuelBookingScreen → PaymentScreen → OrderConfirmationScreen → LiveTrackingScreen

### Files
`lib/features/fuel_delivery/` (36 files, ~2,200 lines)

---

## Sprint 1.8 — Marketplace / Parts (35%)

### Completed
- PartsScreen (758 lines): 15 hardcoded products across 3 vehicle types, 11 categories, 3 promo banners, search with suggestions, featured products, full product grid
- CartScreen (457 lines): add/remove/quantity/decimal/clear, floating cart button, price summary
- Checkout: subtotal, delivery fee (free above ₹999), GST 18%, total, UPI/Card/COD selection, order confirmation bottom sheet
- Wishlist toggle + badge count (local state only)
- 4 supporting widgets: `ProductCard` (299 lines), `CartItemCard` (166 lines), `PriceSummaryCard` (142 lines), `CategoryChip` (65 lines)
- `ordersList` accumulator in `lib/parts/order_data.dart`

### Missing / Non-functional
- **Product detail screen**: tapping any product shows "coming soon" SnackBar
- **Home → Marketplace navigation**: "Shop All" + product taps on home = "coming soon"
- **Bottom nav tab**: no marketplace tab (only Home, Services, Orders, AI, Profile)
- **"Parts" quick service**: falls to default case "coming soon" in home_screen.dart
- **Backend APIs**: zero — no parts, cart, or order endpoints
- **Dart models**: uses `Map<String, dynamic>` instead of proper model classes
- **State management**: local widget state only (lost on app restart)
- **Cart persistence**: lost on app restart
- **Test coverage**: none

### Navigation
Broken — no navigation path from home or bottom nav to the PartsScreen

### Files
`lib/parts/parts_screen.dart` (758 lines), `lib/parts/cart_screen.dart` (457 lines), `lib/parts/order_data.dart` (1 line), `lib/widgets/product_card.dart` (299 lines), `lib/widgets/cart_item_card.dart` (166 lines), `lib/widgets/price_summary_card.dart` (142 lines), `lib/widgets/category_chip.dart` (65 lines)

---

## Sprint 1.9 — AI Assistant / Chatbot (95%)

### Completed
- **Chat UI**: message bubbles (user orange right / bot grey left), timestamps, expand/collapse, animated entry
- **Chat input**: text field (send on submit, multiline up to 4 lines), attach/mic/send buttons
- **Welcome screen**: time-aware greeting, 6 quick action cards, 3 recent conversations, 4 suggested questions
- **Thinking indicator**: pulsing AI icon gradient, rotating step messages, bouncing dots (153 lines)
- **Gemini integration**: `gemini-2.5-flash` via `ChatGoogleGenerativeAI` (API key in `.env`)
- **XGBoost ML diagnosis**: `fault_classifier.joblib` for telemetry-based vehicle fault diagnosis
- **RAG knowledge base**: FAISS vector store + `sentence-transformers/all-MiniLM-L6-v2` embeddings
- **Intent classification + routing**: 10 intents → route to diagnosis/RAG/LLM with fallback
- **Session management**: UUID sessions, 12-message memory window, structured audit logging
- **Backend API**: 5 endpoints — POST /chat, POST /session, GET /history, POST /diagnose, POST /query
- **Diagnosis card** (396 lines): fault name, severity badge, safety advice (color-coded), cost/time, confidence ring, action buttons
- **Error handling**: error banner with retry, network exception handling, empty catch fallback
- **Integration test**: 85-line test with live backend verification (coolant/sensor/keywords)
- **Bottom nav**: Tab 4 = AI Assistant (sparkle icon)
- **Rule-based fallback**: local responses when API key missing or placeholder

### Partial
- **Home screen "Start AI Diagnosis" card**: card renders but `onTap` is `null` when used as `const AIAssistantCard()` — non-functional from HomeDashboard
- **Diagnosis card action buttons**: "Find Mechanic", "Order Parts", "Download", "Share" all show "coming soon" SnackBars

### Missing
- Voice input (shows "coming soon")
- File attachments (shows "coming soon")
- Test coverage beyond 1 integration test

### Navigation
Working — Bottom tab 4 → ChatBot full UI

### Files
`lib/bottom_bar/chatboard.dart` (866 lines), `lib/widgets/chat_bubble.dart` (143 lines), `lib/widgets/chat_input.dart` (136 lines), `lib/widgets/thinking_indicator.dart` (153 lines), `lib/widgets/diagnosis_card.dart` (396 lines), `lib/services/ai_repository.dart` (82 lines), `lib/services/api_client.dart` (149 lines)  
Backend: 18 Python files (chat_service, diagnosis_service, rag_service, api router, schemas, config)

---

## Overall Project Audit

| Sprint | Completion | Status |
|---|---|---|
| Sprint 1.1 — Splash Screen | **100%** | Locked final |
| Sprint 1.2 — Onboarding | **100%** | Locked final |
| Sprint 1.3 — Login | **75%** | Mock auth, social login not wired, no user persistence |
| Sprint 1.4 — Registration | **65%** | No data stored, no vehicle fields, no auto-login |
| Sprint 1.5 — Home Dashboard | **40%** | Two conflicting homes, all mock data, most navigation broken |
| Sprint 1.6 — Mechanic | **55%** | Full UI flow, 100% mock, no backend APIs, map placeholder |
| Sprint 1.7 — Fuel Delivery | **75%** | Full architecture, 100% mock, 2 high-severity bugs |
| Sprint 1.8 — Marketplace | **35%** | UI prototype, no backend, no navigation path |
| Sprint 1.9 — AI Assistant | **95%** | Near-production with real Gemini + ML + RAG |

**Weighted Overall: ~71%**

---

## Architecture Review

| Metric | Score | Notes |
|---|---|---|
| **Folder Structure** | 7/10 | Fuel Delivery uses `features/` (good). Others scattered across `auth/`, `home/`, `mechanic/`, `parts/`, `homescreen/`, `bottom_bar/`, `starting_screen/` |
| **Feature-first** | 5/10 | Only Fuel Delivery isolates properly. Others leak into shared `lib/widgets/` |
| **Reusable Widgets** | 8/10 | 49 shared + 22 feature-specific widgets. Good reuse patterns |
| **Theme Usage** | 9/10 | Full light/dark mode, `AppColors`, `AppTheme`, `ThemeProvider` with SP persistence |
| **Responsive** | 9/10 | `AppResponsive` with scale/scaleFont/scaleIcon, desktop/mobile detection |
| **Dark Mode** | 9/10 | Every feature checks `Brightness.dark`. Consistent dark palette |
| **Code Duplication** | 4/10 | Pricing formula ×3, Haversine ×3, two home screens, two login screens |
| **State Management** | 5/10 | `Provider` used. Fuel/Order/Tracking have state machines. Home = StatelessWidget. Marketplace = local state |
| **Dependency Injection** | 2/10 | None — providers instantiated directly in widgets, no state sharing |
| **Backend** | 2/10 | Only AI has real backend. Auth, mechanic, fuel, marketplace = zero APIs |

**Architecture Overall: 6.0/10**

---

## Code Quality Review

| Metric | Score | Notes |
|---|---|---|
| `const` usage | ✔ Good | Most widgets use `const` constructors |
| Dead code | ⚠ | 2 login screens, `pricing_service.dart` unused |
| Imports | ✔ Clean | `flutter analyze` = 0 errors, 0 warnings (our code) |
| Analyzer | ✔ Passes | 23 info-level issues (all pre-existing) |
| Build readiness | ✔ | Compiles cleanly |
| Scalability | ❌ | No DI, no routing, inconsistent feature isolation |
| Maintainability | ⚠ | Mixed — Fuel + AI well-structured; home dashboard fragile |

**Code Quality: 7.0/10**

---

## Production Readiness

**Status: MVP / Pre-Production — NOT ready for production**

| Criterion | Verdict |
|---|---|
| Builds without errors | ✔ Yes |
| Real authentication | ❌ Mock |
| User data persistence | ❌ None |
| Backend integration | ❌ Only AI (1 of 5 features) |
| Real payment | ❌ Fake 2s delay |
| Real GPS | ❌ Hardcoded Bengaluru |
| Error handling | ⚠ Partial (AI + Fuel good, rest none) |
| Loading states | ⚠ Partial (Fuel + Mechanic some, home none) |
| Empty states | ⚠ Partial |
| Test coverage | ❌ 3 tests for entire app |
| Security (API key) | ⚠ `.env` in assets |

---

## Technical Debt Report

| Item | Severity | Effort |
|---|---|---|
| Two login screens (one unused) | Low | 1h |
| Two home screens (architecture conflict) | **High** | 4h |
| Pricing formula duplicated 3× | Low | 1h |
| Haversine formula duplicated 3× | Low | 1h |
| `pricing_service.dart` dead code | Low | 5min |
| Tracking provider empty order ID | **High** | 15min |
| Cancel does not cancel order | **High** | 30min |
| No DI (state lost between screens) | **High** | 8h |
| No named routes / router | Medium | 4h |
| No backend for 4/5 features | **Critical** | 3 months |
| No test coverage | **Critical** | 2 months |

---

## Missing Features Report

| Feature | Status |
|---|---|
| Real authentication (JWT, OAuth) | ❌ |
| Social login (Google, Apple) | ⚠ Buttons only |
| User profile persistence | ❌ |
| Vehicle management (CRUD) | ❌ |
| Emergency SOS (real dispatch) | ❌ |
| Real-time mechanic tracking | ❌ |
| Photo upload | ❌ Mock only |
| Product detail page | ❌ |
| Home → Marketplace navigation | ❌ Broken |
| Wallet (balance, transactions) | ❌ |
| Push notifications | ❌ |
| Global search | ❌ |
| Real payment gateway | ❌ |
| Real GPS geolocation | ❌ Hardcoded |
| Offline support | ❌ |
| Error/crash reporting | ❌ |

---

## Final Scores

| Category | Score |
|---|---|
| **UI** | 75% |
| **UX** | 60% |
| **Architecture** | 60% |
| **Backend** | 20% |
| **Scalability** | 30% |
| **Maintainability** | 55% |
| **Code Quality** | 70% |
| **Overall** | **53%** |

---

## Prioritized Roadmap

### Fix First (this week)
1. 🔴 `tracking_provider.dart:28` — tracking passes empty string as order ID (15min)
2. 🔴 `live_tracking_screen.dart` — cancel does not cancel order (30min)
3. 🟡 Merge/resolve two home screens (4h)
4. 🟡 Wire social login buttons with at least a SnackBar callback (2h)
5. 🟡 Fix Emergency SOS `onTap: null` on HomeDashboard (30min)

### Build Next (Sprint 2 — Backend Integration)
6. 🔴 Auth backend + user persistence + `AuthProvider`
7. 🔴 Convert HomeDashboard to StatefulWidget with provider + loading/error/empty states
8. 🟡 Mechanic API endpoints (listing, booking, tracking)
9. 🟡 Fuel delivery API endpoints (ordering, pricing, partners, tracking)
10. 🟡 Marketplace product detail page + home navigation

### Production Release Blockers
- ❌ No real authentication system
- ❌ No backend for 4/5 features
- ❌ No test coverage (3 tests)
- ❌ No error tracking / crash reporting
- ⚠ `Space Grotesk` font not in `pubspec.yaml`
- ⚠ `.env` API key exposed in assets
