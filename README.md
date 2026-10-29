# 🚲 PalPedal: Real-Time Cycle Sharing Platform with Integrated Digital Wallet

> **Course & Domain:** Software Development & Operations (DevOps)  
> **Tech Stack:** Flutter (Android Mobile Client) • Django REST Framework (Backend) • PostgreSQL (Database) • Docker & Compose (Containerization) • GitHub Actions (CI/CD)

---

## 🌟 Executive Summary

**PalPedal** is an enterprise-grade micro-mobility cycle sharing and booking ecosystem. It combines a real-time mobile application with a high-performance backend, an ACID-compliant digital wallet, smart docking station telemetry, and full DevOps automation.

### 📋 Key Achievements & Resume Alignment
- **Full-Stack Android App**: Designed and implemented in **Flutter** featuring real-time station discovery, QR-code cycle unlocking, live ride telemetry (duration & fare), and integrated digital wallet management.
- **Robust Scalable Backend**: Built with **Django REST Framework** backed by **PostgreSQL**, implementing pessimistic locking (`select_for_update`) to prevent double-spending or overdrafts.
- **Operations & DevOps**: Packaged into multi-container **Docker Compose** orchestration with **Nginx** reverse proxy, automated **GitHub Actions CI/CD** pipelines for automated linting, test suites, and container builds.
- **Standardized Documentation**: Comprehensive IEEE 830 **Software Requirements Specification (SRS)**, **System Architecture & Design Document (SDD)**, **Testing Report**, and **Operations Guide**.

---

## 🏗️ System Architecture

```
                                +-----------------------------------+
                                |     PalPedal Flutter Client       |
                                |  (Android App / Material Design 3)|
                                +-----------------+-----------------+
                                                  |
                                    HTTPS / REST  |  Port 80/443
                                                  v
                                +-----------------------------------+
                                |        Nginx Reverse Proxy        |
                                +-----------------+-----------------+
                                                  |
                                    Gunicorn WSGI |  Port 8000
                                                  v
                      +-------------------------------------------------------+
                      |             Django REST Framework Backend             |
                      |  - Auth & Profile Engine    - Fleet & Station Telemetry |
                      |  - Ride Lifecycle Engine   - Atomic Digital Wallet     |
                      +-------------------+--------------------+--------------+
                                          |                    |
                                     Port | 5432          Port | 6379
                                          v                    v
                                +--------------------+  +---------------+
                                | PostgreSQL 16 DB   |  |  Redis Cache  |
                                | (ACID Transactions)|  |  & Broker     |
                                +--------------------+  +---------------+
```

---

## 📁 Repository Structure

```
palpedal/
├── backend/                             # Django REST Framework Backend
│   ├── cycle_sharing/                   # Django settings, WSGI, URLs
│   │   ├── settings.py                  # Dual-mode DB (PostgreSQL + SQLite fallback)
│   │   ├── urls.py                      # Root routing
│   │   └── wsgi.py
│   ├── core/                            # Core domain application
│   │   ├── models.py                    # Wallet, WalletTransaction, Station, Cycle, RideBooking
│   │   ├── serializers.py               # DRF Serializers
│   │   ├── views.py                     # Atomic APIs (Auth, Wallet, Rides, Stations)
│   │   ├── urls.py                      # REST endpoints
│   │   ├── admin.py                     # Rich Django admin control center
│   │   ├── tests.py                     # Automated unit & integration test suite
│   │   └── management/commands/
│   │       └── seed_data.py             # One-command seed data generator
│   ├── templates/
│   │   └── web_demo.html                # Interactive browser-based simulation dashboard
│   ├── requirements.txt
│   └── Dockerfile
├── frontend_flutter/                    # Complete Android Flutter Client
│   ├── pubspec.yaml
│   ├── android/app/src/main/
│   │   └── AndroidManifest.xml          # Permissions (Internet, Camera, GPS)
│   └── lib/
│       ├── main.dart
│       ├── models/                      # User, Wallet, Station, Cycle, Ride models
│       ├── services/                    # ApiService (REST HTTP client)
│       ├── providers/                   # Auth, Wallet, Fleet, Ride state management
│       └── screens/                     # Login, HomeMap, QRScan, ActiveRide, Wallet, History
├── devops/                              # Deployment & Operations
│   ├── docker-compose.yml               # Multi-service stack (Postgres + Redis + Backend + Nginx)
│   ├── Dockerfile.backend               # Production container definition
│   ├── nginx.conf                       # Edge reverse proxy configuration
│   └── .env.example                     # Environment secrets template
├── .github/workflows/
│   └── ci-cd.yml                        # GitHub Actions CI/CD pipeline
├── docs/                                # Software Engineering & Operations Documentation
│   ├── SRS.md                           # IEEE Std 830 Software Requirements Specification
│   ├── SYSTEM_DESIGN.md                 # Architecture, ERD, Class & Sequence flows
│   ├── TESTING_REPORT.md                # Test strategy, matrix, coverage report
│   └── DEVOPS_OPERATIONS.md             # Production rollout & container orchestration
└── README.md
```

---

## ⚡ Quickstart Guide

### Option 1: Instant Local Execution (Python / Django)

```bash
# 1. Navigate to backend
cd palpedal/backend

# 2. Enable the local-only SQLite development setup
export DEBUG=True
export SECRET_KEY=local-development-only

# 3. Apply database migrations
python manage.py migrate

# 4. Seed demonstration fleet, stations, and user account
python manage.py seed_data

# 5. Run automated test suite
python manage.py test core

# 6. Launch the development server & interactive simulator
python manage.py runserver 8000
```
Open **`http://127.0.0.1:8000/`** in your browser to interact with the full real-time ride simulator, unlock bikes, top up your wallet, and test the system live!

### Deploying the Django app to Vercel

Vercel functions do not provide a persistent writable SQLite database. Configure a managed PostgreSQL database and set these Vercel environment variables for **Production** (and Preview if used):

| Variable | Value |
| --- | --- |
| `DEBUG` | `False` |
| `SECRET_KEY` | A newly generated, random secret; do not reuse the repository's example value |
| `ALLOWED_HOSTS` | `palpedal.vercel.app` |
| `DATABASE_URL` | The PostgreSQL connection string from the managed database provider |
| `DB_SSL_REQUIRE` | `True` when the provider requires TLS (the recommended production setting) |

The backend accepts `DATABASE_URL`, `POSTGRES_URL`, or `POSTGRES_URL_NON_POOLING`. Set the database variables in Vercel before deploying. Then, from `backend/`, install the requirements and run `python manage.py migrate --noinput` against that same production database. Run `python manage.py seed_data` once if the demo fleet and rider should be available. Do not use a local SQLite file or run database migrations on every serverless request.

---

### Option 2: Production Containerized Stack (Docker Compose)

```bash
# 1. Navigate to DevOps configuration
cd palpedal/devops

# 2. Launch PostgreSQL, Redis, Backend, and Nginx
docker-compose up --build -d

# 3. Check container health
docker-compose ps
```

---

### Option 3: Running the Flutter Android Client

```bash
cd palpedal/frontend_flutter
flutter pub get
flutter run
```

---

## 💳 PalPedal Digital Wallet & Ride Tariff Specification

### Tariff Structure
- **Base Unlock Fee:** `$1.50`
- **Per-Minute Charge:** `$0.15 / min`
- **Minimum Wallet Balance to Unlock:** `$5.00`

### Concurrency & Data Consistency
Wallet balance deductions use Django's atomic database transactions with pessimistic row locking:
```python
with transaction.atomic():
    wallet = Wallet.objects.select_for_update().get(user=request.user)
    wallet.balance -= fare
    wallet.save()
    WalletTransaction.objects.create(
        wallet=wallet,
        transaction_type='DEBIT',
        amount=fare,
        ride=ride,
        description=f'Ride fare ({mins} mins on {cycle.cycle_number})'
    )
```
This guarantees **zero double-spending**, prevents race conditions, and logs an immutable audit trail.

---

## 🧪 Automated Testing & CI/CD Verification

The test suite covers:
- User registration and automatic wallet provisioning (`TC-AUTH-01`)
- Wallet recharge and balance verification (`TC-WLT-01`)
- Minimum balance threshold enforcement (`TC-WLT-02`)
- Real-time ride start, cycle state transition to `IN_USE`, lock status `UNLOCKED` (`TC-RIDE-01`)
- Conclude ride, automated fare calculation, and wallet debit (`TC-RIDE-03`)
- Denial of ride start on already-rented cycle (`TC-RIDE-02`)

Execute via:
```bash
python manage.py test core --verbosity 2
```

---

## 📄 Documentation Artifacts
Detailed SDLC documents are provided in the [`docs/`](./docs/) directory:
- [System Requirements Specification (SRS)](./docs/SRS.md)
- [System Architecture & Design Document](./docs/SYSTEM_DESIGN.md)
- [Testing & Quality Assurance Report](./docs/TESTING_REPORT.md)
- [DevOps & Operations Guide](./docs/DEVOPS_OPERATIONS.md)
