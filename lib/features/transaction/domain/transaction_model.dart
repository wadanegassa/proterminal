import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { transfer, payment, deposit, withdrawal }

enum TransactionStatus { pending, completed, failed }

class TransactionModel {
  final String id;
  final String senderId;
  final String? senderName;
  final String receiverId;
  final String? receiverName;
  final double amount;
  final TransactionType type;
  final TransactionStatus status;
  final String? platform; // e.g., 'ProShop', 'ProDev', 'Office', 'Stripe', 'Chapa'
  final String? productId; 
  final bool isRevenue;
  final DateTime timestamp;
  final String? note;

  const TransactionModel({
    required this.id,
    required this.senderId,
    this.senderName,
    required this.receiverId,
    this.receiverName,
    required this.amount,
    required this.type,
    required this.status,
    this.platform,
    this.productId,
    this.isRevenue = true,
    required this.timestamp,
    this.note,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> data, String id) {
    TransactionType parseType(String? s) {
      switch (s) {
        case 'payment':
          return TransactionType.payment;
        case 'deposit':
          return TransactionType.deposit;
        case 'withdrawal':
          return TransactionType.withdrawal;
        default:
          return TransactionType.transfer;
      }
    }

    TransactionStatus parseStatus(String? s) {
      switch (s) {
        case 'completed':
          return TransactionStatus.completed;
        case 'failed':
          return TransactionStatus.failed;
        default:
          return TransactionStatus.pending;
      }
    }

    return TransactionModel(
      id: id,
      senderId: (data['senderId'] as String?) ?? '',
      senderName: data['senderName'] as String?,
      receiverId: (data['receiverId'] as String?) ?? '',
      receiverName: data['receiverName'] as String?,
      amount: ((data['amount'] ?? 0) as num).toDouble(),
      type: parseType(data['type'] as String?),
      status: parseStatus(data['status'] as String?),
      platform: data['platform'] as String?,
      productId: data['productId'] as String?,
      isRevenue: data['isRevenue'] as bool? ?? true,
      timestamp:
          (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'senderName': senderName,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'amount': amount,
        'type': type.name,
        'status': status.name,
        'platform': platform,
        'productId': productId,
        'isRevenue': isRevenue,
        'timestamp': Timestamp.fromDate(timestamp),
        'note': note,
      };

  /// For the business owner: Income is when money is received via a platform or system.
  bool get isIncome => isRevenue && (receiverId == 'Merchant' || receiverId.isNotEmpty);

  /// Generates a CSV row for this transaction
  String toCsvRow() => [
        id,
        timestamp.toIso8601String(),
        senderName ?? senderId,
        receiverName ?? receiverId,
        amount.toString(),
        platform ?? 'Main',
        type.name,
        status.name,
        note ?? '',
      ].map((e) => '"$e"').join(',');
}
