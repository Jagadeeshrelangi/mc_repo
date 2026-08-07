# Module Knowledge: Profile (`frontend/lib/features/profile/`)

> Phase 5 · Tab 4. Source: Architecture §5.5, API §8, SPRINT_1_9A.

## Purpose
Account center: profile, vehicles, saved addresses, wallet, rewards, unified order
history, notification settings, privacy/security, support, about, theme picker, logout.

## Inventory
| Layer | Items |
|---|---|
| Models (9 files, 13 classes) | `EmergencyContact`, `NotificationSettings`, `ProfileStats`, `Reward`, `RewardTierProgress`, `RewardsData`, `SavedAddress`, `UserProfile`, `ProfileVehicle`, `WalletTransaction`, `Coupon`, `PaymentMethod`, `WalletData` |
| Provider | `ProfileProvider` (root graph #7) |
| Repositories | `ProfileRepository` (800ms latency, failure injection) |
| Services | `ProfileService`, `ValidationService` |
| Screens (12) | `ProfileScreen`, `EditProfileScreen`, `MyVehiclesScreen`, `VehicleDetailScreen`, `SavedAddressesScreen`, `WalletScreen`, `RewardsScreen`, `OrderHistoryScreen`, `NotificationSettingsScreen`, `PrivacySecurityScreen`, `SupportScreen`, `AboutScreen` |
| Widgets (13) | profile header, wallet card, reward card, address tile, settings tile, etc. |
| Navigation | `navigation.dart`: `/profile` + 11 sub-routes + `profileFadeRoute` |

## Key Behavior
- Seed: Jagadeesh Gowda (Pro tier); vehicles `veh-101/102`, addresses `addr-101/102`
  (counters from 200); wallet 1200 / 2450 pts / 4 txns; rewards 2450 redeemable / 4 rewards;
  12 services; referral `GOWDA200` (200 pts).
- Vehicles/addresses sort default-first (frozen); auto-promote default.
- `fetchOrders` reads shared `ordersList` — single source with Orders tab.
- Notification settings persist via `NotificationSettingsStore`
  (SharedPreferences prod / in-memory tests).
- Theme picker is an in-place `SimpleDialog`, not a route.

## Failure Paths
`ProfileNetworkException` retry; form validation via `ValidationService`;
delete confirmations for vehicles/addresses.

## Tests
`test/profile_module_test.dart` — 30 tests.

## Backend Relation (Sprint 2)
`users`, `vehicles`, `addresses`, `wallet`, `wallet_transactions`, `reward_ledger`,
`notification_settings`. `ProfileStats.orders = count(order_entries)`.
