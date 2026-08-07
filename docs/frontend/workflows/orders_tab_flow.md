# Workflow: Orders Tab (Unified Feed)

> Modules: orders (tab 2) · marketplace · profile · orderStore/ordersList

## Mermaid

```mermaid
sequenceDiagram
    autonumber
    actor U as User
    participant OT as Orderscreen (tab 2)
    participant OS as OrderStore (ChangeNotifier)
    participant LIST as ordersList (global)
    participant P as MarketplaceProvider

    Note over OT,LIST: Tab 2 stays alive in IndexedStack
    OT->>OT: render ordersList grouped by filter (All/Parts/Mechanic/Fuel/AI)
    P->>LIST: addMarketplaceOrder(...)
    LIST->>OS: insert entry (type parts, status Pending)
    OS->>OS: notify()
    OS-->>OT: rebuild on notify only (no per-frame listener)
    P->>LIST: fetchOrders (Profile history reads same list)
    OT->>OT: "Explore Services" → switch shell to tab 1
```

## Narrative
1. Orders tab renders the shared global `ordersList`, grouped by category filter tabs.
2. Marketplace checkout inserts `parts` entries and notifies via `OrderStore`.
3. Profile order history reads the same list — single source, never diverges.
4. Seeded entries exist for Parts / Mechanic / Fuel / AI categories.

## Decision / Failure / Recovery
- **Stale tab:** fixed in 1.9b — tab rebuilds only on tab change or `OrderStore.notify()`.
- **Offstage duplicates:** hidden tab labels stay in the tree (tests use `.first`).
- **Empty:** empty-state for a category with no entries.

## Backend Notes (Sprint 2)
- `ordersList` ↔ `order_entries` table; type parts|mechanic|fuel|aiReport;
  status Pending|Delivered|Completed|In Progress|Cancelled.
- Marketplace inserts write here; Orders tab + Profile history read the same rows.
