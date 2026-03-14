import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
// Removed unused import
import 'package:propay/features/auth/domain/user_model.dart';
import 'package:propay/features/transaction/domain/transaction_model.dart';
import 'package:propay/features/merchant/domain/merchant_model.dart';
import 'package:propay/features/wallet/domain/card_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // ── User ─────────────────────────────────────────────────────────────────
  Stream<UserModel?> getUserData(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (snap.exists && snap.data() != null) {
        return UserModel.fromMap(snap.data()!, snap.id);
      }
      return null;
    });
  }

  Future<void> createUserProfile(
    String uid, String name, String email, String phone,
  ) async {
    await _db.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'phone': phone,
      'walletBalance': 0.0,
      'role': 'standard',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<UserModel?> getUserByPhone(String phone) async {
    final snap = await _db
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      return UserModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
    }
    return null;
  }

  // ── Transactions ──────────────────────────────────────────────────────────
  Stream<List<TransactionModel>> getTransactionHistory(String uid) {
    // Get transactions where user is sender OR receiver (merged client-side)
    return _db
        .collection('transactions')
        .where('senderId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TransactionModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<TransactionModel>> getReceivedTransactions(String uid) {
    return _db
        .collection('transactions')
        .where('receiverId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TransactionModel.fromMap(d.data(), d.id))
            .toList());
  }

  // ── Cloud Functions ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> transferFunds(
      String receiverId, double amount) async {
    final result = await _functions
        .httpsCallable('processWalletTransfer')
        .call({'receiverId': receiverId, 'amount': amount});
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> payViaQR(
      String merchantId, double amount) async {
    final result = await _functions
        .httpsCallable('verifyQRPayment')
        .call({'merchantId': merchantId, 'amount': amount});
    return Map<String, dynamic>.from(result.data as Map);
  }

  // ── Merchants ─────────────────────────────────────────────────────────────
  Future<MerchantModel?> getMerchantById(String merchantId) async {
    final snap = await _db.collection('merchants').doc(merchantId).get();
    if (snap.exists && snap.data() != null) {
      return MerchantModel.fromMap(snap.data()!, snap.id);
    }
    return null;
  }

  Stream<List<MerchantModel>> getMerchants() {
    return _db.collection('merchants').snapshots().map((snap) =>
        snap.docs.map((d) => MerchantModel.fromMap(d.data(), d.id)).toList());
  }

  // ── Cards ─────────────────────────────────────────────────────────────────
  Stream<List<CardModel>> getCards(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('cards')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CardModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> addCard(String uid, CardModel card) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('cards')
        .add(card.toMap());
  }

  Future<void> deleteCard(String uid, String cardId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('cards')
        .doc(cardId)
        .delete();
  }

  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    
    // Search by name (starts with) or phone
    final nameSnap = await _db
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(5)
        .get();
        
    final phoneSnap = await _db
        .collection('users')
        .where('phone', isEqualTo: query)
        .limit(1)
        .get();

    final users = nameSnap.docs
        .map((d) => UserModel.fromMap(d.data(), d.id))
        .toList();
        
    for (var d in phoneSnap.docs) {
      final user = UserModel.fromMap(d.data(), d.id);
      if (!users.any((u) => u.uid == user.uid)) {
        users.add(user);
      }
    }
    
    return users;
  }
}
