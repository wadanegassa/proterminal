import 'package:flutter/material.dart';
import '../../features/transaction/domain/transaction_model.dart';
import 'formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/wallet/presentation/currency_provider.dart';

class ReceiptUtils {
  static void shareReceipt(BuildContext context, TransactionModel tx) {
    // In a real app, this might use 'share_plus' to share a PDF or Image.
    // For now, we'll show a "Receipt Presentation" dialog.
    final prefCurrency = ProviderScope.containerOf(context).read(displayCurrencyProvider);
    final convertedAmount = CurrencyConverter.convert(
      amount: tx.amount,
      from: tx.platform?.toLowerCase() == 'chapa' ? 'ETB' : 'USD',
      to: prefCurrency,
    );
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF6366F1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.receipt_long_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Transaction Receipt',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _receiptRow('Status', tx.status.name.toUpperCase(), isSuccess: tx.status == TransactionStatus.completed),
                  const Divider(height: 32),
                  _receiptRow('Amount', Formatters.currency(convertedAmount, symbol: CurrencyConverter.getSymbol(prefCurrency)), isBold: true),
                  _receiptRow('Date', Formatters.dateTime(tx.timestamp)),
                  _receiptRow('Transaction ID', tx.id.substring(0, 12).toUpperCase()),
                  const Divider(height: 32),
                  _receiptRow('From', tx.senderName ?? 'Sender'),
                  _receiptRow('To', tx.receiverName ?? 'Receiver'),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share PDF Receipt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _receiptRow(String label, String value, {bool isBold = false, bool isSuccess = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isSuccess ? Colors.green : Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
