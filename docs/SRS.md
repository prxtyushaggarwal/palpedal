# Software Requirements Specification (SRS)
## Real-Time Cycle Sharing & Booking Platform with Integrated Wallet
**Document Identifier:** SRS-CSB-2026-V1.0  
**Standard:** IEEE Std 830-1998  
**Project Domain:** Software Development & Operations (DevOps)

---

### 1. Introduction

#### 1.1 Purpose
This document specifies the software requirements for the **Real-Time Cycle Sharing and Booking System**, an enterprise-grade micro-mobility solution comprising a cross-platform mobile client (Flutter for Android), a scalable REST backend (Django REST Framework), a relational database engine (PostgreSQL), and automated containerized operations (Docker, CI/CD).

#### 1.2 Scope
The system facilitates automated public bicycle rental across designated smart docking stations. Key capabilities include:
- Station discovery and live cycle availability tracking.
- QR-code scan-to-unlock and IoT-based cycle lock state management.
- Dynamic ride telemetry (time elapsed, distance covered, live tariff calculation).
- Integrated prepaid digital wallet with atomic balance deduction and transactional audit log.
- Administrative operational dashboards for fleet rebalancing and revenue metrics.

#### 1.3 Definitions, Acronyms, and Abbreviations
- **DRF**: Django REST Framework
- **SRS**: Software Requirements Specification
- **JWT**: JSON Web Token
- **ACID**: Atomicity, Consistency, Isolation, Durability
- **GPS**: Global Positioning System
- **CI/CD**: Continuous Integration / Continuous Deployment

---

### 2. Overall Description

#### 2.1 Product Perspective
The system operates in a distributed client-server architecture:
```
+-------------------------------------------------------------+
|                  Flutter Client (Android)                   |
| (UI, State Management, Location Services, QR Scanner, Maps) |
+------------------------------+------------------------------+
                               | HTTPS / JSON REST API
                               v
+-------------------------------------------------------------+
|               Django REST Framework API Gateway             |
|   (Authentication, Booking Engine, Billing, Fleet State)    |
+------------------------------+------------------------------+
                               |
                               v
+-------------------------------------------------------------+
|                     PostgreSQL Database                     |
|     (Users, Wallets, Stations, Cycles, Rides, Audits)       |
+-------------------------------------------------------------+
```

#### 2.2 User Personas & Characteristics
1. **Registered Rider**: Users who create accounts, maintain prepaid wallet balances, locate bikes, scan to unlock, and view trip receipts.
2. **Operations Team / Fleet Manager**: Technicians responsible for station rebalancing, fleet maintenance, and cycle battery/mechanical health monitoring.
3. **System Administrator**: Manages pricing tariffs, system configurations, and audits financial transactions.

#### 2.3 Operating Environment
- **Server OS**: Linux (Ubuntu 22.04 LTS / Alpine containers) or Windows 10/11 Server.
- **Runtimes**: Python 3.11+, Flutter 3.x / Dart 3.x, PostgreSQL 15+.
- **Containerization**: Docker 24+, Docker Compose v2.

---

### 3. Specific Functional Requirements

#### 3.1 User Authentication & Authorization (FR-AUTH)
- **FR-AUTH-01**: System shall support email and password-based registration and token-based authentication.
- **FR-AUTH-02**: Upon user registration, the system shall automatically instantiate an empty digital wallet (`balance: $0.00`) linked to the new user.
- **FR-AUTH-03**: Secure endpoints shall require standard Bearer/Token authentication headers.

#### 3.2 Integrated Digital Wallet Engine (FR-WALLET)
- **FR-WALLET-01**: Users can inspect their current wallet balance in real time.
- **FR-WALLET-02**: Users can top up their digital wallet with specified denominations ($5, $10, $20, $50, custom).
- **FR-WALLET-03**: Ride initiation requires a minimum threshold balance ($5.00) in the user's wallet.
- **FR-WALLET-04**: Fare deductions must execute as atomic database transactions (`select_for_update`) to prevent race conditions and double-spending.
- **FR-WALLET-05**: Every financial modification creates an immutable `WalletTransaction` entry (Credit/Debit, amount, timestamp, ride reference).

#### 3.3 Station & Fleet Management (FR-FLEET)
- **FR-FLEET-01**: The system shall manage geographic stations with latitude, longitude, address, total capacity, and available bike slots.
- **FR-FLEET-02**: Cycles maintain unique identifiers (UUID/QR code strings), battery status, lock status (`LOCKED`, `UNLOCKED`), and operational state (`AVAILABLE`, `IN_USE`, `MAINTENANCE`).
- **FR-FLEET-03**: Clients can query stations within geographic radiuses or fetch real-time dock occupancy.

#### 3.4 Booking & Ride Lifecycle (FR-RIDE)
- **FR-RIDE-01 (Discovery)**: Rider views nearby stations and selects a cycle or scans a cycle's physical QR code.
- **FR-RIDE-02 (Unlock/Start)**: Upon validating wallet balance $\ge \$5.00$ and cycle status `AVAILABLE`, the system creates an active `RideBooking`, transitions cycle status to `IN_USE`, unlocks the smart lock, and marks station dock available.
- **FR-RIDE-03 (Active Ride)**: System tracks start time, route duration, and calculates real-time projected fare:
  $$\text{Total Fare} = \text{Base Fare } (\$1.50) + (\text{Minutes} \times \$0.15/\text{min})$$
- **FR-RIDE-04 (End Ride)**: User docks the bike at a destination station. The lock engages, the cycle status reverts to `AVAILABLE`, duration is finalized, total fare is calculated, and the amount is immediately deducted from the user's wallet.
- **FR-RIDE-05 (Receipt)**: The user receives a detailed ride summary including duration, distance, stations, and debit confirmation.

---

### 4. Non-Functional Requirements (NFR)

- **NFR-01 Performance**: REST API endpoints shall respond in $<200\text{ ms}$ under standard loads.
- **NFR-02 Concurrency & Data Integrity**: High-concurrency wallet transactions must adhere to ACID properties with pessimistic locking.
- **NFR-03 Security**: Passwords salted and hashed with PBKDF2/Argon2. Sensitive API keys loaded via environment variables (`.env`).
- **NFR-04 Availability**: Target 99.9% uptime achieved through Dockerized microservices and automated health checks.
- **NFR-05 Portability**: Client codebase runs on Android (and iOS/Web); backend services packaged into lightweight Open Container Initiative (OCI) images.
