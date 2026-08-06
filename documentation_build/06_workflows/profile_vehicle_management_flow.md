# Workflow: Profile & Vehicle Management

> Modules: profile · orders (shared list)

## Mermaid

```mermaid
sequenceDiagram
    autonumber
    actor U as User
    participant P as ProfileProvider
    participant PR as ProfileRepository (mock, 800ms)
    participant VS as ValidationService
    participant ORD as ordersList (shared)

    U->>P: Open Profile tab
    P->>PR: fetchProfile / fetchStats
    PR-->>P: Jagadeesh Gowda (Pro), stats (12 services, orders from ordersList)
    U->>P: Add vehicle (brand/model/reg/fuel/insurance/PUC/health)
    P->>VS: validate fields
    P->>PR: addVehicle (id veh-<counter 200>)
    U->>P: Save address
    P->>PR: addAddress (addr-<counter 200>)
    U->>P: View wallet / rewards
    P->>PR: fetchWallet / fetchRewards
    PR-->>P: 1200 balance, 2450 pts, 4 txns / rewards
    U->>P: View orders
    P->>ORD: fetchOrders (reads shared ordersList)
```

## Narrative
1. Profile tab = tab 4; header, vehicles, wallet, rewards, orders, addresses, notifications,
   privacy, support, about, theme picker, logout.
2. Vehicles/addresses sort default-first (frozen ordering), counters start at 200.
3. `ProfileStats.orders` comes from the shared `ordersList` — never diverges from Orders tab.
4. Notification settings persist via `NotificationSettingsStore`
   (SharedPreferences prod / in-memory tests).

## Decision / Failure / Recovery
- **Validation:** `ValidationService` guards address/vehicle/payment fields.
- **Default promotion:** `setDefaultVehicle/Address` auto-promotes (one default).
- **Error/retry:** typed `ProfileNetworkException` via `failForFirstCalls`.
- **Delete:** vehicle/address delete confirmed in UI.

## Backend Notes (Sprint 2)
- `users`, `vehicles`, `addresses`, `wallet`, `wallet_transactions`, `reward_ledger`, `notification_settings`.
- `ProfileStats.orders = count(order_entries)`; rewards = `sum(reward_ledger.points)`.
- `is_logged_in` + `theme_mode` stay on-device (SharedPreferences), never in DB.
