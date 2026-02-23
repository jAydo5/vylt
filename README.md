# 💳 VYLT

## A Financial Intelligence & Liquidity Management Ecosystem

VYLT is a Flutter-based fintech application that reimagines how individuals understand, manage, and emotionally interact with money. Instead of functioning as a passive financial ledger, VYLT prioritises **financial clarity, cognitive reassurance, predictive awareness, and intent-based control** throughout the user's financial lifecycle.
The project is built as an engineering-focused portfolio piece exploring UI physics, financial modeling concepts, and structured Flutter architecture.

---

## 📌 Problem Statement

Most existing personal finance and banking applications (e.g., Revolut, Monzo, YNAB, Mint) primarily focus on:

- Transaction tracking  
- Balance monitoring  
- Budget categorisation  
- Static financial snapshots  

However, they fail to address the **psychological and cognitive challenges** users face when managing money, particularly:

- Anxiety around financial uncertainty  
- Poor awareness of future liquidity risk  
- Lack of forward-looking insight  
- Cognitive overload from raw data  
- No friction for high-risk financial actions  

Public feedback and behavioural research indicate that users struggle not with **spending mechanics**, but with **financial understanding and confidence**.

VYLT addresses these issues by shifting from a *transaction-centric* model to a **financial intelligence ecosystem**.

---

## 💡 Solution Overview

VYLT introduces a **Smart Financial Awareness Ecosystem** that supports users across four key dimensions:

1. **Awareness** – Real-time financial state clarity  
2. **Prediction** – Runway forecasting and future liquidity insight  
3. **Risk Intelligence** – Visual financial risk modelling  
4. **Action Confidence** – Friction-based financial interactions  

The application is designed as a **UX-first simulation**, demonstrating advanced interaction design, emotional feedback loops, and predictive financial modelling concepts.

---

## ✨ Core Features

### 📊 Financial Dashboard & Liquidity Overview

- Real-time balance visualisation  
- Liquid asset breakdown  
- Dynamic financial health indicators  
- Mood-reactive UI feedback  

---

### 🧮 Runway Forecasting Engine

- Predicts how long a user can sustain current spending  
- Simulates financial sustainability  
- Dynamic time-based liquidity modelling  
- Visual runway countdown system  

---

### ⚠️ Risk Intelligence Module

- Portfolio volatility simulation  
- Liquidity concentration analysis  
- Visual risk signalling  
- Emotional UI modulation based on financial stability  

---

### 🎛️ Friction-Based Financial Actions

- Long-press confirmations  
- Resistance sliders for high-value transfers  
- Spring-based interaction physics  
- Distinct haptic patterns  

Designed to **prevent impulsive financial behaviour** and encourage deliberate action.

---

### 👤 Profile & Financial Identity Layer

- Personal financial preferences  
- Risk tolerance simulation  
- Feature gating through consent  
- Privacy-centric personalisation  

---

## 🧠 Design & HCI Principles Applied

- **Visibility of System Status** – Continuous financial clarity  
- **Feedback** – Visual, haptic, and motion-based confirmation  
- **Error Prevention** – Intent friction and action constraints  
- **Recognition Over Recall** – Data-driven insights, not raw numbers  
- **Cognitive Load Reduction** – Progressive information disclosure  
- **GDPR-Conscious UX** – Minimal data collection, consent-driven features  

---

## 🎨 VYLT UI Style Guide (Brief)

This style guide defines the core visual and interaction standards used across the VYLT application, ensuring **design consistency, usability, and emotional engagement**.

---

### 1. Colour Tokens

VYLT adopts a **dark intelligence theme**, reinforcing clarity, focus, and emotional neutrality during financial decision-making.

- **Primary Background:** `#000000`  
- **Surface / Cards:** `#1C1C1E`  
- **Stable Financial State:** Blue  
- **High Volatility / Risk:** Red  
- **Recovery / Positive Trajectory:** Green  
- **Primary Accent:** Subtle gradient overlays  

Colour modulation dynamically adapts to **financial risk levels**.

---

### 2. Typography Hierarchy

Typography prioritises **clarity, hierarchy, and emotional neutrality**.

- **Headings:** *Playfair Display*  
  - Used for financial summaries and dashboard emphasis  
- **Body & UI Text:** *Inter*  
  - Optimised for high-density numeric data and readability  

---

### 3. Button States & Interaction Feedback

- **Primary Actions:** Gradient surfaces with motion feedback  
- **Secondary Actions:** Subtle surface outlines  
- **Destructive Actions:** Red accent + friction confirmation  
- **Disabled State:** Muted contrast  

Haptic feedback and spring-based animations reinforce **financial intent awareness**.

---

### 4. Reusable UI Components

- Financial metric cards  
- Volatility indicators  
- Runway timeline widgets  
- Action friction sliders  
- Smart notification banners  

---

## 🔐 Authentication & Privacy Architecture

- Firebase Authentication (Email/Password)  
- Auth-gated navigation  
- No plaintext financial storage  
- Consent-driven feature gating  

> Note: VYLT avoids persistent local storage of sensitive personal data to reinforce **GDPR-first interaction design**.

---

## 🛠️ Tech Stack

### Frontend

- Flutter (Dart)  
- Material + Cupertino Hybrid  
- Custom UI Painters  
- Flutter Animate  
- Google Fonts  

### Backend / Services

- Firebase Core  
- Firebase Authentication  

### Local Storage

- Custom privacy-first local database abstraction  

---

## 📁 Project Structure

```

lib/
│── main.dart
│── app.dart
│
│── core/
│   ├── privacy/
│   │   └── consent_repository.dart
│   ├── storage/
│   │   └── local_database.dart
│
│── home_screen.dart
│── wallet_screen.dart
│── transactions_screen.dart
│── predictions_screen.dart
│── profile_screen.dart
│── onboarding_screen.dart
│── vylt_actions_suite.dart
│
│── firebase_options.dart

````

---

## 🚀 How to Run the Project

1. Clone the repository  
2. Install dependencies:

   ```bash
   flutter pub get
````

3. Ensure Firebase is configured (`firebase_options.dart`)
4. Run the app:

   ```bash
   flutter run
   ```
````
The focus is placed on:

* UX-driven financial problem solving
* Human-centered fintech design
* Predictive system modelling
* Privacy-first architecture
* Reflective engineering practice

---

## 🔮 Future Improvements

* Secure encrypted local storage
* Biometric authentication
* Monte Carlo financial forecasting
* Backend microservices for real analytics
* AI-powered spending behaviour modelling
* Open banking integration (TrueLayer / Plaid)

---

## 🧾 License

This project was developed out of personal curiosity, product research, and the pursuit of next-generation UX. 
It serves as a conceptual portfolio piece. All financial data within the repository is simulated.

---

## 👤 Developer Information

**Name:** Jayanth Dasaroju
**Student ID:** 2912341
**Course:** MSc Software Engineering
**Module:** Mobile and Web Application Development
**Institution:** University of East London
**Academic Year:** 2025–2026

**Project Role:**
Sole developer responsible for ideation, HCI research, UX/UI design, system architecture, Flutter implementation, and evaluation.

**Contact:** [u2912341@uel.ac.uk](mailto:jayanthdasroju@gmail.com)
**Portfolio:** [https://www.jays-dev.space/](https://www.jays-dev.space/)

---

## 🙌 Final Note

VYLT is not designed to replace traditional finance apps —
it is designed to **redefine how people emotionally understand and act on money**.

This repository represents:

> A shift from *tracking money* → to *feeling and forecasting financial reality*.


