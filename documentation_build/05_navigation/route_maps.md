# Route Maps — Mecha Connect

> Phase 3 · Source: `NAVIGATION_MAP.md` (frozen) + repo scan of `navigation.dart`.

## 1. Entry & Splash Decision
- Only named route: `/` → `SplashScreen`.
- Splash → next via 450ms fade `pushReplacement`:
  - `is_logged_in == true` → `BottomNavigation` (5-tab shell)
  - `is_logged_in == false` + onboarding done → `LoginScreen`
  - else (first launch) → `OnboardingScreen`

## 2. Tab Shell (5 tabs, `IndexedStack`)
| Tab | Screen | Entry file |
|---|---|---|
| 0 Home | `HomeDashboard` | `lib/starting_screen/home.dart` (legacy path in NAVIGATION_MAP) |
| 1 Services | `ServiceSelectionScreen` | `lib/starting_screen/home.dart` |
| 2 Orders | `Orderscreen` | `lib/bottom_bar/order_screen.dart` |
| 3 AI | `AiHomeScreen` | `lib/features/ai/screens/ai_home_screen.dart` |
| 4 Profile | `ProfileScreen` | `lib/features/profile/screens/profile_screen.dart` |

## 3. Declared Route Constants (current code)
- **AI** (`lib/features/ai/navigation.dart`): `/ai`, `/ai/chat`, `/ai/diagnosis`, `/ai/history`, `/ai/conversation`
- **Marketplace** (`lib/features/marketplace/navigation.dart`): `/marketplace`, `/marketplace/product`, `/marketplace/category`, `/marketplace/search`, `/marketplace/cart`, `/marketplace/wishlist`
- **Profile** (`lib/features/profile/navigation.dart`): `/profile`, `/profile/edit`, `/profile/vehicles`, `/profile/vehicles/detail`, `/profile/addresses`, `/profile/wallet`, `/profile/rewards`, `/profile/orders`, `/profile/notifications`, `/profile/privacy`, `/profile/support`, `/profile/about`
- fuel_delivery, mechanic, auth, home: navigate inline (no dedicated `navigation.dart`).

## 4. Mechanic Flow
```
VehicleFormPage → MechanicHomeScreen
  ├── Nearby mechanics → NearbyMechanicsScreen → Mechanic card → MechanicDetailsScreen
  ├── Service category → SelectServiceScreen → Book → VehicleFormPage / details → MechanicDetailsScreen
  └── History → BookingHistoryScreen
MechanicDetailsScreen → Book service → BookingSummaryScreen
  → BookingConfirmationScreen (pushAndRemoveUntil)
  → LiveTrackingScreen (pushReplacement)
  → JobCompletedScreen (pushReplacement)
  → RatingReviewScreen (pushReplacement)
```

## 5. Fuel Flow
```
FuelHomeScreen
  ├── Order history → OrderHistoryScreen → Order → LiveTracking / Receipt
  └── Book fuel → FuelBookingScreen → PaymentScreen (pushReplacement)
      → OrderConfirmationScreen (pushReplacement)
      → LiveTrackingScreen (pushReplacement)
      → OrderCompleteScreen (pushReplacement)
      → ReceiptScreen (pushReplacement)
```

## 6. Marketplace Flow
```
MarketplaceHomeScreen
  ├── Category grid → CategoryScreen → ProductDetailScreen
  ├── Product card → ProductDetailScreen
  ├── Search → SearchScreen → ProductDetailScreen
  ├── Cart → CartScreen → CheckoutScreen
  └── Wishlist → WishlistScreen → ProductDetailScreen
CheckoutScreen → OrderSuccessScreen (pushReplacement; writes Orders tab via orderStore)
OrderSuccessScreen → "View Orders" → Orders tab
```

## 7. AI Flow
```
AiHomeScreen
  ├── Suggested question / quick action → ChatScreen
  ├── New diagnosis / "Run Guided Diagnosis" → DiagnosisScreen
  ├── History → ConversationHistoryScreen → ConversationDetailScreen
  └── Cross-module (AiAction): Book Mechanic → MechanicHomeScreen
      Fuel → FuelHomeScreen · Search Parts → MarketplaceHomeScreen
ChatScreen bottom sheet: rename/delete conversation; returns via Navigator.pop(value).
```

## 8. Profile Flow
```
ProfileScreen → Edit / Vehicles / VehicleDetail / Wallet / Rewards / My Orders /
  Saved Addresses / Notifications / Privacy & Security / Theme (in-place dialog) /
  Support / About / Logout (confirm → pushAndRemoveUntil(LoginScreen))
```

## 9. Cross-Module Edges (frozen)
| From | To | Trigger |
|---|---|---|
| Home / Services | Mechanic form, Fuel, Marketplace | Service cards |
| AI chat/diagnosis | Mechanic, Fuel, Marketplace | `AiAction` buttons |
| Marketplace checkout | Orders tab | `addMarketplaceOrder` + `orderStore.notify()` |
| Profile | Auth | Logout |
| Orders tab | Services tab | "Explore Services" |

## 10. Transition Language (frozen)
- Splash → entry: 450ms fade. AI: `aiFadeRoute` (220ms). Profile: `profileFadeRoute` (220/180ms).
- Others: `MaterialPageRoute`. GNav tab switch: 250ms built-in.
