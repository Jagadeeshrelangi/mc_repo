# API Contract — Mecha Connect (Mock Backend)

> Sprint 1.9b · Frozen contract for the in-memory repositories
> This contract defines exactly what the real FastAPI backend must implement
> in Sprint 2 so the Flutter UI does not change.

## 1. General Conventions

| Convention | Value |
|---|---|
| Base path | `/api/v1` (Sprint 2 target) |
| Latency | simulated per repository: AI 900ms, Profile 800ms, Home 800ms, Marketplace 700ms, Fuel 700ms, Mechanic per method |
| Failure injection | repositories accept `failForFirstCalls` → throw `XxxNetworkException` for the first N calls (deterministic retry-path testing) |
| Error format | typed exceptions with user-facing `message` (e.g. `AiNetworkException`, `ProfileNetworkException`) |
| Money | `double` (₹ INR), e.g. `price`, `mrp`, `estimated_cost`, `balance` |
| Timestamps | ISO-8601 strings on AI/order payloads; `DateTime` in-memory |
| Localized strings | Rupee symbol `₹` used in descriptions/labels |

### ID schemes (frozen)

| Domain | Prefix / pattern | Example |
|---|---|---|
| Marketplace order | `MKP-<year>-<0000>` | `MKP-2026-0001` |
| Marketplace product | `p-` | `p-spark-plug` |
| Marketplace coupon/offer | `coupon-` / `offer-` | `coupon-mecha10`, `offer-brake` |
| Review (product/mechanic) | `rv-` / `r` | `rv-brake-1`, `r1` |
| Shared orders tab | `ORD-` | `ORD-1001` |
| Fuel order | `FUEL-<year>-<0000>` | `FUEL-2026-0009` |
| Fuel station/partner | `station_` / `partner_` | `station_1`, `partner_1` |
| Fuel invoice | `INV-<orderId>` | `INV-FUEL-2026-0009` |
| Mechanic service | `svc_` | `svc_1` |
| Mechanic | `m` | `m1` |
| AI conversation | `ai-` | `ai-0001` |
| AI message | `m-` | `m-0001` |
| AI diagnosis | `diag-` | `diag-1` |
| Profile vehicle | `veh-` (counter from 200) | `veh-101`, `veh-201` |
| Profile address | `addr-` (counter from 200) | `addr-101`, `addr-202` |
| Wallet txn | `txn-` | `txn-101` |
| Reward | `rew-` | `rew-101` |
| Payment method | `pay-` | `pay-101` |

## 2. Home API

`HomeRepository.fetchHomeData()`
→ `HomeData { quickServices[], nearbyServices[], marketplaceItems[], activities[], offers[] }`
(800ms latency; mock const data in `features/home/models/home_models.dart`).

## 3. Auth API

`AuthRepository` / `AuthService` / `AuthProvider`. Local auth state persisted
via SharedPreferences key `is_logged_in`. Login/SignUp/ForgotPassword screens
only; no real credential storage at RC1.

## 4. AI Assistant API (`features/ai`)

### Entities
- `Conversation { id, title, createdAt, updatedAt, isPinned, messages[] }`
- `ChatMessage { id, role (user|assistant), content, timestamp, response? }`
- `AiResponse { blocks[], actions[] }`
  - `AiBlock { type, text?, title?, items[]? }`
    types: `text | warning | recommendation | bulletList | checklist | costEstimate`
  - `AiActionButton { label, action }` — `AiAction` enum values:
    `openDiagnosis | bookMechanic | searchParts | fuelRecommendation`
- `Diagnosis { id, vehicleName, vehicleType, problem, symptoms[], possibleCauses[], severity, estimatedCost, recommendedAction, shouldDrive, recommendedService, confidence, timestamp }`

### Methods
| Method | Signature | Notes |
|---|---|---|
| `fetchConversations()` | → `List<Conversation>` | pinned first, then newest `updatedAt` |
| `sendMessage(conversationId, message)` | → `String` (raw reply) | keyword knowledge base |
| `diagnoseVehicle({vehicleType, problem, symptoms})` | → `Map<String,dynamic>` | structured payload, counter `diag-N` |

### Diagnosis payload shape (what the real backend must return)
```json
{
  "id": "diag-1",
  "vehicle_name": "Honda Activa 6G",
  "vehicle_type": "bike",
  "problem": "won't start",
  "symptoms": ["clicking"],
  "possible_causes": ["Flat or weak battery", "Faulty starter relay"],
  "severity": "high",
  "estimated_cost": 1200,
  "recommended_action": "Try a jump start once...",
  "should_drive": false,
  "recommended_service": "Battery & Starting System Service",
  "confidence": 86,
  "timestamp": "2026-08-02T..."
}
```

Seed conversations: 5 (`ai-0001` Engine overheating, `ai-0002` Battery,
`ai-0003` Brake noise, `ai-0004` Fuel efficiency, `ai-0005` Oil change);
two pinned.

## 5. Marketplace API (`features/marketplace`)

### Entities
- `Category { id, name, icon }` — 10 categories (engine-parts, brake-system,
  oils, tyres, batteries, accessories, cleaning, lights, filters, electronics)
- `Brand { id, name }` — 15 brands (Bosch, TVS, Rolon, NGK, Hero, Castrol,
  Motul, MRF, CEAT, Exide, Amaron, 3M, Philips, Hella, Osram)
- `Product { id, name, brandId, brand, categoryId, price, mrp, rating,
  ratingCount, stock, imageUrl, icon, description, specifications[],
  vehicleTypes[], compatibility[], warranty, deliveryEstimate, popularity,
  ageDays, isFeatured, isBestSeller, isTrending, isFlashDeal,
  isRecommended, reviews[] }`
- `Offer { id, title, subtitle, code, gradientStart, gradientEnd, categoryId }` — 3 offers
- `Coupon { id, code, title, description, type, value, maxDiscount, minOrderValue }` — 3 coupons
- `Review { id, author, rating, comment, date, isVerifiedPurchase, helpfulCount, photoUrls[] }`
- `Cart / CartItem`, `OrderItem { productId, qty, unitPrice, lineTotal }`,
  `MarketplaceOrder { id, item, address, paymentMethod, total, createdAt }`

### Catalog counts (frozen)
40 products (incl. 1 out-of-stock `p-out-of-stock`), 10 categories, 15 brands,
3 offers, 3 coupons. Several products flagged `featured`, `bestSeller`,
`trending`, `flashDeal`.

### Methods
| Method | Signature |
|---|---|
| `fetchProducts()` | → `List<Product>` |
| `fetchCategories()` | → `List<Category>` |
| `fetchBrands()` | → `List<Brand>` |
| `fetchOffers()` | → `List<Offer>` |
| `getCoupons()` | → `List<Coupon>` (Sprint 2: server-validated) |
| `createOrder({items, address, paymentMethod})` | → `List<MarketplaceOrder>` (one per line; `MKP-<year>-<0000>`) |

### Orders-tab integration (frozen)
`addMarketplaceOrder({id?, name, brand, quantity, price, image?})` in
`lib/parts/order_data.dart` inserts `{id, name, brand, quantity, price,
image, type: parts, status: 'Pending', date: 'Today'}` into `ordersList` and
calls `orderStore.notify()`. The Orders tab and Profile order history read the
same list.

## 6. Mechanic API (`features/mechanic`)

### Entities
- `MechanicCategory { name, icon, color, bgColor, description }` — 8 categories
- `MechanicService { id, name, icon, price, estimatedMinutes, description }` — 8 services
- `MechanicInfo { id, name, rating, reviewCount, experienceYears, distanceKm,
  etaMinutes, isAvailable, priceStarting, phone, skills[], languages[],
  about, services[], workingHours{}, isVerified }`
- `MechanicReview { id, reviewerName, rating, comment, date, vehicle }`
- Booking/tracking records (summary, confirmation, tracking, rating)

### Mock data (frozen)
4 mechanics (`m1`..`m4`; one unavailable `m4`), 3 featured mechanics,
reviews keyed by mechanic (`r1`..`r8`), `generalServices` shared.

### Method surface (`MechanicRepository`)
List/query mechanics, fetch mechanic details + reviews, book service, create
booking summary → confirmation, track live booking, submit rating/review,
booking history. All async with latency; repository is constructor-injectable.

## 7. Fuel Delivery API (`features/fuel_delivery`)

### Entities
- `FuelType` enum: petrol, diesel, premiumPetrol, electric (coming soon), cng (coming soon)
- `FuelVehicle { id, type (car|bike|suv), name, number }`
- `FuelStation { id, name, brand, rating, ratingCount, distanceKm, etaMinutes,
  pricePerLitre, availability (available|low|outOfStock), isOpen, address }`
- `DeliveryLocation { latitude, longitude, address, label }`
- `PriceEstimate { fuelCost, deliveryCharge, platformFee, taxes, grandTotal, etaMinutes }`
- `FuelOrder { id, fuelType, quantity, deliveryLocation, station, vehicle,
  priceEstimate, status, partner?, paymentMethod?, createdAt, invoice? }`
- `OrderStatus` sequence: `requested → accepted → fuelPacked → partnerAssigned → enRoute → arrived → delivered` (+ `cancelled`)
- `FuelPartner { id, name, phone, rating, ratingCount, distance, etaMinutes, isAvailable, vehicleNumber, vehicleModel }`
- `TrackingInfo { partnerLatitude, partnerLongitude, customerLatitude, customerLongitude, distanceRemaining, etaMinutes, status, statusLabel }`
- `Invoice { invoiceId, orderId, createdAt, fuelType, quantity, pricePerLitre, fuelCost, deliveryCharge, platformFee, taxes, grandTotal, partnerName, vehicleNumber }`

### Methods
| Method | Notes |
|---|---|
| `getFuelTypes()` | incl. disabled coming-soon options |
| `getSavedVehicles()` | 3 mock vehicles |
| `getFuelStations({latitude, longitude})` | 6 stations near point, sorted by distance |
| `createOrder(...)` | → `FuelOrder` (`FUEL-<year>-<0000>`) |
| `acceptOrder(id)` / `advanceStatus(id)` | advances tracking sequence; partner assigned at `partnerAssigned` |
| `cancelOrder(id)` | → cancelled |
| `completeOrder(id)` | attaches invoice (`INV-<orderId>`) |
| `generateInvoice(id)` | → `Invoice` |
| `getTracking(id)` | → `TrackingInfo` (simulated live coords/ETA) |
| `getOrderHistory()` / `refreshHistory()` | seeded `FUEL-2026-0005..0009` |

### Price model (`FuelService.calculatePrice`)
`grandTotal = fuelCost + deliveryCharge + platformFee + taxes`.

## 8. Profile API (`features/profile`)

### Entities
- `UserProfile { name, email, phone, dateOfBirth, gender, joinedDate, membershipTier, emergencyContact }`
  tier: `pro` (seeded) / `free`
- `ProfileVehicle { id, brand, model, registration, fuelType, insuranceExpiry,
  pucExpiry, serviceDueKm, serviceDueDate?, isDefault, healthScore }`
- `SavedAddress { id, label (home|office|other), address, latitude, longitude, isDefault }`
- `WalletData { balance (1200), rewardPoints (2450), transactions[], coupons[], paymentMethods[] }`
- `WalletTransaction { id, title, subtitle, amount, type (debit|credit), date, icon }`
- `RewardsData { redeemablePoints (2450), totalEarned (3200), rewards[], achievements[], referralCode 'GOWDA200', referralRewardPoints 200, tierProgress }`
- `Reward { id, title, subtitle, points, type (earned|referral|redeemed|achievement), date, icon }`
- `ProfileStats { vehicles, services (12), orders (from shared ordersList), rewards }`
- `NotificationSettings` (persisted) + `NotificationSettingsStore` (SharedPreferences / in-memory)
- `PaymentMethod { id, name, details, icon }`

### Methods
| Method | Notes |
|---|---|
| `fetchProfile()` / `saveProfile()` | seeded Jagadeesh Gowda, Pro tier |
| `fetchVehicles()` | default first, then registration desc; `veh-101`, `veh-102` |
| `addVehicle()` / `saveVehicle()` / `deleteVehicle()` / `setDefaultVehicle()` | counter from 200; auto-promote default |
| `fetchAddresses()` | default first, then home→office→other |
| `addAddress()` / `saveAddress()` / `deleteAddress()` / `setDefaultAddress()` | counter from 200 |
| `fetchWallet()` | 4 txns, 2 coupons, 2 payment methods |
| `fetchRewards()` | 4 rewards, 4 achievements |
| `fetchStats()` | vehicles + services + orders + rewards |
| `fetchOrders()` | reads shared `ordersList` (never diverges from Orders tab) |
| `fetchNotificationSettings()` / `saveNotificationSettings()` | persisted |

### Ordering guarantees (frozen)
Vehicles and addresses always sort default-first, so every surface renders the
same order and lists never jump between screens.

## 9. Versioning & Backward Compatibility

- Additive field changes only (client ignores unknown fields).
- Enum changes require a client-matching release.
- All endpoints must honor the latency/failure conventions so loading, empty
  and error/retry states remain exercisable in QA.
