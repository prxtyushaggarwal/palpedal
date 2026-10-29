# System Architecture & Design Document
## Real-Time Cycle Sharing & Booking Platform with Integrated Wallet
**Document Identifier:** SDD-CSB-2026-V1.0  
**Project Domain:** Software Development & Operations

---

### 1. System Architecture Overview

The system is built on a 3-tier distributed microservices pattern:
1. **Presentation Tier (Client)**: Flutter Cross-Platform Client (Android focus) with Material Design 3, Provider state management, and HTTP API integration.
2. **Application Tier (Backend)**: Django 5 / 6 with Django REST Framework (DRF) handling business logic, authentication, ride state machine, and atomic wallet transactions.
3. **Persistence Tier (Database)**: PostgreSQL (or SQLite in local dev) maintaining transactional relational integrity with ACID guarantees.

```mermaid
flowchart TD
    subgraph Client["Flutter Mobile Client (Android)"]
        UI["Material 3 Screens\n(Map, QR Scan, Active Ride, Wallet)"]
        State["State Management\n(Provider / Riverpod)"]
        Service["API & Storage Client\n(Dio / http)"]
        UI --> State
        State --> Service
    end

    subgraph Gateway["Reverse Proxy & Web Server"]
        Nginx["Nginx Reverse Proxy\n(Port 80/443, SSL, Static Assets)"]
        Gunicorn["Gunicorn WSGI Application Server"]
        Nginx --> Gunicorn
    end

    subgraph Backend["Django REST Backend"]
        AuthView["Auth & Profile API"]
        FleetView["Station & Cycle Discovery API"]
        RideView["Booking & Ride Lifecycle Engine"]
        WalletView["Atomic Wallet & Transaction Engine"]
        
        Gunicorn --> AuthView
        Gunicorn --> FleetView
        Gunicorn --> RideView
        Gunicorn --> WalletView
    end

    subgraph Database["PostgreSQL Database Engine"]
        Tables[("Tables:
        - auth_user
        - core_wallet
        - core_wallettransaction
        - core_station
        - core_cycle
        - core_ridebooking")]
        FleetView --> Tables
        RideView --> Tables
        WalletView --> Tables
    end

    Service -- HTTPS / JSON REST --> Nginx
```

---

### 2. Entity-Relationship (ER) Diagram

```mermaid
erDiagram
    USER ||--|| WALLET : "owns"
    USER ||--o{ RIDE_BOOKING : "creates"
    WALLET ||--o{ WALLET_TRANSACTION : "records"
    STATION ||--o{ CYCLE : "docks"
    STATION ||--o{ RIDE_BOOKING : "originates / terminates"
    CYCLE ||--o{ RIDE_BOOKING : "used in"

    USER {
        int id PK
        string username
        string email
        string first_name
        string last_name
    }

    WALLET {
        uuid id PK
        int user_id FK
        decimal balance
        datetime updated_at
    }

    WALLET_TRANSACTION {
        uuid id PK
        uuid wallet_id FK
        string transaction_type "CREDIT | DEBIT"
        decimal amount
        string description
        datetime created_at
        uuid ride_id FK "optional"
    }

    STATION {
        uuid id PK
        string name
        decimal latitude
        decimal longitude
        string address
        int capacity
        int available_cycles
    }

    CYCLE {
        uuid id PK
        string qr_code UK
        string cycle_number
        uuid current_station_id FK "nullable"
        string status "AVAILABLE | IN_USE | MAINTENANCE"
        string lock_status "LOCKED | UNLOCKED"
        int battery_percentage
    }

    RIDE_BOOKING {
        uuid id PK
        int user_id FK
        uuid cycle_id FK
        uuid start_station_id FK
        uuid end_station_id FK "nullable"
        datetime start_time
        datetime end_time "nullable"
        decimal duration_minutes
        decimal total_fare
        string status "ACTIVE | COMPLETED | CANCELLED"
    }
```

---

### 3. Ride Lifecycle State Machine

```mermaid
stateDiagram-v2
    [*] --> AVAILABLE : Cycle docked at Station
    AVAILABLE --> IN_USE : User scans QR & starts ride\n(Wallet >= $5.00)
    IN_USE --> COMPLETED : User locks cycle at Station\n(Fare deducted from Wallet)
    IN_USE --> MAINTENANCE : Hardware fault reported
    MAINTENANCE --> AVAILABLE : Repaired & Rebalanced
    COMPLETED --> AVAILABLE : Cycle docked & locked
```

---

### 4. Sequence Diagram: Booking & Wallet Deduction Flow

```mermaid
sequenceDiagram
    autonumber
    actor Rider as Rider (Flutter App)
    participant API as Django REST API
    participant DB as PostgreSQL Database
    participant Wallet as Wallet Engine

    Rider->>API: POST /api/rides/start/ {cycle_qr: "CYC-101"}
    API->>DB: Fetch Cycle & User Wallet (Pessimistic Lock)
    DB-->>API: Wallet Balance ($15.00), Cycle Status (AVAILABLE)
    alt Balance < $5.00
        API-->>Rider: 400 Bad Request: Insufficient balance to start ride
    else Balance >= $5.00
        API->>DB: Set Cycle.status = 'IN_USE', lock = 'UNLOCKED'
        API->>DB: Create RideBooking (status: 'ACTIVE', start_time: now())
        DB-->>API: Booking Confirmed (UUID)
        API-->>Rider: 201 Created: Ride active, cycle unlocked
    end

    Note over Rider,API: Rider rides cycle. Telemetry pulses duration.

    Rider->>API: POST /api/rides/end/ {ride_id, end_station_id}
    API->>DB: Lock RideBooking, User Wallet & Cycle
    API->>Wallet: Calculate Fare: Base ($1.50) + (mins * $0.15)
    Wallet->>DB: Deduct Fare from Wallet (atomic)
    Wallet->>DB: Insert WalletTransaction (DEBIT, amount, timestamp)
    API->>DB: Update Cycle: status='AVAILABLE', station=end_station
    API->>DB: Update RideBooking: status='COMPLETED', end_time=now(), fare
    DB-->>API: Commit Transaction
    API-->>Rider: 200 OK: Trip summary & updated balance
```
