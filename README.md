# ProTerminal - Unified Merchant & Product Intelligence Hub

ProTerminal is a high-performance business operations hub designed to manage multi-platform e-commerce (ProShop, ProMarket) and centralize global merchant intelligence.

## Core Pillars
- **Platform Intelligence**: Cross-platform inventory management for ProShop, ProFood, and beyond.
- **Merchant Wallet**: Secure atomic balance updates and gateway integrations (Stripe, Chapa).
- **ProTerminal Signal**: Real-time revenue monitoring and activity logs for distributed business units.
- **Advanced Analytics**: Granular performance metrics including Category Profitability and AOV per Platform.
- **QR Payment Ecosystem**: Native support for dynamic merchant QR generation and scanning.

## Tech Stack
- **Frontend**: Flutter (Riverpod for state, FL Chart for intelligence visualization).
- **Backend**: Firebase (Firestore, Cloud Functions, Authentication).
- **Styling**: Cyber-Fintech aesthetics with adaptive Dark/Light modes.

## Setup Instructions

### 1. Firebase Configuration
- Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com).
- Enable **Authentication**, **Cloud Firestore**, and **Cloud Functions**.
- Deploy `firestore.rules` and `functions/`.
- Use `flutterfire configure` to generate configuration.

### 2. Payment Gateway Configuration
Set your merchant keys in the Firebase Functions environment:
```bash
firebase functions:config:set stripe.secret="YOUR_STRIPE_SECRET" chapa.secret="YOUR_CHAPA_SECRET"
```

### 3. Execution
```bash
flutter pub get
flutter run
```

## Security & Reliability
- **Atomic Ledgers**: Transactions are processed via Cloud Functions to ensure balance integrity.
- **Security Rules**: Robust Firestore rules prevent unauthorized ledger manipulation.
- **Product Mapping**: Smart attribution of gateway signals (Stripe/Chapa) to specific product ecosystems.
