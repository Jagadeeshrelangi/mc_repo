# Glossary — Mecha Connect

> Phase 7 · Terms used across the bundle.

| Term | Definition |
|---|---|
| RC1 | Release Candidate 1 — current deliverable state (version 1.0.0+1) |
| Frontend Lock Candidate | Frozen-frontend status; UI/data/navigation frozen pending RC1 approval |
| Repository seam | Interface between providers and mock/real data; the only data source |
| Mock realism | Simulated latency + `failForFirstCalls` deterministic failure injection |
| `failForFirstCalls` | Mock failure-injection flag: first N calls throw typed exceptions |
| OrderStore / ordersList | `frontend/lib/parts/order_data.dart` singletons; unified Orders-tab feed |
| order_entries | Postgres table that `ordersList` maps to (Sprint 2) |
| AiBlock / AiResponse | Typed assistant reply blocks + action buttons |
| AiAction | openDiagnosis / bookMechanic / searchParts / fuelRecommendation |
| IndexedStack | Shell body keeping all 5 tabs mounted |
| GNav | `google_nav_bar` bottom navigation widget |
| ETA | Estimated time of arrival (mechanic/fuel) |
| PUC | Pollution Under Control certificate (vehicle) |
| AOV / LTV / CAC | Average order value / lifetime value / customer acquisition cost |
| health_score | Vehicle health 0–100 (vehicles table) |
| membership_tier | `free` / `pro` |
| OrderStatus | fuel: requested→accepted→fuelPacked→partnerAssigned→enRoute→arrived→delivered |
| Reduced motion | OS accessibility setting; hero carousel autoplay disabled |
| DevicePreview | Debug-only device-frame wrapper (`kDebugMode`) |
| SharedPreferences | On-device key-value store (`is_logged_in`, `theme_mode`, notifications) |
| FAISS / RAG | Backend AI index / retrieval-augmented generation (Sprint 2 scaffold) |
| XGBoost fault_classifier | Trained fault-diagnosis model (Sprint 2 scaffold) |
