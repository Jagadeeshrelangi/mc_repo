# API Knowledge — Mecha Connect

> Phase 3 · Frozen contract for the in-memory repositories (`../API.md`), which the real
> FastAPI backend must implement in Sprint 2. The Flutter UI does not change.

## 1. Conventions
- Base path: `/api/v1` (Sprint 2 target).
- Latency (simulated): AI 900ms · Profile 800ms · Home 800ms · Marketplace 700ms · Fuel 700ms · Mechanic per method.
- Failure injection: repos accept `failForFirstCalls` → typed `XxxNetworkException` with user-facing `message`.
- Money: `double` INR (₹). Timestamps: ISO-8601 on wire payloads.
- Additive field changes only; enum changes require a client-matching release.

## 2. ID Schemes (frozen)
| Domain | Prefix | Example |
|---|---|---|
| Marketplace order | `MKP-<year>-<0000>` | `MKP-2026-0001` |
| Marketplace product | `p-` | `p-spark-plug` |
| Coupon / offer | `coupon-` / `offer-` | `coupon-mecha10`, `offer-brake` |
| Review (product/mechanic) | `rv-` / `r` | `rv-brake-1`, `r1` |
| Shared orders tab | `ORD-` | `ORD-1001` |
| Fuel order | `FUEL-<year>-<0000>` | `FUEL-2026-0009` |
| Fuel station / partner | `station_` / `partner_` | `station_1`, `partner_1` |
| Fuel invoice | `INV-<orderId>` | `INV-FUEL-2026-0009` |
| Mechanic service / mechanic | `svc_` / `m` | `svc_1`, `m1` |
| AI conversation / message / diagnosis | `ai-` / `m-` / `diag-` | `ai-0001`, `m-0001`, `diag-1` |
| Profile vehicle / address | `veh-` / `addr-` (counter from 200) | `veh-101`, `addr-202` |
| Wallet txn / reward / payment | `txn-` / `rew-` / `pay-` | `txn-101`, `rew-101`, `pay-101` |

## 3. Module Method Surfaces

### 3.1 Home (`features/home`)
| Method | Returns |
|---|---|
| `fetchHomeData()` | `HomeData { quickServices[], nearbyServices[], marketplaceItems[], activities[], offers[] }` |

### 3.2 Auth (`features/auth`)
Local-only at RC1. Login/SignUp/ForgotPassword screens; state via SharedPreferences `is_logged_in`.
No credential storage.

### 3.3 AI (`features/ai`)
| Method | Returns |
|---|---|
| `fetchConversations()` | `List<Conversation>` (pinned first, then newest updatedAt) |
| `sendMessage(conversationId, message)` | raw reply string (keyword knowledge base) |
| `diagnoseVehicle({vehicleType, problem, symptoms})` | structured diagnosis payload (`diag-N`) |

`AiResponse { blocks[], actions[] }`; `AiBlock.type` in text|warning|recommendation|bulletList|checklist|costEstimate;
`AiAction` enum: openDiagnosis | bookMechanic | searchParts | fuelRecommendation.
Seed: 5 conversations (`ai-0001` Engine overheating … `ai-0005` Oil change), 2 pinned.

### 3.4 Marketplace (`features/marketplace`)
| Method | Returns |
|---|---|
| `fetchProducts()` / `fetchCategories()` / `fetchBrands()` / `fetchOffers()` / `getCoupons()` | catalog lists (40/10/15/3/3) |
| `createOrder({items, address, paymentMethod})` | `List<MarketplaceOrder>` (`MKP-<year>-<0000>`) |

Orders-tab integration: `addMarketplaceOrder(...)` in `frontend/lib/parts/order_data.dart` inserts a `parts` entry
(status Pending, date Today) and calls `orderStore.notify()`.

### 3.5 Mechanic (`features/mechanic`)
List/query mechanics; fetch details + reviews; book service; summary → confirmation; live tracking;
submit rating/review; booking history. Constructor-injectable repository.
Seed: 4 mechanics (`m4` unavailable), 3 featured, reviews `r1..r8`, 8 categories, 8 services.

### 3.6 Fuel (`features/fuel_delivery`)
| Method | Notes |
|---|---|
| `getFuelTypes()` | incl. disabled coming-soon (electric, cng) |
| `getSavedVehicles()` | 3 mock vehicles |
| `getFuelStations({lat, lng})` | 6 stations sorted by distance |
| `createOrder(...)` | `FUEL-<year>-<0000>` |
| `acceptOrder(id)` / `advanceStatus(id)` | tracking sequence; partner at `partnerAssigned` |
| `cancelOrder(id)` / `completeOrder(id)` | cancelled / attach invoice |
| `generateInvoice(id)` | `INV-<orderId>` |
| `getTracking(id)` | simulated live coords/ETA |
| `getOrderHistory()` / `refreshHistory()` | seeded `FUEL-2026-0005..0009` |

OrderStatus: requested → accepted → fuelPacked → partnerAssigned → enRoute → arrived → delivered (+ cancelled).
`FuelService.calculatePrice`: grandTotal = fuelCost + deliveryCharge + platformFee + taxes.

### 3.7 Profile (`features/profile`)
`fetchProfile/saveProfile` (Jagadeesh Gowda, Pro) · `fetchVehicles/addVehicle/saveVehicle/deleteVehicle/setDefaultVehicle`
· `fetchAddresses/addAddress/saveAddress/deleteAddress/setDefaultAddress` · `fetchWallet` (4 txns, 2 coupons, 2 pay methods)
· `fetchRewards` (4 rewards, 4 achievements) · `fetchStats` · `fetchOrders` (reads shared `ordersList`)
· `fetchNotificationSettings/saveNotificationSettings` (persisted).
Ordering guarantee: vehicles/addresses sort default-first everywhere.

## 4. Backend Scaffold → Contract Mapping (Sprint 2)
The FastAPI scaffold mirrors the AI surface: `backend/app/api/v1/conversation.py`,
`diagnosis.py`, `knowledge.py` → services (`chat_service` Gemini/langchain,
`diagnosis_service` XGBoost `fault_classifier.joblib`, `rag_service` FAISS).
Marketplace/mechanic/fuel/profile endpoints are not yet scaffolded.

## 5. Versioning & Backward Compatibility
- Additive field changes only (client ignores unknown fields).
- Enum changes require a client-matching release.
- All endpoints must honor latency/failure conventions so loading/empty/error states remain exercisable.
