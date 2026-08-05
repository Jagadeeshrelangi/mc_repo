# Frontend Architecture — Mecha Connect (Frontend Lock Candidate)

> Sprint 1.9b · Frozen architecture reference
> Flutter 3.29.2 · Provider (7.x) · nested · google_nav_bar · device_preview

## 1. Overview

Mecha Connect is a Flutter app for vehicle owners (parts marketplace, mechanic
booking, fuel delivery, AI diagnostics, wallet/rewards). At RC1 the entire data
layer is **mock** (in-memory repositories with simulated latency + failure
injection) so the UI behaves exactly like production. Sprint 2 swaps repository
internals for the real backend; **the UI never bypasses the repository layer.**

```
lib/
├── main.dart                        # entry, env load, root providers, SplashScreen
├── app_wiring.dart                  # single source of truth for the provider graph
├── theme/                           # AppColors, AppSpacing/AppElevation, AppResponsive,
│                                    # ThemeProvider, AppTheme (light/dark), app_theme_helpers
├── bottom_bar/
│   ├── bottom_navigation.dart       # 5-tab GNav + IndexedStack shell
│   └── order_screen.dart            # Orders tab (listens to OrderStore)
├── parts/order_data.dart            # shared order store + ordersList singleton
├── starting_screen/                 # Splash → Onboarding/Login + HomeDashboard +
│                                    # ServiceSelectionScreen
├── homescreen/drawerscreen.dart     # ProfileDrawer
├── services/location_provider.dart  # location + FuelProvider dependency
├── widgets/                         # shared UI (order_card, location_header, …)
└── features/
    ├── auth/        # Login / SignUp / ForgotPassword
    ├── home/        # Home repository + models
    ├── ai/          # chat, diagnosis, history
    ├── marketplace/ # catalog, cart, checkout, wishlist, orders
    ├── mechanic/    # booking, live tracking, ratings
    ├── fuel_delivery/ # booking, tracking, invoice/receipt
    ├── profile/     # profile, vehicles, addresses, wallet, rewards
    └── vehicle_location/ # (vehicle location flow, 8 tests)
```

## 2. App Entry (`lib/main.dart`)

1. `WidgetsFlutterBinding.ensureInitialized()`; loads `.env` (best effort).
2. Creates `LocationProvider`, `FuelProvider` (needs location), and
   `MarketplaceProvider` up front.
3. `runApp(MultiProvider(providers: buildRootProviders(...), child: MyApp()))`.
4. `MyApp` → `DevicePreview(enabled: kDebugMode)` → `MaterialApp` with
   `theme: AppTheme.light`, `darkTheme: AppTheme.dark`,
   `themeMode: themeProvider.themeMode`, `initialRoute: '/'` → `SplashScreen`.

Splash routing logic (`_navigateToNext`, 450ms fade `pushReplacement`):

| `is_logged_in` | `onboarding_completed` | Target |
|---|---|---|
| true | — | `BottomNavigation` |
| false | true | `LoginScreen` |
| false | false | `OnboardingScreen` |

No dev flags remain in the gateway; `MyApp` takes no navigator observers.

## 3. Provider Graph (`lib/app_wiring.dart`)

Single production wiring, also used verbatim by the runtime regression test.

| Order | Provider | Constructed with |
|---|---|---|
| 1 | `ThemeProvider` | `ChangeNotifierProvider(create)` |
| 2 | `LocationProvider` | injectable or default |
| 3 | `AuthProvider` | `AuthService(AuthRepository())` |
| 4 | `HomeProvider` | `HomeRepository()` |
| 5 | `MechanicProvider` | default (repository injectable since 1.9b) |
| 6 | `AiProvider` | default (owns ONE `AiRepository`) |
| 7 | `ProfileProvider` | `ProfileRepository(SharedPreferencesNotificationSettingsStore)` |
| 8 | `FuelProvider` | `FuelProvider(locationProvider: location)` |
| 9 | `MarketplaceProvider` | injectable or default |

Injection points (for tests): `LocationProvider`, `FuelProvider`,
`MarketplaceProvider`, `ProfileProvider`. Everything else is created in place.

### Non-provider singletons

- `orderStore` (`lib/parts/order_data.dart`) — `OrderStore extends ChangeNotifier`; the
  Orders tab and Marketplace both reach it. `addMarketplaceOrder()` calls
  `orderStore.notify()` after inserting into `ordersList`.
- `ordersList` — seeded global in-memory order list (Parts / Mechanic / Fuel /
  AI seeded entries + Marketplace inserts).

## 4. App Shell — 5-Tab `IndexedStack`

`BottomNavigation` (`lib/bottom_bar/bottom_navigation.dart`):

| Index | Tab | Screen |
|---|---|---|
| 0 | Home | `HomeDashboard` |
| 1 | Services | `ServiceSelectionScreen` |
| 2 | Orders | `Orderscreen` |
| 3 | AI | `AiHomeScreen` |
| 4 | Profile | `ProfileScreen` |

- Body is `IndexedStack(index: _currentIndex, children: _navItems)` — all five
  tabs stay mounted; hidden tabs are offstage but findable/stateful.
- `GNav` bottom bar; tab changes via `setState`; tap-handling guards against
  redundant setState.
- Consequences handled in 1.9b: offstage 'Parts' label duplicates
  `find.text('Parts')` in tests (use `.first`); Orders tab needs an external
  notifier (`OrderStore`) because it stays alive across tab switches.

## 5. Feature Modules

### 5.1 AI Assistant (`features/ai`)
- Models: `Conversation`, `ChatMessage`, `AiResponse`/`AiBlock`/`AiActionButton`,
  `Diagnosis`, `QuickAction`, `SuggestedQuestion`.
- `AiRepository` (mock engine): seed knowledge base (5 conversations), raw
  keyword replies, structured diagnosis templates; latency 900ms; failure
  injection `failForFirstCalls`.
- `AiProvider` (ChangeNotifier): owns exactly ONE `AiRepository` shared with
  `AiService` and `DiagnosisService` (triple-repo bug fixed in 1.9b).
  `loadHome`/`refreshHome` use `_mergeReloaded()` to preserve user
  conversations and pin overrides.
- Screens: `AiHomeScreen`, `ChatScreen`, `DiagnosisScreen`,
  `ConversationHistoryScreen`, `ConversationDetailScreen`.
- Navigation helper `features/ai/navigation.dart` defines
  `/ai`, `/ai/chat`, `/ai/diagnosis`, `/ai/history`, `/ai/conversation` and an
  `aiFadeRoute` push helper used across the AI module.

### 5.2 Marketplace (`features/marketplace`)
- Models: `Product`, `Category`, `Brand`, `Offer`, `Coupon`, `Cart`,
  `OrderItem`/`MarketplaceOrder`, `Review`.
- `MarketplaceRepository` (700ms latency): catalog + order creation
  (`MKP-<year>-<0000>` ids). Coupons are catalog data.
- `MarketplaceProvider`: catalog, cart, checkout, wishlist; `placeOrder`
  writes the Orders tab via `addMarketplaceOrder` (shared store) and returns
  typed `MarketplaceOrder` records for the confirmation flow.
- Screens: MarketplaceHome, Category, ProductDetail, Cart, Checkout,
  OrderSuccess, Search, Wishlist.
- `ProductCard` uses `context.read` + `context.select` for wishlist state
  (rebuilds only on wishlist change).

### 5.3 Mechanic (`features/mechanic`)
- Models: `MechanicInfo`, `MechanicService`, `MechanicCategory`,
  `MechanicReview`, booking/tracking records.
- `MechanicRepository` (constructor-injectable, 1.9b); `MechanicProvider`.
- Screens: MechanicHome, NearbyMechanics, MechanicDetails, SelectService,
  VehicleForm (uses `DiagnosisService` from the AI module — no real HTTP),
  BookingSummary, BookingConfirmation, LiveTracking, RatingReview,
  JobCompleted, BookingHistory.

### 5.4 Fuel Delivery (`features/fuel_delivery`)
- Models: `FuelType`, `FuelVehicle`, `FuelStation`, `DeliveryLocation`,
  `FuelOrder`, `PriceEstimate`, `TrackingInfo`, `Invoice`, `FuelPartner`,
  `OrderStatus`.
- `FuelRepository` (700ms latency): stations near lat/lng, order lifecycle
  (requested → accepted → fuelPacked → partnerAssigned → enRoute → arrived →
  delivered), `INV-<orderId>` invoices, seeded history `FUEL-2026-0005..0009`.
- `FuelService` computes price estimates (fuel cost, delivery, platform fee,
  taxes, grand total).
- Screens: FuelHome, FuelBooking, OrderConfirmation, Payment, LiveTracking,
  OrderComplete, Receipt, OrderHistory.

### 5.5 Profile (`features/profile`)
- Models: `UserProfile`, `ProfileVehicle`, `SavedAddress`, `WalletData` /
  `WalletTransaction` / `PaymentMethod`, `RewardsData` / `Reward`,
  `ProfileStats`, `NotificationSettings`, `EmergencyContact`, `Coupon`.
- `ProfileRepository` (800ms latency, failure injection): seeded profile
  (Jagadeesh Gowda, Pro tier), vehicles (`veh-101..102`, counter from 200),
  addresses (`addr-101..102`, counter from 200), wallet (balance 1200,
  2450 pts, 4 txns), rewards (2450 redeemable, 4 rewards), stats (12 services,
  orders from shared `ordersList`), notification settings persisted via
  `NotificationSettingsStore` (SharedPreferences prod / in-memory tests).
- Screens: Profile, EditProfile, MyVehicles, VehicleDetail,
  SavedAddresses, Wallet, Rewards, OrderHistory, NotificationSettings,
  PrivacySecurity, Support, About.

### 5.6 Auth (`features/auth`)
- `AuthRepository` + `AuthService` + `AuthProvider`. Login/SignUp/ForgotPassword.
- Login state persisted via `is_logged_in` (SharedPreferences) read by splash.

### 5.7 Home (`features/home`)
- `HomeRepository.fetchHomeData()` (800ms) → `HomeData` with quick services,
  nearby services, marketplace items, activities, offers.
- `HomeProvider` + `home_screen.dart` + `home_search_screen.dart`.

## 6. Theme & Responsive

- `ThemeProvider` (SharedPreferences `theme_mode`) — system/light/dark.
- `AppTheme.light` / `AppTheme.dark` (see `theme/app_theme.dart`).
- `app_theme_helpers.dart` provides context getters (`context.cardBg`,
  `context.border`, `context.accent`, `context.textTertiary`, …) used widely.
- `AppResponsive`: breakpoints mobile 600 / tablet 1024; `responsive<T>`,
  clamped `scale/scaleFont/scaleIcon`, `ConstrainedContent` max-width wrapper.
- Full token reference: `UI_DESIGN_SYSTEM.md`.

## 7. Cross-Cutting Conventions (frozen)

1. **Repository seam:** every module has a repository that is the ONLY data
   source; providers call repositories; screens never call HTTP.
2. **Mock realism:** repositories simulate latency and support deterministic
   failure injection (`failForFirstCalls`); retry/error UI paths are real.
3. **State:** `ChangeNotifier` + Provider. `IndexedStack` keeps tab state.
   Cross-tab state uses small singletons (`orderStore`, `ordersList`).
4. **ID schemes** (frozen for the API contract):
   `MKP-`, `ORD-`, `FUEL-<year>-`, `INV-`, `MEC `/`svc_`, `ai-`, `m-`, `diag-`,
   `veh-`, `addr-`, `txn-`, `rew-`, `pay-`.
5. **Navigation:** imperative `Navigator.push(MaterialPageRoute/aiFadeRoute)`;
   no named routes except `/` (splash). Deep links from AI to
   Marketplace/Fuel/Mechanic go through `features/ai/navigation.dart`.

## 8. Sprint 2 (Backend) Integration Seams

| Seam | Today | Sprint 2 |
|---|---|---|
| Repositories (`features/*/repositories/*.dart`) | In-memory mocks | HTTP client (FastAPI/PostgreSQL) |
| `AiRepository` | Mock KB + templates | Gemini/OpenAI client |
| `ProfileRepository` | In-memory + SharedPreferences | FastAPI/PostgreSQL |
| `ordersList`/`orderStore` | Global singleton | Repository-backed feed |
| Coupon validation | Catalog data | Server-side validation |
| Real-time tracking | Simulated `TrackingInfo` | WebSocket/push |

No screen or provider signature changes are required because the UI depends
only on the repository interfaces (see `API_CONTRACT.md`).
