const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

// Atomic Wallet Transfer
exports.processWalletTransfer = functions.https.onCall(async (data, context) => {
  const {receiverId, amount} = data;
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
    transaction.update(senderRef, {walletBalance: senderBalance - amount});
    transaction.update(receiverRef, {walletBalance: (receiverDoc.data().walletBalance || 0) + amount});

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

    return {success: true, transactionId: txRef.id};
  });
});

// Verify QR Payment
exports.verifyQRPayment = functions.https.onCall(async (data, context) => {
  const {merchantId, amount} = data;
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
    transaction.update(userRef, {walletBalance: userBalance - amount});

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

    return {success: true};
  });
});
