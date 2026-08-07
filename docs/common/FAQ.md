# FAQ — Mecha Connect

> Living document. Answers drawn from the canonical documentation tree.

## Product

**Q: What is Mecha Connect?**
A: An AI-powered roadside-assistance and vehicle-services platform for Indian
vehicle owners. Users can book a verified mechanic, order on-demand fuel
delivery, buy spare parts, get AI-guided vehicle diagnosis, track help in real
time, and manage profile/wallet/rewards in one app.

**Q: What does the app currently do?**
A: RC1 ships a complete Flutter frontend (Frontend Lock Candidate) with all
seven feature modules working against in-memory mock repositories. Every screen,
flow, and interaction is functional and exercised by 162 passing tests.

**Q: Is the backend live?**
A: No. A FastAPI scaffold exists (chat, diagnosis, RAG + FAISS + XGBoost) but is
not wired to the app. Connecting it is Sprint 2 scope.

## Engineering

**Q: Why is everything mock at RC1?**
A: The repositories simulate latency and deterministic failure injection so the
UI behaves exactly like production. The frozen repository interfaces are the
seam the real backend slots into during Sprint 2 without UI changes.

**Q: How is the app architected?**
A: Screens → Providers (ChangeNotifier + Provider) → Repositories → mock
engines. A single provider graph lives in `frontend/lib/app_wiring.dart`; a 5-tab
`IndexedStack` shell keeps tab state alive; cross-tab state uses small
singletons (`orderStore` / `ordersList`).

**Q: What is the "Frontend Lock Candidate"?**
A: The frozen frontend state: UI, data models, navigation, and repository
interfaces are locked for RC1 pending release approval. Use this phrasing, never
"RC1 Certified".

**Q: How do I verify the build?**
A: `flutter analyze` must report 0 issues and `flutter test` must pass 162/162.
See `docs/common/DEVELOPMENT_WORKFLOW.md`.

**Q: Where is the API contract?**
A: `docs/backend/API.md` — the frozen contract the real FastAPI backend must
implement in Sprint 2.

## Data & Privacy

**Q: Where does data live at RC1?**
A: In memory (mock repositories) plus `SharedPreferences` for `is_logged_in`,
`theme_mode`, and notification settings. No on-device PII beyond the seeded
demo profile; no real credentials are stored at RC1.

**Q: Is my live location sent anywhere?**
A: No real HTTP calls exist at RC1. Location is read on-device for map
centering and nearby ordering only.

## Documentation

**Q: Which document should I read first?**
A: `docs/common/PROJECT_OVERVIEW.md` builds the mental model, then
`docs/common/ARCHITECTURE_OVERVIEW.md` and `docs/CANONICAL_DOCUMENT_MAP.md`.

**Q: Where is the engineering handbook?**
A: `docs/handbook/ENGINEERING_HANDBOOK.md` — the 20-chapter public technical
reference. Release history is in `docs/handbook/CHANGELOG.md`.

**Q: What is confidential vs public?**
A: Public docs live under `docs/common/`, `docs/frontend/`, `docs/backend/`, and
`docs/handbook/`. Internal business, financial, security, and risk content is
excluded from public bundles and from git tracking.
