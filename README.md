# 💳 VYLT

## Financial Intelligence & Liquidity Management App (Flutter)

VYLT is a Flutter-based fintech application that explores how predictive financial modeling, risk awareness, and friction-based UX can improve user decision-making.

Unlike traditional banking apps that act as passive ledgers, VYLT introduces:

- Runway forecasting  
- Risk visualization  
- Intent-based transaction flows  
- Modular financial state handling  

The project is built as an engineering-focused portfolio piece exploring UI physics, financial modeling concepts, and structured Flutter architecture.

---

# 🎯 Problem Statement

Most consumer fintech apps focus on:

- Transaction history  
- Transfers  
- Static balances  

However, they lack:

- Forward-looking runway awareness  
- Portfolio volatility signals  
- Context-aware spending feedback  
- Intent friction for high-risk actions  

VYLT explores how these features can be modeled and implemented in a mobile architecture.

---

# 🏗️ Architecture Overview

VYLT follows a modular layered structure inside `/lib` to separate concerns clearly.

## High-Level Layers

```

Presentation Layer (Screens & UI)
Core Services Layer (Privacy, Storage)
Data Layer (Local DB + Firebase)

```

---

## 📂 Project Structure

```

lib/
├── main.dart
├── app.dart
│
├── core/
│    ├── privacy/
│    │     └── consent_repository.dart
│    ├── storage/
│    │     └── local_database.dart
│
├── home_screen.dart
├── wallet_screen.dart
├── transactions_screen.dart
├── predictions_screen.dart
├── profile_screen.dart
├── onboarding_screen.dart
├── vylt_actions_suite.dart

```

---

## 🧩 Layer Breakdown

### 1️⃣ Presentation Layer

Contains all UI screens:

- `home_screen.dart`  
- `wallet_screen.dart`  
- `transactions_screen.dart`  
- `predictions_screen.dart`  
- `profile_screen.dart`  
- `vylt_actions_suite.dart`  

**Responsibilities:**

- Render financial state  
- Handle UI animations  
- Manage physics-based interactions  
- Trigger domain-level calculations  

---

### 2️⃣ Core Layer

Located in:

```

core/privacy/
core/storage/

```

#### `consent_repository.dart`

Handles:

- GDPR-style user data consent  
- Data provenance checks  
- Feature gating based on privacy settings  

#### `local_database.dart`

Responsible for:

- Local transaction persistence  
- Financial snapshot storage  
- Caching user financial state  

Designed to keep business logic separate from UI rendering.

---

### 3️⃣ Application Entry

- `main.dart` → App bootstrap  
- `app.dart` → Route definitions & global theme  

Handles:

- Auth gate  
- Navigation routing  
- Global theme injection  
- Dark Intelligence design system configuration  

---

# ⚙️ Core Engineering Concepts

## 🧮 Runway Engine (Client-Side Simulation)

Runway is calculated using:

- Current liquidity  
- Rolling average burn rate  
- Recurring transaction detection (simulated)  
- Risk weighting factor  

Projected runway:

```

runway_days = total_liquidity / average_daily_spend

````

Displayed dynamically inside:

- Horizon screen  
- Safe-spend HUD  

---

## 📊 Risk Modeling

System Risk is derived from:

- Asset volatility mock data  
- Allocation ratio  
- Liquidity concentration  

Displayed via:

- Percentage volatility  
- Mood-reactive UI color modulation  

---

## 🎛️ Friction-Based Interaction Design

High-risk financial actions use:

- Long-press confirmation  
- Slider resistance simulation  
- Spring-based animation physics  
- Distinct haptic patterns  

Implemented using:

- Custom animation controllers  
- Physics simulations  
- Gesture detectors  

---

# 🎨 UI & Interaction System

### Dark Intelligence Theme

- Primary: `#000000`  
- Cards: `#1C1C1E`  
- Stable: Blue  
- Volatile: Red  
- Recovery: Green  

Heavy use of:

- Backdrop blur  
- Glassmorphism  
- Animated gradients  
- GPU-accelerated painters  

---

# 🔐 Authentication & Security

- Firebase Authentication (Email/Password)  
- Auth-gated routes  
- No sensitive financial data stored in plaintext  
- Simulated financial data only  

**Future:**

- Biometric authentication  
- Secure storage encryption layer  

---

# 🛠 Tech Stack

### Frontend

- Flutter (Dart)  
- Custom UI Painters  
- Animation Controllers  
- Blended Material + Cupertino  

### Backend Services

- Firebase Core  
- Firebase Authentication  

### Local Storage

- Custom local database abstraction  

---

# 🚀 Running the Project

```bash
git clone <repo>
flutter pub get
flutter run
````

Ensure Firebase config is present:
`firebase_options.dart`

---

# 🔮 Future Improvements

* TrueLayer / Plaid integration
* Secure encrypted storage
* Backend microservice for real runway analytics
* Monte Carlo simulation for predictive modeling
* Riverpod / Bloc integration for stronger state separation

---

## 🧾 License

This project was developed out of personal curiosity, product research, and the pursuit of next-generation UX. It serves as a conceptual portfolio piece. All financial data within the repository is simulated.

---

## 👤 Developer Information

**Name:** Jayanth Dasaroju
**Role:** SDE
**Focus:** Ideation, HCI Research, UX/UI Design, and Flutter Implementation

**Contact:** [u2912341@uel.ac.uk](mailto:jayanthdasroju@gmail.com)

**Portfolio:** [https://www.jays-dev.space/](https://www.jays-dev.space/)

---

## 🙌 Final Note

VYLT is not designed to replicate traditional banking apps. It is designed to **redefine financial clarity, emotional resonance, and action confidence**.

> A shift from *tracking money* → to *understanding and acting viscerally on money*.

```
