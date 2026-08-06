# Mecha Connect - Smart On-Demand Auto Care & AI Diagnostics

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.110.0-009688.svg?style=flat&logo=fastapi)](https://fastapi.tiangolo.com)
[![Flutter](https://img.shields.io/badge/Flutter-3.19.0-02569B.svg?style=flat&logo=flutter)](https://flutter.dev)
[![Platform: Android | iOS | Web](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-blue)](https://flutter.dev)

Mecha Connect is a smart, on-demand vehicle care and emergency road assistance platform. By combining real-time geofenced routing, edge diagnostic predictions, and a Retrieval-Augmented Generation (RAG) virtual mechanic, Mecha Connect keeps motorists moving safely, wherever they are.

---

## 🌟 Key Features
- 🛠️ **Instant Mechanic Dispatch**: Locate and dispatch nearby verified mechanics dynamically based on ratings, specializations, and ETAs.
- ⛽ **Doorstep Fuel Delivery**: Order fuel (petrol/diesel) on-demand, with synchronized litre-and-rupee sliders and local station mapping.
- 🧠 **Vehicle Diagnosis Engine**: A telemetry-driven classifier powered by Random Forest and XGBoost. Predicts specific faults (e.g., overheating, battery depletion) using raw sensor metrics.
- 📖 **AI Mechanic (RAG)**: A LangChain-driven chat assistant grounded in OEM vehicle manuals, warning symbols, and OBD diagnostic datasets via FAISS vector indexing and Gemini 2.5 Flash.
- ⏳ **Predictive Maintenance**: Monitored component wear (oil, battery, brake pads, tyres, coolant) calculated based on driving profiles and vehicle age.

---

## 🏗️ Folder Structure
```text
mecha_connect/
├── assets/                 # App icons, walkthrough images, and fonts
├── backend/                # FastAPI Application Core
│   ├── app/
│   │   ├── api/            # Route controllers & endpoints
│   │   ├── core/           # Configs, logging models, domain exceptions
│   │   ├── schemas/        # Request and response models
│   │   └── services/       # Chat, RAG, and Diagnosis integrations
│   ├── requirements.txt    # Python backend package manifests
│   └── .env                # Backend key overrides
├── documentation_build/    # Canonical documentation (see documentation_build/README.md)
│   ├── 00_core/            # Product specs, changelog, install/deploy guides
│   ├── 01_knowledge/       # Knowledge base + master handbook
│   ├── 02_architecture/    # Architecture, diagrams, design system
│   ├── 03_database/ 04_api/ 05_navigation/ 06_workflows/ 07_modules/
│   ├── 08_assets/ 09_exports/  tools/
│   └── archive/            # Historical records (engineering_review, sprint_history, legacy)
├── lib/                    # Flutter Application Core
│   ├── auth/               # Login and authentication screens
│   ├── bottom_bar/         # Navigation bar, chat, orders, profile
│   ├── home/               # Home dashboard and data models
│   ├── homescreen/         # Mechanic locator and petrol delivery screens
│   ├── mechanic/           # Mechanic-specific screens
│   ├── parts/              # Parts catalog and ordering
│   ├── services/           # ApiClient and AIRepository network layers
│   ├── starting_screen/    # Onboarding, login, and splash screens
│   ├── theme/              # App theme, colors, typography
│   ├── widgets/            # Reusable widget components
│   └── main.dart           # App bootstrapper & configuration loader
├── test/                   # Unit and integration test suites
│   └── integration/        # E2E integration tests
├── pubspec.yaml            # Flutter package manifests
└── .env                    # Frontend backend URL overrides
```

---

## 🔌 Technical Manuals
For detailed setup instructions, API contracts, and architecture workflows, explore these resources:
- 📥 **[Local Installation Guide](documentation_build/00_core/INSTALLATION.md)**: Setup guides for FastAPI and Flutter environments.
- 🏗️ **[Frontend Architecture Guide](documentation_build/02_architecture/FRONTEND_ARCHITECTURE.md)**: How the app is built — provider graph, module tree, backend integration seams.
- 🔌 **[API Contract Reference](documentation_build/04_api/API_CONTRACT.md)**: The frozen API contract that Sprint 2 backend must implement.
- 📖 **[Documentation Index](documentation_build/CANONICAL_DOCUMENT_MAP.md)**: Single source of truth for every documentation topic.

---

## 🚀 Future Vision & Scope
1. **IoT OBD-II Hardware Sync**: Enable real-time telemetry streaming directly from physical OBD-II dongles plugged into client vehicles, eliminating manual sensor submissions.
2. **Dynamic Service Center Bidding**: Allow workshops to bid in real-time on complex repair jobs submitted by users, ensuring transparent and optimal market pricing.
3. **AR Dashboard Assistant**: Introduce Augmented Reality (AR) HUD guides on mobile cameras to visually point out oil dipsticks, radiator caps, and fuse boxes during emergencies.
4. **Predictive Carbon Footprint Tracker**: Analyze driving behaviors, fuel consumption, and vehicle age to calculate greenhouse gas offsets and award green fuel discounts.

---

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.
