# Mecha Connect — System Architecture

**Version:** 1.0  
**Status:** Locked  
**Last Updated:** 2026-07-29  
**Owner:** Architecture Team  

---

## 1. Architecture Overview

```mermaid
graph TB
    subgraph "Presentation Layer (Flutter)"
        SP[Splash Screen]
        OB[Onboarding]
        AU[Auth]
        HD[Home Dashboard]
        MB[Mechanic Booking]
        VSR[Vehicle Service Request]
        FS[Fuel Service]
        MP[Marketplace]
        ST[Settings]
        
        SP --> OB
        OB --> AU
        AU --> HD
        HD --> MB
        HD --> VSR
        HD --> FS
        HD --> MP
        HD --> ST
        
        subgraph "Mechanic Flow"
            MB1[Browse Nearby]
            MB2[Mechanic Details]
            MB3[Service Selection]
            MB4[Booking Summary]
            MB5[Confirmation]
            MB6[Live Tracking]
            MB7[Service Complete]
            MB8[Review]
            
            MB1 --> MB2 --> MB3 --> MB4 --> MB5 --> MB6 --> MB7 --> MB8
        end
        MB --> MB1
    end

    subgraph "Business Logic Layer"
        VM[ViewModels / State Management]
        AP[API Repositories]
        LP[Local Persistence]
        AI[AI Service]
    end

    subgraph "Data Layer"
        FB[Firebase / Supabase]
        LS[Local Storage / Hive]
        MAP[Maps Service Tile Server]
    end

    subgraph "External Services"
        GM[Gemini AI API]
        OS[OpenStreetMap]
    end

    subgraph "Mock Data Layer"
        MD[Mock Data<br/>lib/mechanic/mock_data.dart<br/>lib/home/mock_data.dart]
    end

    HD --> VM
    VM --> AP
    VM --> LP
    VM --> AI
    AP --> MD
    LP --> LS
    AI --> GM
    MAP --> OS
```

---

## 2. Component Architecture

```mermaid
graph LR
    subgraph "Flutter App"
        DIR[DI / Service Locator<br/>get_it]
        ROU[GoRouter<br/>Navigation]
        STT[State<br/>Provider]
        THM[Theme<br/>Dark/Light]
        REPS[Repositories]
    end

    subgraph "Backend (Planned)"
        API[FastAPI<br/>REST API]
        WS[WebSocket<br/>Tracking]
        DB[PostgreSQL]
        RD[Redis<br/>Cache]
    end

    subgraph "AI Engine"
        GCC[Gemini Context<br/>Caching]
        DIA[AI Diagnosis<br/>Engine]
        MAT[Matching<br/>Algorithm]
    end

    DIR --> STT
    STT --> REPS
    REPS --> API
    REPS --> GCC
    ROU --> DIR
    THM --> STT
    API --> DB
    API --> WS
    API --> RD
    GCC --> DIA
    GCC --> MAT
```

---

## 3. Data Flow: Mechanic Booking

```mermaid
sequenceDiagram
    participant User as User (Flutter)
    participant App as App State
    participant AI as AI Service
    participant API as Backend API
    participant DB as Database
    
    User->>App: Describe vehicle issue
    App->>AI: Send symptoms text
    AI-->>App: Return fault prediction + estimate
    App-->>User: Show diagnosis + cost
    User->>App: Request mechanic
    App->>API: GET /mechanics/nearby (lat, lng)
    API->>DB: Query available mechanics
    DB-->>API: Mechanic list
    API-->>App: Nearby mechanics
    App-->>User: Display mechanic cards
    User->>App: Select mechanic + book
    App->>API: POST /booking (mechanic_id, service, location)
    API->>DB: Create booking
    API-->>App: Booking confirmed with ETA
    App-->>User: Show confirmation + live tracking
    API->>App: WebSocket: location updates
    App-->>User: Mechanic on the way
    App-->>User: Mechanic arrived
    User->>App: Service completed
    App->>API: POST /booking/complete
    App-->>User: Review prompt
```

---

## 4. Navigation Architecture

```mermaid
flowchart TD
    SP[Splash] --> OB[Onboarding]
    OB --> LG[Login]
    OB --> RG[Register]
    LG --> HD[Home]
    RG --> HD
    HD --> MCN[Mecahnic Nearby]
    HD --> VEH[Vehicle Service]
    HD --> FL[Fuel Delivery]
    HD --> MP[Marketplace]
    HD --> ST[Settings]
    
    MCN --> MD[Mechanic Details]
    MD --> SV[Select Service]
    SV --> BS[Booking Summary]
    BS --> CF[Confirmation]
    CF --> LT[Live Tracking]
    LT --> SC[Service Complete]
    SC --> RV[Review]
    
    VEH --> VR[Vehicle Registration]
    VR --> VH[Vehicle History]
    
    FL --> FO[Fuel Order]
    FO --> FT[Fuel Tracking]
    
    MP --> PL[Product Listing]
    PL --> PD[Product Detail]
    PD --> OR[Order]
    
    ST --> PR[Profile]
    ST --> TH[Theme]
    ST --> AB[About]
    ST --> AB --> LG
    
    classDef alt fill:#f96,stroke:#333,stroke-width:2px;
    class SP,OB,LG,RG,HD alt;
    classDef book fill:#9cf,stroke:#333,stroke-width:2px;
    class MCN,MD,SV,BS,CF,LT,SC,RV book;
```

---

## 5. State Management Architecture

```mermaid
flowchart TD
    subgraph "Provider Layer"
        AP[AppProvider]
        TP[ThemeProvider]
        LP[LocationProvider]
        BP[BookingProvider]
        MP[MechanicProvider]
        VP[VehicleProvider]
    end
    
    subgraph "Service Layer"
        LS[LocationService]
        AS[APIService]
        AIS[AIService]
        NS[NotificationService]
    end
    
    subgraph "Repository Layer"
        MR[MechanicRepository]
        BR[BookingRepository]
        VR[VehicleRepository]
    end
    
    AP --> LS
    LP --> LS
    VP --> VR
    MP --> MR
    BP --> BR
    
    MR --> AS
    BR --> AS
    VR --> AS
    AIS --> AS
```

---

## 6. Directory Structure

```
lib/
├── main.dart
├── auth/
├── home/
│   └── widgets/
├── mechanic/
│   ├── screens/
│   └── widgets/
├── homescreen/
├── bottom_bar/
├── Starting_screen/
├── parts/
├── theme/
├── widgets/
├── services/
└── test/
```

---

## 7. Related Documents

- [PROJECT_ARCHITECTURE.md](PROJECT_ARCHITECTURE.md)
- [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md)
- [API_SPEC.md](../06_reference/API_SPEC.md)
- [AI_ARCHITECTURE.md](AI_ARCHITECTURE.md)
- [DEPLOYMENT.md](../03_development/DEPLOYMENT.md)

