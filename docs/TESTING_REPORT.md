# Test Strategy & Quality Assurance Report
## Real-Time Cycle Sharing & Booking Platform with Integrated Wallet
**Document Identifier:** TST-CSB-2026-V1.0  
**Project Domain:** Software Development & Operations

---

### 1. Test Strategy & Objectives

The QA framework applies multi-tiered verification:
1. **Unit Testing**: Isolated verification of domain models, validators, fee calculation algorithms, and wallet balance rules.
2. **Integration Testing**: End-to-end API lifecycle testing covering user authentication, station discovery, cycle unlocking, ride tracking, and wallet deduction.
3. **Pessimistic Concurrency Testing**: Testing simultaneous ride starts and wallet debits to ensure zero double-spend or negative balances.
4. **Security Testing**: Unauthenticated request blocking, expired/invalid token handling, and unauthorized cycle access.

---

### 2. Test Cases Specification

| Test Case ID | Test Category | Target Feature | Description / Scenario | Expected Result |
| :--- | :--- | :--- | :--- | :--- |
| **TC-AUTH-01** | Functional | User Auth | User registration with valid email and password | Returns HTTP 201; User created; Empty wallet auto-provisioned ($0.00) |
| **TC-AUTH-02** | Functional | User Auth | User login with valid credentials | Returns HTTP 200 with authentication token |
| **TC-WLT-01** | Business Logic | Wallet | Top-up wallet balance by $20.00 | Returns HTTP 200; balance increases to $20.00; credit audit log generated |
| **TC-WLT-02** | Validation | Wallet | Attempt ride start with balance < $5.00 | Returns HTTP 400 "Insufficient balance. Minimum $5.00 required." |
| **TC-RIDE-01** | Integration | Booking | Start ride on available cycle with sufficient balance | Returns HTTP 201; cycle status becomes `IN_USE`; lock status `UNLOCKED` |
| **TC-RIDE-02** | Validation | Booking | Attempt to start ride on already `IN_USE` cycle | Returns HTTP 400 "Cycle is currently unavailable" |
| **TC-RIDE-03** | End-to-End | Booking & Fare | End active ride at valid station | Returns HTTP 200; fare deducted; wallet transaction recorded; cycle restored to `AVAILABLE` |
| **TC-RIDE-04** | Concurrency | Wallet / ACID | Simultaneous debit requests against single wallet | Pessimistic locking prevents overdraft; transactions processed sequentially |

---

### 3. Automated Test Execution Guide

To execute the automated test suite within the Django backend:
```bash
python manage.py test core
```

Sample output:
```
Creating test database for alias 'default'...
System check identified no issues (0 silenced).
........
----------------------------------------------------------------------
Ran 8 tests in 0.412s

OK
Destroying test database for alias 'default'...
```
