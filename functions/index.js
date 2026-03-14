const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

// Atomic Wallet Transfer
exports.processWalletTransfer = functions.https.onCall(async (data, context) => {
  const { receiverId, amount } = data;
  const senderId = context.auth.uid;

  if (!senderId) throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
  if (amount <= 0) throw new functions.https.HttpsError("invalid-argument", "Amount must be positive.");

  return db.runTransaction(async (transaction) => {
    const senderRef = db.collection("users").doc(senderId);
    const receiverRef = db.collection("users").doc(receiverId);

    const senderDoc = await transaction.get(senderRef);
    const receiverDoc = await transaction.get(receiverRef);

    if (!senderDoc.exists) throw new functions.https.HttpsError("not-found", "Sender not found.");
    if (!receiverDoc.exists) throw new functions.https.HttpsError("not-found", "Receiver not found.");

    const senderBalance = senderDoc.data().walletBalance || 0;
    if (senderBalance < amount) {
      throw new functions.https.HttpsError("failed-precondition", "Insufficient balance.");
    }

    // Update balances
    transaction.update(senderRef, { walletBalance: senderBalance - amount });
    transaction.update(receiverRef, { walletBalance: (receiverDoc.data().walletBalance || 0) + amount });

    // Record transaction
    const txRef = db.collection("transactions").doc();
    transaction.set(txRef, {
      senderId: senderId,
      senderName: senderDoc.data().name,
      receiverId: receiverId,
      receiverName: receiverDoc.data().name,
      amount: amount,
      type: "transfer",
      status: "completed",
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, transactionId: txRef.id };
  });
});

// Verify QR Payment
exports.verifyQRPayment = functions.https.onCall(async (data, context) => {
  const { merchantId, amount } = data;
  const userId = context.auth.uid;

  if (!userId) throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");

  return db.runTransaction(async (transaction) => {
    const userRef = db.collection("users").doc(userId);
    const merchantRef = db.collection("merchants").doc(merchantId);

    const userDoc = await transaction.get(userRef);
    const merchantDoc = await transaction.get(merchantRef);

    if (!userDoc.exists) throw new functions.https.HttpsError("not-found", "User not found.");
    if (!merchantDoc.exists) throw new functions.https.HttpsError("not-found", "Merchant not found.");

    const userBalance = userDoc.data().walletBalance || 0;
    if (userBalance < amount) {
      throw new functions.https.HttpsError("failed-precondition", "Insufficient balance.");
    }

    // Update balances (Merchant doesn't have a wallet in the same collection, usually separate logic)
    transaction.update(userRef, { walletBalance: userBalance - amount });

    // Record transaction
    const txRef = db.collection("transactions").doc();
    transaction.set(txRef, {
      senderId: userId,
      senderName: userDoc.data().name,
      receiverId: merchantId,
      receiverName: merchantDoc.data().businessName,
      amount: amount,
      type: "payment",
      status: "completed",
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true };
  });
});

/**
 * Stripe Payment Integration
 * Requires STRIPE_SECRET_KEY in functions config:
 * firebase functions:config:set stripe.secret="sk_test_..."
 */
const stripe = require("stripe")(functions.config().stripe ? functions.config().stripe.secret : "sk_test_placeholder");

exports.createStripePaymentIntent = functions.https.onCall(async (data, context) => {
  const { amount, currency } = data;
  const userId = context.auth ? context.auth.uid : null;

  if (!userId) {
    throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
  }

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: currency || "usd",
      metadata: { userId: userId },
      automatic_payment_methods: { enabled: true },
    });

    return {
      clientSecret: paymentIntent.client_secret,
    };
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});

// Webhook to handle Stripe payment success and update wallet
exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers["stripe-signature"];
  let event;

  try {
    event = stripe.webhooks.constructEvent(
      req.rawBody,
      sig,
      functions.config().stripe ? functions.config().stripe.webhook_secret : "whsec_..."
    );
  } catch (err) {
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  if (event.type === "payment_intent.succeeded") {
    const paymentIntent = event.data.object;
    const userId = paymentIntent.metadata.userId;
    const amount = paymentIntent.amount / 100;

    const userRef = db.collection("users").doc(userId);
    await db.runTransaction(async (t) => {
      const userDoc = await t.get(userRef);
      const currentBalance = userDoc.data().walletBalance || 0;
      t.update(userRef, { walletBalance: currentBalance + amount });

      const txRef = db.collection("transactions").doc();
      t.set(txRef, {
        senderId: "STRIPE",
        senderName: "External Card",
        receiverId: userId,
        receiverName: userDoc.data().name,
        amount: amount,
        type: "topup",
        status: "completed",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
  }

  res.json({ received: true });
});

// Securely Fetch Linked Gateway Balances (Stripe, Chapa, CBE, etc.)
exports.getGatewayBalances = functions.https.onCall(async (data, context) => {
  const userId = context.auth ? context.auth.uid : null;
  if (!userId) {
    throw new functions.https.HttpsError("unauthenticated", "User must be logged in to fetch balances.");
  }

  try {
    const cards = [];

    // 1. Fetch live Stripe Balance
    try {
      const balance = await stripe.balance.retrieve();

      // Calculate total available balance across all Stripe currencies
      let totalAvailable = 0;
      balance.available.forEach((bal) => {
        totalAvailable += (bal.amount / 100); // Convert cents to standard
      });

      cards.push({
        id: `gateway_stripe_${userId}`,
        cardNumber: '**** **** **** 4242', // Ideally fetched from Stripe PaymentMethods/Connect
        cardHolder: 'Live Stripe Balance',
        expiryDate: 'N/A',
        balance: totalAvailable,
        type: 'Stripe Balance',
        gradientIndex: 1,
        platform: 'stripe',
        gatewayId: 'acct_1Stripe',
      });
    } catch (stripeErr) {
      console.error("Stripe balance fetch failed:", stripeErr);
      // Depending on requirements, we might still return other gateway cards 
      // even if Stripe fails. Log and proceed.
    }

    // 2. Mock Chapa / Telebirr / CBE Birr integrations below
    // In production, these would be physical API calls equivalent to stripe.balance.retrieve()

    // Telebirr 
    cards.push({
      id: `gateway_telebirr_${userId}`,
      cardNumber: '+251 911 *** 234',
      cardHolder: 'Verified User',
      expiryDate: 'N/A',
      balance: 12500.00,
      type: 'Telebirr',
      gradientIndex: 2,
      platform: 'telebirr',
      gatewayId: `tb_${userId}`,
    });

    // CBE Birr
    cards.push({
      id: `gateway_cbe_${userId}`,
      cardNumber: '1000 **** **** 8932',
      cardHolder: 'Verified User',
      expiryDate: 'N/A',
      balance: 45200.50,
      type: 'CBE Birr',
      gradientIndex: 3,
      platform: 'cbebirr',
      gatewayId: `cbe_${userId}`,
    });

    // Return the unified array of formatted cards
    return { cards: cards };

  } catch (error) {
    console.error("Gateway fetch error:", error);
    throw new functions.https.HttpsError("internal", "Failed to resolve external gateway balances.");
  }
});
