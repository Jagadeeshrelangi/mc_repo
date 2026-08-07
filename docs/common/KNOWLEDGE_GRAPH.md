# KNOWLEDGE_GRAPH — Mecha Connect

> **Documentation Build v2.1 · 2026-08-05**
> Structured relationship document — NOT a diagram. Shows how every part of the
> project connects, one chain per domain. Read top-down as a dependency story.

---

## 0. Root Graph (the spine)

```
main.dart
   │ loads dotenv (best-effort)
   ▼
app_wiring.dart → buildRootProviders()          ← single source of truth
   │
   ▼
MultiProvider → MyApp → DevicePreview(kDebugMode) → MaterialApp
   │                                                 │ initialRoute '/'
   ▼                                                 ▼
BottomNavigation (5-tab IndexedStack)            SplashScreen
   ├── 0 Home → HomeProvider                       ├─ logged in → shell
   ├── 1 Services → service cards                  ├─ onboarding done → Login
   ├── 2 Orders → orderStore / ordersList          └─ first launch → Onboarding
   ├── 3 AI → AiProvider
   └── 4 Profile → ProfileProvider
```

## 1. Marketplace

```
Services tab (ServiceSelectionScreen)
   ▼ Marketplace card
MarketplaceHomeScreen
   ▼ MarketplaceProvider        (root #9; uses CartService, SelectService)
   ▼ MarketplaceRepository      (700ms mock; 40 products/10 cat/15 brands/3 offers/3 coupons)
   ▼ Models: Product · Category · Brand · Offer · Coupon · CartItem · WishlistItem
           OrderItem · CheckoutAddress · MarketplaceOrder · PriceSummary · Review
   ▼ ProductDetail → Cart → Checkout → placeOrder
   ▼ orderStore.addMarketplaceOrder() → notify()
   ▼ Orders tab (tab 2) + Profile OrderHistory  (shared ordersList)
   ▼ Sprint 2: api/v1/... → orders + order_items + order_entries (PostgreSQL)
```

## 2. AI Assistant

```
AI tab (tab 3)
   ▼ AiProvider                 (root #6; owns ONE AiRepository)
   ▼ AiService + DiagnosisService   ← shared with provider (triple-repo bug fixed)
   ▼ AiRepository               (900ms mock; 5 seed conversations, 2 pinned)
   ▼ Models: Conversation · ChatMessage · AiResponse/AiBlock/AiActionButton
           Diagnosis · QuickAction · SuggestedQuestion
   ▼ Chat → Diagnosis → AiAction (openDiagnosis|bookMechanic|searchParts|fuelRecommendation)
   ▼ deep-links: MechanicHome · FuelHome · MarketplaceHome  (features/ai/navigation.dart)
   ▼ Sprint 2: conversation.py · diagnosis.py · knowledge.py
            chat_service (Gemini) · diagnosis_service (XGBoost) · rag_service (FAISS)
```

## 3. Fuel Delivery

```
Services tab → Fuel card
   ▼ FuelHomeScreen
   ▼ FuelProvider               (root #8; needs LocationProvider)
   ▼ FuelRepository + FuelService + NearbyService + QuickService   (700ms mock)
   ▼ Models: FuelType · FuelVehicle · FuelStation · DeliveryLocation · FuelOrder
           PriceEstimate · TrackingInfo · Invoice · FuelPartner · OrderStatus
   ▼ Book → Price (fuelCost+delivery+platform+taxes) → Pay → Confirm → Track → Complete
   ▼ Status: requested→accepted→fuelPacked→partnerAssigned→enRoute→arrived→delivered
   ▼ LocationProvider (10s timeLimit + 12s timeout; manual fallback)
   ▼ Sprint 2: fuel_orders + price_estimates + tracking_events + invoices + fuel_stations/partners
```

## 4. Mechanic

```
Services tab → SOS / Breakdown card
   ▼ VehicleFormPage → MechanicHomeScreen
   ▼ MechanicProvider           (root #5; repository constructor-injectable)
   ▼ MechanicRepository         (mock; 4 mechanics, 3 featured, reviews r1–r8, 8 cat/8 svc)
   ▼ Models: MechanicInfo · MechanicService · MechanicCategory · MechanicReview
           BookingRequest · Booking
   ▼ Nearby → Details → SelectService → BookingSummary → Confirm → LiveTrack → Complete → Rate
   ▼ VehicleForm uses DiagnosisService (AI module, mock) — no HTTP
   ▼ Sprint 2: mechanics + mechanic_services + mechanic_bookings
            + booking_events (JSONB) + ratings + tracking via WebSocket
```

## 5. Authentication

```
SplashScreen
   ▼ AuthProvider               (root #3; AuthService(AuthRepository()))
   ▼ LoginScreen / SignUpScreen / ForgotPasswordScreen
   ▼ SharedPreferences key: is_logged_in
   ▼ success → BottomNavigation;  logout → pushAndRemoveUntil(LoginScreen)
   ▼ Sprint 2: Firebase Auth + JWT + users.password_hash (no credentials at RC1)
```

## 6. Profile & Account Center

```
Profile tab (tab 4)
   ▼ ProfileProvider            (root #7; ProfileService + ValidationService)
   ▼ ProfileRepository          (800ms mock; Jagadeesh Gowda/Pro; veh-101/102; addr-101/102;
                                  wallet 1200 · 2450 pts · rewards 2450 · 12 services)
   ▼ Models: UserProfile · ProfileVehicle · SavedAddress · WalletData/WalletTransaction
           RewardsData/Reward · ProfileStats · NotificationSettings · PaymentMethod
   ▼ Wallet · Rewards · Vehicles · Addresses · Orders (reads shared ordersList) · Settings
   ▼ Sprint 2: users + vehicles + addresses + wallet + wallet_transactions
            + reward_ledger + notification_settings
```

## 7. Home Dashboard

```
Home tab (tab 0) + Services tab
   ▼ HomeProvider               (root #4)
   ▼ HomeRepository             (800ms mock)
   ▼ HomeData aggregate: quickServices · nearbyServices · marketplaceItems · activities · offers
   ▼ Service cards → Mechanic / Fuel / Marketplace flows; search → HomeSearchScreen
   ▼ Sprint 2: single GET /api/v1/home assembly endpoint
```

## 8. Navigation

```
Only named route '/' (Splash)
   ▼ imperative Navigator.push (MaterialPageRoute default; aiFadeRoute 220ms; profileFadeRoute)
   ▼ Route constants:
       ai:        /ai · /ai/chat · /ai/diagnosis · /ai/history · /ai/conversation
       marketplace: /marketplace · /marketplace/{product,category,search,cart,wishlist}
       profile:   /profile + /profile/{edit,vehicles,vehicles/detail,addresses,wallet,
                  rewards,orders,notifications,privacy,support,about}
       fuel/mechanic/auth/home: inline (no navigation.dart)
```

## 9. Orders (unified feed)

```
MarketplaceProvider.placeOrder ─┐
ProfileProvider.fetchOrders ────┼──► ordersList (global) → OrderStore.notify()
Orders tab (tab 2) ─────────────┘        ▼
                                   rebuild on notify only
   ▼ Sprint 2: order_entries (type parts|mechanic|fuel|aiReport;
                status Pending|Delivered|Completed|In Progress|Cancelled)
```

## 10. Location (shared cross-cutting)

```
LocationProvider (root #2)
   ▼ LocationService (geolocator + permission_handler)   → DetectedLocation
   ▼ GeocodingService → GeocodingResult (reverse geocode)
   ▼ Used by: FuelProvider (required), mechanic nearby ordering, map screens,
             location_header/banner/picker shared widgets
   ▼ State: permissionState (initial|granted|denied|deniedForever|serviceDisabled)
   ▼ Sprint 2: server computes distance/ETA; on-device coords sent in requests
```

## 11. Theme (cross-cutting)

```
ThemeProvider (above MaterialApp) → SharedPreferences key 'theme_mode'
   ▼ ThemeMode.system default; AppTheme.light / AppTheme.dark
   ▼ context helpers (cardBg, border, accent, textTertiary…) via app_theme_helpers.dart
   ▼ All 7 modules consume tokens; new tokens require sign-off
```

## 12. Backend Scaffold (Sprint 2 target, exists)

```
FastAPI app (backend/app/main.py)
   ▼ CORS allow all · MechaException handler (code→HTTP status)
   ▼ api/v1: conversation.py · diagnosis.py · knowledge.py
   ▼ services: chat_service (Gemini) · diagnosis_service (XGBoost joblib) · rag_service (FAISS)
   ▼ AI assets: ai/knowledge_base/{faq,manuals,obd_codes,dashboard_symbols,faiss_index}
                ai/models/fault_classifier.joblib
   ▼ .env: GEMINI_API_KEY (masked at startup log)
   ▼ Mirrors the frozen API surface exactly (see `backend/API.md`)
```
