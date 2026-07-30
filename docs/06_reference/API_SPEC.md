# Mecha Connect — API Specification

**Version:** 1.1.0  
**Status:** Draft (Sprint 2 implementation)  
**Last Updated:** 2026-07-29  
**Owner:** Architecture Team  

---

## Table of Contents

1. [System Health](#1-system-health)
2. [Conversation & Chat](#2-conversation--chat)
3. [Vehicle Diagnosis](#3-vehicle-diagnosis)
4. [Knowledge Base (RAG)](#4-knowledge-base-rag)
5. [Planned Endpoints (Sprint 2)](#5-planned-endpoints-sprint-2)
6. [Error Codes](#6-error-codes)
7. [Authentication & Pagination](#7-authentication--pagination)
8. [Related Documents](#8-related-documents)

---

## Base Information

| Property | Value |
|----------|-------|
| Base Path | `/api/v1` |
| Server | FastAPI (Python) |
| Authentication | Bearer JWT (planned) |
| Pagination | Cursor-based (planned) |

---

## 1. System Health

### `GET /health`
Verify API server status.

**Response (200):**
```json
{
  "status": "healthy",
  "service": "Mecha Connect Backend",
  "version": "1.0.0"
}
```

---

## 2. Conversation & Chat

### `POST /api/v1/conversation/session`
Create a new conversation session.

**Response (201):**
```json
{
  "session_id": "session_fc5e2924031c"
}
```

### `GET /api/v1/conversation/history`
Retrieve conversation history.

**Params:** `session_id` (string, required)

**Response (200):**
```json
{
  "session_id": "session_fc5e2924031c",
  "history": [
    { "role": "user", "content": "My bike won't start." },
    { "role": "assistant", "content": "The red battery charging system light indicates..." }
  ]
}
```

### `POST /api/v1/conversation/chat`
Send a user query. Classifies intent and routes to appropriate engine.

**Request:**
```json
{
  "message": "My engine won't start and makes a clicking noise.",
  "session_id": "session_fc5e2924031c"
}
```

**Response (200) — Diagnostic:**
```json
{
  "response": "Based on my diagnostics, the most likely issue is...",
  "intent": "Vehicle Diagnosis",
  "session_id": "session_fc5e2924031c",
  "diagnostic_details": {
    "predicted_fault": "Alternator or Battery Failure",
    "estimated_cost": 4500,
    "repair_time": "1.5 hours",
    "safety_advice": "CAUTION: Turn off all non-essential electrics."
  },
  "latency_ms": 1220.5
}
```

---

## 3. Vehicle Diagnosis

### `POST /api/v1/diagnosis/diagnose`
Call the XGBoost/rule-based fault classifier. Supports both telemetry-mode and symptom-mode.

**Request:**
```json
{
  "mileage": 85000,
  "obd_error_code": "P0300",
  "engine_temp": 95.0,
  "vibration_level": 0.5,
  "battery_voltage": 12.6,
  "oil_pressure": 45.0,
  "vehicle_type": "Car",
  "brand": "Honda",
  "model": "Civic",
  "fuel_type": "Petrol",
  "symptoms": ["Engine vibration", "Low pickup"]
}
```

**Response (200):**
```json
{
  "predicted_fault": "Engine Misfire",
  "confidence": 0.95,
  "estimated_cost": 3500,
  "repair_time": "2 hours",
  "safety_advice": "WARNING: Engine misfire can damage the catalytic converter.",
  "diagnosis_mode": "symptom"
}
```

---

## 4. Knowledge Base (RAG)

### `POST /api/v1/knowledge/query`
Query the FAISS vector database for grounded documentation answers.

**Request:**
```json
{
  "query": "P0115 check engine light sensor",
  "k": 2
}
```

**Response (200):**
```json
{
  "answer": "P0115 indicates an Engine Coolant Temperature (ECT) Circuit Malfunction...",
  "sources": [
    {
      "source": "symbols_guide.txt",
      "category": "general",
      "score": 0.352
    }
  ]
}
```

---

## Planned Endpoints (Sprint 2)

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/v1/auth/login` | User login |
| POST | `/api/v1/auth/register` | User registration |
| GET | `/api/v1/mechanics` | List nearby mechanics |
| GET | `/api/v1/mechanics/{id}` | Mechanic details |
| POST | `/api/v1/bookings` | Create booking |
| GET | `/api/v1/bookings/{id}` | Get booking status |
| POST | `/api/v1/payments` | Process payment |
| GET | `/api/v1/vehicles` | User vehicles |
| POST | `/api/v1/vehicles` | Add vehicle |

---

## 7. Authentication & Pagination

### Authentication (Planned Sprint 2)
| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/auth/login` | Login → returns JWT |
| POST | `/api/v1/auth/register` | Register new user |
| POST | `/api/v1/auth/refresh` | Refresh expired token |
| POST | `/api/v1/auth/logout` | Invalidate token |

All authenticated endpoints require header: `Authorization: Bearer <token>`

### Pagination (Planned Sprint 2)
All list endpoints will use cursor-based pagination:
```json
{
  "cursor": "eyJsYXN0X2lkIjogMTIzfQ==",
  "limit": 20,
  "data": [...]
}
```

---

## 8. Related Documents

- [SYSTEM_ARCHITECTURE.md](../02_architecture/SYSTEM_ARCHITECTURE.md)
- [AI_ARCHITECTURE.md](../02_architecture/AI_ARCHITECTURE.md)
- [THIRD_PARTY_SERVICES.md](THIRD_PARTY_SERVICES.md)
- [DATABASE_SCHEMA.md](../02_architecture/DATABASE_SCHEMA.md)

