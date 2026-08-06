# Screens & Routes Inventory — Mecha Connect

> Phase 1 · Screen classes captured by repo scan; routes from `navigation.dart` files.

## 1. Screens by Module (public classes, 48 total)

| Module | Screens |
|---|---|
| **ai** (5) | `AiHomeScreen`, `ChatScreen`, `ConversationDetailScreen`, `ConversationHistoryScreen`, `DiagnosisScreen` |
| **auth** (3) | `LoginScreen`, `SignUpScreen`, `ForgotPasswordScreen` |
| **fuel_delivery** (8) | `FuelHomeScreen`, `FuelBookingScreen`, `PaymentScreen`, `OrderConfirmationScreen`, `LiveTrackingScreen`, `OrderCompleteScreen`, `OrderHistoryScreen`, `ReceiptScreen` |
| **home** (2) | `HomeScreen`, `HomeSearchScreen` |
| **marketplace** (8) | `MarketplaceHomeScreen`, `ProductDetailScreen`, `CategoryScreen`, `SearchScreen`, `CartScreen`, `WishlistScreen`, `CheckoutScreen`, `OrderSuccessScreen` |
| **mechanic** (10) | `MechanicHomeScreen`, `NearbyMechanicsScreen`, `MechanicDetailsScreen`, `SelectServiceScreen`, `BookingSummaryScreen`, `BookingConfirmationScreen`, `BookingHistoryScreen`, `JobCompletedScreen`, `RatingReviewScreen`, `LiveTrackingScreen` |
| **profile** (12) | `ProfileScreen`, `EditProfileScreen`, `MyVehiclesScreen`, `VehicleDetailScreen`, `SavedAddressesScreen`, `WalletScreen`, `RewardsScreen`, `OrderHistoryScreen`, `NotificationSettingsScreen`, `PrivacySecurityScreen`, `SupportScreen`, `AboutScreen` |

Plus shell/entry screens: `SplashScreen` (route `/`, `lib/main.dart`), onboarding (`lib/starting_screen/`),
`DrawerScreen` (`lib/homescreen/drawerscreen.dart`), `OrderScreen` (`lib/bottom_bar/order_screen.dart`).

## 2. Declared Routes (`navigation.dart` consts)

### ai (`lib/features/ai/navigation.dart`)
`/ai` · `/ai/chat` · `/ai/diagnosis` · `/ai/history` · `/ai/conversation`

### marketplace (`lib/features/marketplace/navigation.dart`)
`/marketplace` · `/marketplace/product` · `/marketplace/category` · `/marketplace/search` · `/marketplace/cart` · `/marketplace/wishlist`

### profile (`lib/features/profile/navigation.dart`)
`/profile` · `/profile/edit` · `/profile/vehicles` · `/profile/vehicles/detail` · `/profile/addresses` · `/profile/wallet` · `/profile/rewards` · `/profile/orders` · `/profile/notifications` · `/profile/privacy` · `/profile/support` · `/profile/about`

> fuel_delivery, mechanic, auth, home navigate inline (no dedicated `navigation.dart`).
> Full flow maps: `docs/07_rc1_certification/NAVIGATION_MAP.md` + Handbook ch12 (reused in Phase 5 `05_navigation/`).

> Note: the frozen `NAVIGATION_MAP.md` names some legacy screen/widgets (e.g. `HomeDashboard`,
> `ServiceSelectionScreen`, `Orderscreen` at `lib/starting_screen/home.dart`) that have since moved
> into `lib/features/*` (e.g. `HomeScreen` in `lib/features/home/screens/home_screen.dart`).
> Flow semantics in NAVIGATION_MAP remain canonical; file paths above reflect the current repo scan.

## 3. Navigation Notes
- 5-tab shell (frozen): **0 Home** (`HomeDashboard`), **1 Services** (`ServiceSelectionScreen`), **2 Orders** (`Orderscreen`), **3 AI** (`AiHomeScreen`), **4 Profile** (`ProfileScreen`) — `IndexedStack` keeps tabs mounted (`lib/bottom_bar/bottom_navigation.dart`, `google_nav_bar`).
- Marketplace, Fuel, and Mechanic flows are entry points **inside the Services tab** (cards on `ServiceSelectionScreen`), not separate tabs.
- Orders tab renders the shared `OrderStore` (`lib/parts/order_data.dart`) grouped All/Parts/Mechanic/Fuel/AI; marketplace checkout writes into it.
- Auth flow is pre-shell; splash (`/`) decides onboarding vs login vs shell based on session.
- Frozen transition language: 450ms fade from splash; `aiFadeRoute`/`profileFadeRoute` (220ms); other modules `MaterialPageRoute`.
