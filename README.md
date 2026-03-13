# ProPay - Production-Ready Flutter Fintech App

ProPay is a modern digital wallet and QR payment system built with Flutter and Firebase.

## Features
- **Secure Wallet**: Atomic balance updates via Firebase Functions.
- **P2P Transfers**: Send money to other users securely.
- **QR Payments**: Scan merchant QR codes (static/dynamic) for instant payments.
- **Payment Gateway**: Integrated with Stripe and Chapa.
- **Modern UI**: Sleek fintech design with glassmorphism and smooth gradients.
- **Real-time**: Live balance and transaction history updates using Riverpod and Firestore Streams.

## Setup Instructions

### 1. Firebase Configuration
- Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com).
- Enable **Authentication** (Email/Password).
- Enable **Cloud Firestore** and deploy `firestore.rules`.
- Enable **Cloud Functions** (Requires Blaze Plan).
- Use `flutterfire configure` to generate `lib/firebase_options.dart`.

### 2. Backend Deployment (Functions)
```bash
cd functions
npm install
firebase deploy --only functions
```

### 3. Payment Keys
Set your Stripe and Chapa keys in the Firebase Functions configuration:
```bash
firebase functions:config:set stripe.secret="YOUR_STRIPE_SECRET" chapa.secret="YOUR_CHAPA_SECRET"
```

### 4. Running the App
```bash
flutter pub get
flutter run
```

## Project Structure
- `lib/models`: Data models with Firestore serialization.
- `lib/providers`: State management using Riverpod.
- `lib/services`: Communication with Firebase and Payments.
- `lib/screens`: All UI screens (Home, Login, Send Money, etc.).
- `lib/widgets`: Reusable premium UI components.
- `functions/index.js`: Core backend logic for secure transactions.

## Security
- **Atomic Operations**: All wallet transfers and payments use Firestore transactions within Cloud Functions to prevent race conditions and data corruption.
- **Security Rules**: Firestore rules prevent direct balance manipulation from the client side.
