# Navigation Map — Mecha Connect (Frontend Lock Candidate)

> Sprint 1.9b · Frozen navigation reference
> Style: imperative `Navigator.push` with `MaterialPageRoute` or module fade
> routes (`aiFadeRoute`, `profileFadeRoute`). Only named route: `/` → Splash.

## 1. App Entry & Root Flow

```
main() → MultiProvider(buildRootProviders) → MyApp → DevicePreview → MaterialApp
  initialRoute: '/' → SplashScreen
      │
      ├─ is_logged_in == true            → BottomNavigation   (5-tab shell)
      ├─ is_logged_in == false && onboarding done → LoginScreen
      └─ else (no onboarding)            → OnboardingScreen
  (all via 450ms fade pushReplacement)
```

Login / SignUp / ForgotPassword link to each other and push
`BottomNavigation` on success. Profile logout
(`pushAndRemoveUntil` → `LoginScreen`) is the only reverse path.

## 2. Bottom Navigation Shell (5 tabs)

`BottomNavigation` — `IndexedStack` body keeps all tabs mounted; only the
selected tab is visible.

| Index | Tab | Screen | Entry file |
|---|---|---|---|
| 0 | Home | `HomeDashboard` | `frontend/lib/starting_screen/home.dart` |
| 1 | Services | `ServiceSelectionScreen` | `frontend/lib/starting_screen/home.dart` |
| 2 | Orders | `Orderscreen` | `frontend/lib/bottom_bar/order_screen.dart` |
| 3 | AI | `AiHomeScreen` | `frontend/lib/features/ai/screens/ai_home_screen.dart` |
| 4 | Profile | `ProfileScreen` | `frontend/lib/features/profile/screens/profile_screen.dart` |

`ServiceSelectionScreen` exposes an `endDrawer` (`ProfileDrawer`) and an
"Explore Services" affordance that switches to tab 1.

## 3. Services Tab Flows (`ServiceSelectionScreen`)

Top-level cards push:

```
HomeDashboard / ServiceSelectionScreen
 ├── SOS card / Quick service "Breakdown / Garage"  → VehicleFormPage (mechanic)
 ├── Quick service "Fuel"                            → FuelHomeScreen
 ├── Marketplace entry                               → MarketplaceHomeScreen
 └── Search bar                                      → (search surface, Semantics-wrapped)
```

### 3.1 Mechanic flow

```
VehicleFormPage ─→ MechanicHomeScreen (after valid vehicle form)
MechanicHomeScreen
 ├── Nearby mechanics            → NearbyMechanicsScreen
 │                                   └─ Mechanic card → MechanicDetailsScreen
 ├── Service category            → SelectServiceScreen
 │                                   ├─ Book → VehicleFormPage
 │                                   └─ (service details) → MechanicDetailsScreen
 └── History                     → BookingHistoryScreen
MechanicDetailsScreen
 ├── Book service → BookingSummaryScreen
 └── Reviews
BookingSummaryScreen ─→ BookingConfirmationScreen (pushAndRemoveUntil)
BookingConfirmationScreen ─→ LiveTrackingScreen (pushReplacement)
LiveTrackingScreen ─→ JobCompletedScreen (pushReplacement)
JobCompletedScreen ─→ RatingReviewScreen (pushReplacement)
```

Route constants live in `frontend/lib/features/mechanic/`; screens in
`frontend/lib/features/mechanic/screens/`.

### 3.2 Fuel delivery flow

```
FuelHomeScreen
 ├── Order history (header + history card) → OrderHistoryScreen
 │                                             └─ Order → LiveTrackingScreen / ReceiptScreen
 └── Book fuel (station card / primary button / CTA) → FuelBookingScreen
FuelBookingScreen ─→ PaymentScreen (pushReplacement)
PaymentScreen ─→ OrderConfirmationScreen (pushReplacement)
OrderConfirmationScreen ─→ LiveTrackingScreen (pushReplacement)
LiveTrackingScreen ─→ OrderCompleteScreen (pushReplacement)
OrderCompleteScreen ─→ ReceiptScreen (pushReplacement)
```

### 3.3 Marketplace flow

```
MarketplaceHomeScreen
 ├── Category grid → CategoryScreen → ProductDetailScreen
 ├── Product card  → ProductDetailScreen
 ├── Search        → SearchScreen → ProductDetailScreen
 ├── Cart          → CartScreen → CheckoutScreen
 └── Wishlist      → WishlistScreen → ProductDetailScreen
ProductDetailScreen
 ├── Add to cart (wishlist toggle)
 └── Buy now → CartScreen / CheckoutScreen
CheckoutScreen ─→ OrderSuccessScreen (pushReplacement; writes Orders tab via orderStore)
OrderSuccessScreen → "View Orders" → Orders tab (tab 2)
```

## 4. AI Tab Flows

Route constants + helper in `frontend/lib/features/ai/navigation.dart`:

| Route | Screen |
|---|---|
| `/ai` | `AiHomeScreen` |
| `/ai/chat` | `ChatScreen` |
| `/ai/diagnosis` | `DiagnosisScreen` |
| `/ai/history` | `ConversationHistoryScreen` |
| `/ai/conversation` | `ConversationDetailScreen` |

```
AiHomeScreen
 ├── Suggested question / quick action → ChatScreen
 ├── New diagnosis / "Run Guided Diagnosis" → DiagnosisScreen
 ├── History → ConversationHistoryScreen → ConversationDetailScreen
 └── Cross-module actions (from chat/diagnosis/quick cards):
       Book Mechanic  → MechanicHomeScreen
       Fuel           → FuelHomeScreen
       Search Parts   → MarketplaceHomeScreen
DiagnosisScreen → onBookMechanic / onSearchParts / onFuelRecommendation
```

ChatScreen also shows a bottom sheet for conversation rename/delete
(`conversation_tile.dart`) and returns results via `Navigator.pop(value)`.

## 5. Profile Tab Flows

Route constants + fade helpers in `frontend/lib/features/profile/navigation.dart`
(`/profile`, `/profile/edit`, `/profile/vehicles`, `/profile/vehicles/detail`,
`/profile/addresses`, `/profile/wallet`, `/profile/rewards`,
`/profile/orders`, `/profile/notifications`, `/profile/privacy`,
`/profile/support`, `/profile/about`).

```
ProfileScreen
 ├── Header profile → EditProfileScreen
 ├── Vehicle card   → openVehicleDetail (VehicleDetailScreen)
 ├── My Vehicles    → MyVehiclesScreen → openVehicleDetail
 ├── Wallet         → WalletScreen
 ├── Rewards        → RewardsScreen
 ├── My Orders      → OrderHistoryScreen
 ├── Saved Addresses → SavedAddressesScreen (add/edit → sheet dialogs)
 ├── Notifications  → NotificationSettingsScreen
 ├── Privacy & Security → PrivacySecurityScreen
 ├── Theme picker   → in-place SimpleDialog (no route)
 ├── Support        → SupportScreen
 ├── About          → AboutScreen
 └── Logout         → confirm dialog → pushAndRemoveUntil(LoginScreen)
```

## 6. Orders Tab (`Orderscreen`)

Tab 2 renders `ordersList` (shared store) grouped by category filter tabs
(All / Parts / Mechanic / Fuel / AI). It stays alive inside the `IndexedStack`
and rebuilds via `OrderStore` notifications (Marketplace inserts) or its own
tab controller (no per-frame listener since 1.9b). Selecting "Explore
Services" switches the shell to tab 1 (`onExploreServices`).

## 7. Cross-Module Edges (frozen)

| From | To | Trigger |
|---|---|---|
| Home / Services | Mechanic form, Fuel, Marketplace | Service cards |
| AI chat/diagnosis | Mechanic, Fuel, Marketplace | AI action buttons (`AiAction`) |
| Marketplace checkout | Orders tab | `addMarketplaceOrder` + `orderStore.notify()` |
| Profile | Auth | Logout (`pushAndRemoveUntil`) |
| Orders tab | Services tab | "Explore Services" |

## 8. Transition Language (frozen)

- Splash → entry: 450ms fade `pushReplacement` (`main.dart`).
- AI module: `aiFadeRoute` (220ms fade).
- Profile module: `profileFadeRoute` (220ms / 180ms).
- Other modules: `MaterialPageRoute` (platform default).
- GNav tab switch: 250ms built-in animation; shell uses `IndexedStack`.
