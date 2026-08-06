# Mecha Connect — Product Requirements Document

**Version:** 1.0  
**Status:** Draft  
**Last Updated:** 2026-07-29  
**Owner:** Product Team  

---

## 1. Product Vision

Mecha Connect is an AI-powered roadside assistance ecosystem connecting vehicle owners, mechanics, fuel partners, spare part sellers, and administrators through a unified platform.

> "Uber + Swiggy + AI Assistant" for vehicle services.

---

## 2. Problem Statement

- Vehicle breakdowns are stressful — owners struggle to find trusted help quickly
- No unified platform exists for roadside assistance in India
- Pricing is opaque — users overpay for emergency repairs
- Mechanic discovery is offline/word-of-mouth
- Fuel delivery during emergencies is fragmented
- Spare part sourcing is disconnected from repair services

---

## 3. Target Audience

### Primary
- **Vehicle owners** (2-wheeler, 3-wheeler, car) in semi-urban and urban India
- Daily commuters aged 18–45
- Tech-savvy users who prefer app-based services

### Secondary
- Fleet operators (delivery, logistics)
- Women drivers (safety-focused roadside assistance)
- Long-distance travelers

### Tertiary
- Mechanics (service providers on the platform)
- Fuel station partners
- Spare part sellers

---

## 4. User Personas

### Persona A — Rajesh (Daily Commuter)
- Age: 28, Location: Hyderabad
- Vehicle: Honda Activa (2-wheeler)
- Pain: Bike breaks down 2×/year, no idea which mechanic to trust
- Need: Fast, verified mechanic within 10 minutes

### Persona B — Priya (Safety-Conscious Driver)
- Age: 32, Location: Bangalore
- Vehicle: Hyundai i10 (4-wheeler)
- Pain: Stranded at night, worried about safety
- Need: Tracked mechanic arrival, SOS, verified profiles

### Persona C — Vikram (Fleet Owner)
- Age: 40, Location: Chennai
- Vehicles: 10 delivery bikes
- Pain: Frequent breakdowns, inconsistent servicing costs
- Need: Bulk service booking, cost tracking, mechanic ratings

---

## 5. Competitive Analysis

| Feature | Mecha Connect | UrbanPiper | GoMechanic | Park+ |
|---------|---------------|------------|------------|-------|
| AI Diagnosis | ✅ | ❌ | ❌ | ❌ |
| Mechanic Booking | ✅ | ❌ | ✅ | ❌ |
| Fuel Delivery | 🔲 Planned | ❌ | ❌ | ✅ |
| Spare Parts Marketplace | 🔲 Planned | ❌ | ✅ | ❌ |
| Real-time Tracking | ✅ | ❌ | ❌ | ❌ |
| SOS Emergency | ✅ | ❌ | ❌ | ✅ |
| Partner App | 🔲 Planned | ✅ | ❌ | ❌ |
| Indian Market Focus | ✅ | ✅ | ✅ | ✅ |

---

## 6. Unique Selling Proposition (USP)

1. **AI-Powered Diagnosis** — Describe symptoms, get fault prediction + cost estimate before booking
2. **End-to-End Booking** — From diagnosis to payment, one seamless flow
3. **Multi-Service Ecosystem** — Mechanic + Fuel + Parts in one app
4. **Real-Time Tracking** — Know exactly when help arrives
5. **Verified Professionals** — Rated mechanics, transparent pricing

---

## 7. Business Model

### Revenue Streams
| Stream | Description | Timeline |
|--------|-------------|----------|
| Commission per booking | 15–20% on mechanic services | Sprint 2 |
| Fuel delivery margin | ₹20–50 per delivery | Sprint 1.7 |
| Marketplace listing | ₹99/month for spare part sellers | Sprint 1.8 |
| Featured mechanic listings | ₹499/month for priority placement | Sprint 2 |
| AI Diagnosis API | Subscription for fleet operators | Sprint 3 |

### Unit Economics
- **CAC (Customer Acquisition Cost):** ₹150 (digital marketing)
- **Average Order Value:** ₹450 (mechanic service)
- **LTV:** ₹2,250 (5 transactions × ₹450)
- **Payback Period:** 3 transactions

---

## 8. MVP Scope

### In Scope (Sprint 1)
- ✅ Splash, Onboarding, Auth
- ✅ Home Dashboard
- ✅ Vehicle Service Request + AI Diagnosis
- ✅ Mechanic Booking (browse → book → track → review)
- ✅ Responsive Layout
- ✅ Dark Mode

### In Scope (Sprint 2)
- 🔲 Backend Integration
- 🔲 Fuel Delivery
- 🔲 Marketplace (Spare Parts)

### Out of Scope
- ❌ Partner App (Sprint 4)
- ❌ Admin Dashboard (Sprint 5)
- ❌ Voice Assistant (Post-MVP)

---

## 9. Success Metrics

| Metric | Target |
|--------|--------|
| Mechanic ETA | < 15 minutes |
| Booking Completion Rate | > 80% |
| User Rating | > 4.0 ★ |
| Crash-free Rate | > 99.5% |
| Page Load Time | < 2 seconds |
| dart analyze | 0 errors |
| Build Success | 100% |

---

## 10. Future Scope

- Voice-activated SOS
- Predictive maintenance alerts
- Insurance claim integration
- Multi-language support (Hindi, Telugu, Tamil)
- Offline mode with cached mechanic data
- Subscription plans for frequent users
- Corporate fleet accounts
