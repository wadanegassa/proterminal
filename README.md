# ProTerminal &mdash; Cyber-Industrial Financial Intelligence Hub

ProTerminal is a high-performance business operations ecosystem designed for the modern digital merchant. It centralizes multi-platform e-commerce streams into a unified, high-fidelity intelligence dashboard with a focus on atomic data integrity and premium industrial aesthetics.

## 🚀 Core Intelligence Pillars

### 1. Dynamic Currency Synchronization
- **Global Toggle**: Seamlessly switch between **USD** and **ETB** across every screen.
- **Real-time Conversion**: Integrated 1:155 exchange rate logic with instant UI updates for balances, transaction history, and analytic projections.

### 2. Advanced Business Analytics (Intelligence Signals)
- **Revenue Performance**: Real-time Gross Volume, Net Volume, and Refund tracking.
- **Growth Metrics**: Dynamic Month-over-Month (MoM) revenue growth and Average LTV (Lifetime Value) calculations.
- **Visual Intelligence**: 
  - **Transaction Velocity**: Hourly throughput charts.
  - **Revenue Heatmaps**: 30-day activity density visualization.
  - **Distribution Maps**: Regional and Platform-specific revenue partitioning (ProShop, ProDev, ProMarket).

### 3. Multi-Gateway Wallet & Vault
- **Consolidated Ledgers**: Unified view of real-time balances from **Stripe** (USD) and **Chapa** (ETB).
- **Stark Card Presentation**: Industrial-grade UI for managing digital assets and gateway credentials.

### 4. Merchant POS & Ecosystem
- **Native QR Support**: Instant merchant QR generation for Point-of-Sale (POS) interactions.
- **Inventory Health**: Real-time monitoring of SKU status, low-stock alerts, and platform mapping.

## 🛠 Tech Stack

- **Frontend**: Flutter (3.9+) with **Riverpod** for reactive state management.
- **Visualization**: `fl_chart` for granular intelligence rendering.
- **Backend**: Firebase Architecture.
  - **Firestore**: Distributed real-time database.
  - **Cloud Functions**: Atomic ledger processing for transaction integrity.
  - **Auth**: Secure merchant identity management.
- **Design System**: High-contrast "Cyber-Stark" aesthetic using **Glassmorphism** and industrial grid-based layouts.

## 🏗 Setup & Deployment

### 1. Intelligence Backend
- Initialize a Firebase project.
- Enable Auth, Firestore, and Functions.
- Deploy security protocols: `firebase deploy --only firestore:rules,functions`.

### 2. Gateway Environment
Configure your encrypted merchant keys:
```bash
firebase functions:config:set stripe.secret="SK_..." chapa.secret="CH_..."
```

### 3. Execution
```bash
flutter pub get
flutter run
```

## 🔒 Security & Reliability
- **Atomic Operations**: All financial mutations are handled via Cloud Functions to prevent race conditions or ledger drift.
- **Encrypted Sessions**: High-security session management with biometric integration support.
- **Smart Attribution**: Automatic mapping of disparate gateway signals to specific internal product categories.

---
*Built for the next generation of global merchants.*
ProTerminal — Cyber-Industrial Financial Intelligence Hub
ProTerminal is a high-performance business operations ecosystem designed for the modern digital merchant. It centralizes multi-platform e-commerce streams into a unified, high-fidelity intelligence dashboard with a focus on atomic data integrity and premium industrial aesthetics.

🚀 Core Intelligence Pillars
1. Dynamic Currency Synchronization
Global Toggle: Seamlessly switch between USD and ETB across every screen.
Real-time Conversion: Integrated 1:155 exchange rate logic with instant UI updates for balances, transaction history, and analytic projections.
2. Advanced Business Analytics (Intelligence Signals)
Revenue Performance: Real-time Gross Volume, Net Volume, and Refund tracking.
Growth Metrics: Dynamic Month-over-Month (MoM) revenue growth and Average LTV (Lifetime Value) calculations.
Visual Intelligence:
Transaction Velocity: Hourly throughput charts.
Revenue Heatmaps: 30-day activity density visualization.
Distribution Maps: Regional and Platform-specific revenue partitioning (ProShop, ProDev, ProMarket).
3. Multi-Gateway Wallet & Vault
Consolidated Ledgers: Unified view of real-time balances from Stripe (USD) and Chapa (ETB).
Stark Card Presentation: Industrial-grade UI for managing digital assets and gateway credentials.
4. Merchant POS & Ecosystem
Native QR Support: Instant merchant QR generation for Point-of-Sale (POS) interactions.
Inventory Health: Real-time monitoring of SKU status, low-stock alerts, and platform mapping.
🛠 Tech Stack
Frontend: Flutter (3.9+) with Riverpod for reactive state management.
Visualization: fl_chart for granular intelligence rendering.
Backend: Firebase Architecture.
Firestore: Distributed real-time database.
Cloud Functions: Atomic ledger processing for transaction integrity.
Auth: Secure merchant identity management.
Design System: High-contrast "Cyber-Stark" aesthetic using Glassmorphism and industrial grid-based layouts.
🏗 Setup & Deployment
1. Intelligence Backend
Initialize a Firebase project.
Enable Auth, Firestore, and Functions.
Deploy security protocols: firebase deploy --only firestore:rules,functions.
2. Gateway Environment
Configure your encrypted merchant keys:

firebase functions:config:set stripe.secret="SK_..." chapa.secret="CH_..."
3. Execution
flutter pub get
flutter run
🔒 Security & Reliability
Atomic Operations: All financial mutations are handled via Cloud Functions to prevent race conditions or ledger drift.
Encrypted Sessions: High-security session management with biometric integration support.
Smart Attribution: Automatic mapping of disparate gateway signals to specific internal product categories.
