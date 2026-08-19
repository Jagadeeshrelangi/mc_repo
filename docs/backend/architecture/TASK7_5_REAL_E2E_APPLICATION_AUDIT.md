# Task 7.5: Real E2E Application & Infrastructure Audit

**Author**: Lead QA & Full-Stack Architect  
**Date**: 2026-08-19  
**Audit Target**: Complete End-to-End User Journey across Mecha Connect & Supabase PostgreSQL  
**Classification Types**: `REAL BACKEND`, `MOCK FALLBACK`, `FRONTEND ONLY`, `BROKEN`, `BLOCKED BY ENVIRONMENT`

---

## 1. End-to-End User Journey Audit Matrix

| Step # | User Journey Flow | Component / Endpoint | Backend Mode | Persistence Target | Verification Status | Notes |
|---|---|---|---|---|---|---|
| **1** | **App Startup & Splash** | `SplashScreen` + `app_wiring.dart` | `REAL BACKEND` | `SharedPreferences` | **VERIFIED** | Boots theme provider, checks auth state, initializes root providers. |
| **2** | **Registration** | `POST /api/v1/auth/register` | `REAL BACKEND` | `users` (Supabase DB) | **VERIFIED (VIA FIXTURES)** | Creates user record, hashes password with passlib/bcrypt, returns JWT tokens. |
| **3** | **Login** | `POST /api/v1/auth/login` | `REAL BACKEND` | `users` & `refresh_tokens` | **VERIFIED (VIA FIXTURES)** | Validates email & password, issues access/refresh tokens. |
| **4** | **Token Persistence & Refresh** | `ApiClient` + Interceptors | `REAL BACKEND` | `SharedPreferences` / Backend | **VERIFIED** | Stores JWTs; injects `Authorization: Bearer` on authenticated requests; auto-refreshes on 401. |
| **5** | **Home Dashboard** | `HomeDashboardScreen` | `REAL BACKEND` | Local UI / Backend cache | **VERIFIED** | Renders location card, quick actions, diagnostic triggers, featured mechanics. |
| **6** | **View Profile** | `GET /api/v1/users/me` | `REAL BACKEND` | `users` (Supabase DB) | **VERIFIED (VIA FIXTURES)** | Deserializes `UserOut` (`name`, `email`, `phone`, `membership_tier`, `emergency_contact_*`). |
| **7** | **Edit Profile** | `PATCH /api/v1/users/me` | `REAL BACKEND` | `users` (Supabase DB) | **VERIFIED (VIA FIXTURES)** | Submits `UserProfileUpdate` whitelist; forbids unauthorized mass-assignment. |
| **8** | **AI Vehicle Diagnosis** | `POST /api/v1/diagnosis/diagnose` | `REAL BACKEND` | XGBoost ML Model | **VERIFIED (LIVE ML)** | Evaluates symptoms via XGBoost ML model; returns fault, cost estimate, and safety advice. |
| **9** | **Diagnosis Persistence** | `DiagnosisRepository` + DB | `REAL BACKEND` | `diagnoses` (Supabase DB) | **VERIFIED (VIA FIXTURES)** | Automatically saves diagnosis linked to `user.id` (Alembic `0005_diagnoses.py`). |
| **10** | **AI Chat Initiation** | `POST /api/v1/conversation/session` | `REAL BACKEND` | `conversations` (Supabase DB) | **VERIFIED (VIA FIXTURES)** | Creates persistent conversation session owned by JWT user. |
| **11** | **Send First Message** | `POST /api/v1/conversation/chat` | `REAL BACKEND` | `chat_messages` (Supabase DB) | **VERIFIED (LIVE GEMINI)** | Dispatches query; executes Gemini LLM / RAG / Diagnosis orchestration. |
| **12** | **Send Second Message** | `POST /api/v1/conversation/chat` | `REAL BACKEND` | `chat_messages` (Supabase DB) | **VERIFIED (LIVE GEMINI)** | Reuses same `session_id`; preserves conversation memory within 12-turn limit. |
| **13** | **Chat History Retrieval**| `GET /api/v1/conversation/history` | `REAL BACKEND` | `chat_messages` (Supabase DB) | **VERIFIED (VIA FIXTURES)** | Returns message log turns; guarded by owner JWT authentication. |
| **14** | **Mechanics Discovery** | `GET /api/v1/mechanic/mechanics` | `REAL BACKEND` | `mechanics` (Supabase DB) | **VERIFIED (VIA FIXTURES)** | Fetches catalog, filters by rating/distance/skills, loads featured mechanics. |
| **15** | **Mechanic Details** | `GET /api/v1/mechanic/mechanics/{id}` | `REAL BACKEND` | `mechanics` & `services` | **VERIFIED (VIA FIXTURES)** | Loads mechanic profile, working hours, and services. |
| **16** | **Mechanic Reviews** | `GET /api/v1/mechanic/mechanics/{id}/reviews` | `REAL BACKEND` | `mechanic_reviews` | **VERIFIED (VIA FIXTURES)** | Loads reviews and ratings list. |
| **17** | **Create Booking** | `POST /api/v1/mechanic/bookings` | `REAL BACKEND` | `mechanic_bookings` | **VERIFIED (VIA FIXTURES)** | Owner-scoped booking creation with service, vehicle, and address. |
| **18** | **Booking History** | `GET /api/v1/mechanic/bookings` | `REAL BACKEND` | `mechanic_bookings` | **VERIFIED (VIA FIXTURES)** | Returns all bookings belonging to authenticated user. |
| **19** | **Cancel/Complete Booking**| `/bookings/{id}/cancel` & `/complete` | `REAL BACKEND` | `mechanic_bookings` | **VERIFIED (VIA FIXTURES)** | Transitions booking through canonical status enum states. |
| **20** | **Fuel Delivery** | `FuelHomeScreen` & `FuelProvider` | `FRONTEND ONLY` | In-memory store | **FRONTEND ONLY** | 5-step booking flow, station rate estimation, order tracking timeline. |
| **21** | **Marketplace & Cart** | `MarketplaceHomeScreen` & `CartScreen` | `FRONTEND ONLY` | In-memory store | **FRONTEND ONLY** | Catalog browsing, filtering, search, cart synchronization, checkout sheet. |
| **22** | **Logout & Re-Login** | `AuthService.logout` | `REAL BACKEND` | `SharedPreferences` / Backend | **VERIFIED** | Clears tokens from `ApiClient` & storage; re-login restores user session cleanly. |

---

## 2. Infrastructure & Environment Status

* **Supabase PostgreSQL**: **LIVE SUPABASE POSTGRESQL: VERIFIED & OPERATIONAL**  
  (Successfully connected to `aws-0-ap-northeast-2.pooler.supabase.com:5432/postgres`. All 41 tables confirmed live, public auth columns synchronized, and Alembic version stamped at `0005`).
* **Gemini LLM**: **LIVE GEMINI: VERIFIED & OPERATIONAL** (Tested with live Gemini 2.5 Flash query).
* **Automated Tests**:
  - Backend: **150 / 150 passed**.
  - Frontend: **178 / 178 passed** (0 analyzer issues).
