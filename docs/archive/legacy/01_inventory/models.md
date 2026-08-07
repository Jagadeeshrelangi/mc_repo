# Models Inventory — Mecha Connect

> Phase 1 · Class names captured by repo scan (grep `class *` in `*/models/`), grouped by module.
> Counts: 39 model files across 7 modules.

## ai (8 classes)
`AiBlock`, `AiActionButton`, `AiResponse`, `ChatMessage`, `Conversation`, `Diagnosis`, `QuickAction`, `SuggestedQuestion`

## fuel_delivery (8)
`DeliveryLocation`, `FuelOrder`, `FuelPartner`, `FuelStation`, `FuelVehicle`, `Invoice`, `PriceEstimate`, `TrackingInfo`

## home (9)
`UserProfile`, `LocationInfo`, `VehicleInfo`, `QuickService`, `NearbyService`, `MarketplaceItem`, `ActivityItem`, `OfferInfo`, `HomeData`

## marketplace (13)
`CartItem`, `WishlistItem`, `PriceSummary`, `Coupon`, `Offer`, `OrderItem`, `CheckoutAddress`, `MarketplaceOrder`, `Product`, `ProductSpecification`, `Brand`, `Category`, `Review`

## mechanic (6)
`MechanicInfo`, `MechanicService`, `MechanicCategory`, `MechanicReview`, `BookingRequest`, `Booking`

## profile (13)
`EmergencyContact`, `NotificationSettings`, `ProfileStats`, `Reward`, `RewardTierProgress`, `RewardsData`, `SavedAddress`, `UserProfile`, `ProfileVehicle`, `WalletTransaction`, `Coupon`, `PaymentMethod`, `WalletData`

> Note: `Coupon`, `UserProfile`, `Offer` appear in multiple modules (duplicated small model types). Canonical definitions: Handbook ch10 (module knowledge) + `docs/07_rc1_certification/DATABASE_BLUEPRINT.md` ch14. Database tables map 1:1 to these model families (`VehicleInfo`→`vehicles`, `FuelOrder`→`fuel_orders`, `MarketplaceOrder`→`marketplace_orders`, `Booking`→`mechanic_bookings`, `WalletData`→`wallet`, etc.).

## Aggregates
- `HomeData` (home) aggregates the 8 sibling home models for dashboard rendering.
- `RewardsData` (profile) aggregates reward + tier progress.
- `WalletData` (profile) aggregates wallet transactions, coupons, payment methods.
