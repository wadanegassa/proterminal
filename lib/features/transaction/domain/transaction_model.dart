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
        'timestamp': Timestamp.fromDate(timestamp),
        'note': note,
      };
}
