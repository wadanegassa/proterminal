import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../domain/card_model.dart';
import '../../../core/config/payment_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../transaction/domain/transaction_model.dart';

final gatewayServiceProvider = Provider<GatewayService>((ref) {
  return GatewayService();
});

/// A service to interact with external payment gateways (Stripe, Chapa/Telebirr, etc.)
class GatewayService {
  
  /// Stream of linked external accounts as CardModels fetched via direct HTTP Auth
  Stream<List<CardModel>> getLinkedGateways(String uid) async* {
    while (true) {
      try {
        final List<CardModel> liveCards = [];

        // 1. Fetch live Stripe Balance directly via HTTP
        try {
          final stripeRes = await http.get(
            Uri.parse('https://api.stripe.com/v1/balance'),
            headers: {
              'Authorization': 'Bearer ${PaymentConfig.stripeSecretKey}',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
          );

          if (stripeRes.statusCode == 200) {
            final data = json.decode(stripeRes.body);
            double totalAvailable = 0;
            
            if (data['available'] != null) {
              for (var bal in data['available']) {
                totalAvailable += (bal['amount'] / 100); 
              }
            }

            liveCards.add(CardModel(
              id: 'gateway_stripe_$uid',
              walletAddress: 'stripe_$uid',
              cardNumber: 'GATEWAY-****-STRIPE', 
              cardHolder: 'Live Stripe Balance',
              expiryDate: 'N/A',
              balance: totalAvailable,
              type: 'Stripe Balance',
              gradientIndex: 1,
              platform: 'stripe',
              gatewayId: 'acct_1Stripe',
              currency: 'USD',
            ));
          }
        } catch (e) {
          debugPrint("Stripe fetch failed: $e");
        }

        // 2. Fetch Chapa Transactions to calculate balance (since /v1/balances might be 0 in sandbox)
        try {
          final chapaRes = await http.get(
            Uri.parse('https://api.chapa.co/v1/transactions'),
            headers: {
              'Authorization': 'Bearer ${PaymentConfig.chapaSecretKey}',
            },
          );
          
          if (chapaRes.statusCode == 200) {
            final data = json.decode(chapaRes.body);
            final chapaData = data['data'];
            List? transactions;
            
            if (chapaData is List) {
              transactions = chapaData;
            } else if (chapaData is Map && chapaData['transactions'] is List) {
              transactions = chapaData['transactions'];
            }

            double totalBalance = 0;
            if (transactions != null) {
              for (var item in transactions) {
                if (item['status'] == 'success') {
                  totalBalance += double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
                }
              }
            }

            liveCards.add(CardModel(
              id: 'gateway_chapa_$uid',
              walletAddress: 'chapa_$uid',
              cardNumber: 'GATEWAY-****-CHAPA',
              cardHolder: 'Chapa Revenue Balance',
              expiryDate: 'N/A',
              balance: totalBalance,
              type: 'Chapa Wallet',
              gradientIndex: 2,
              platform: 'chapa',
              gatewayId: 'chapa_main',
              currency: 'ETB',
            ));
          } else {
            debugPrint("Chapa TX fetch for balance failed: ${chapaRes.statusCode}");
          }
        } catch (e) {
          debugPrint("Chapa TX fetch for balance failed: $e");
        }

        yield liveCards;
      } catch (e) {
        debugPrint("Error fetching real gateway balances: $e");
        yield [];
      }
      
      await Future.delayed(const Duration(seconds: 45));
    }
  }

  /// Fetches real transaction history from external gateways
  Stream<List<TransactionModel>> getExternalTransactions({int limit = 50}) async* {
    while (true) {
      final List<TransactionModel> txs = [];
      
      // 1. Fetch Stripe Transactions
      try {
        final res = await http.get(
          Uri.parse('https://api.stripe.com/v1/balance_transactions?limit=$limit'),
          headers: {'Authorization': 'Bearer ${PaymentConfig.stripeSecretKey}'},
        );
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          for (var item in data['data']) {
            txs.add(TransactionModel(
              id: item['id'],
              senderId: 'Stripe',
              receiverId: 'Merchant',
              amount: (item['amount'] / 100).toDouble(),
              timestamp: DateTime.fromMillisecondsSinceEpoch(item['created'] * 1000),
              type: TransactionType.transfer,
              status: TransactionStatus.completed,
              platform: 'Stripe',
              isRevenue: true,
              note: 'Stripe: ${item['description'] ?? "No description"}',
            ));
          }
        }
      } catch (e) {
        debugPrint("Stripe TX fetch failed: $e");
      }

      // 2. Fetch Chapa Transactions
      try {
        final res = await http.get(
          Uri.parse('https://api.chapa.co/v1/transactions'),
          headers: {'Authorization': 'Bearer ${PaymentConfig.chapaSecretKey}'},
        );
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          final chapaData = data['data'];
          List? transactions;
          
          if (chapaData is List) {
            transactions = chapaData;
          } else if (chapaData is Map && chapaData['transactions'] is List) {
            transactions = chapaData['transactions'];
          }

          if (transactions != null) {
            for (var item in transactions) {
              txs.add(TransactionModel(
                id: item['tx_ref'] ?? item['id'] ?? 'chapa_${DateTime.now().millisecondsSinceEpoch}',
                senderId: item['first_name'] ?? 'Chapa User',
                receiverId: 'Merchant',
                amount: double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0,
                timestamp: DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now(),
                type: TransactionType.transfer,
                status: item['status'] == 'success' ? TransactionStatus.completed : TransactionStatus.failed,
                platform: 'Chapa',
                isRevenue: item['status'] == 'success',
                note: 'Chapa: ${item['reason'] ?? "Payment"}',
              ));
            }
          }
        } else {
          debugPrint("Chapa TX fetch failed: ${res.statusCode} - ${res.body}");
        }
      } catch (e) {
        debugPrint("Chapa TX fetch failed: $e");
      }

      yield txs;
      await Future.delayed(const Duration(seconds: 60));
    }
  }

  /// Executes a real fund transfer through the respective gateway
  Future<bool> executeGatewayTransfer({
    required CardModel source,
    required String destination,
    required double amount,
    String? note,
  }) async {
    try {
      if (source.platform == 'stripe') {
        // Stripe Payout / Transfer Implementation
        final res = await http.post(
          Uri.parse('https://api.stripe.com/v1/payouts'),
          headers: {
            'Authorization': 'Bearer ${PaymentConfig.stripeSecretKey}',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'amount': (amount * 100).toInt().toString(), // Cents
            'currency': PaymentConfig.currency.toLowerCase(),
          },
        );
        return res.statusCode == 200;
      } else if (source.platform == 'chapa') {
        // Chapa Transfer Implementation
        final res = await http.post(
          Uri.parse('https://api.chapa.co/v1/transfers'),
          headers: {
            'Authorization': 'Bearer ${PaymentConfig.chapaSecretKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'amount': amount,
            'currency': PaymentConfig.localCurrency,
            'account_number': destination,
            'reference': 'transfer_${DateTime.now().millisecondsSinceEpoch}',
          }),
        );
        return res.statusCode == 200;
      }
      return false;
    } catch (e) {
      debugPrint("Gateway transfer failed: $e");
      return false;
    }
  }
}

