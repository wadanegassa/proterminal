import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/firebase_service.dart';
import '../../auth/domain/user_model.dart';
import '../../transaction/domain/transaction_model.dart';
import '../../auth/presentation/auth_provider.dart';
import '../domain/card_model.dart';
import '../../../core/providers/service_providers.dart';

import '../data/gateway_service.dart';
import '../../product/presentation/product_provider.dart';

// Stream of cards stored in Firebase (ProTerminal cards)
final internalCardsProvider = StreamProvider<List<CardModel>>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final user = authAsync.valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(firebaseServiceProvider).getCards(user.uid);
});

// Stream of external integrated cards (Stripe, Telebirr, etc.)
final gatewayCardsProvider = StreamProvider<List<CardModel>>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final user = authAsync.valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(gatewayServiceProvider).getLinkedGateways(user.uid);
});

// Combined Stream of ALL cards (Exclusively Gateways now)
final userCardsProvider = Provider<AsyncValue<List<CardModel>>>((ref) {
  final gateway = ref.watch(gatewayCardsProvider);

  if (gateway.isLoading && gateway.valueOrNull == null) {
    return const AsyncValue.loading();
  }

  if (gateway.hasError) {
    return AsyncValue.error(gateway.error!, gateway.stackTrace!);
  }

  return AsyncValue.data(gateway.valueOrNull ?? []);
});

// Real-time user model stream
final userModelProvider = StreamProvider<UserModel?>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final user = authAsync.valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(firebaseServiceProvider).getUserData(user.uid);
});

// Real-time sent transactions
final sentTransactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final user = authAsync.valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(firebaseServiceProvider).getTransactionHistory(user.uid);
});

// Real-time received transactions
final receivedTransactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final user = authAsync.valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(firebaseServiceProvider).getReceivedTransactions(user.uid);
});
// Real-time external transactions (Stripe, etc.)
final externalTransactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final user = authAsync.valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(gatewayServiceProvider).getExternalTransactions();
});

// Combined transaction list
final allTransactionsProvider = Provider<AsyncValue<List<TransactionModel>>>((ref) {
  final sent = ref.watch(sentTransactionsProvider);
  final received = ref.watch(receivedTransactionsProvider);
  final external = ref.watch(externalTransactionsProvider);

  if (sent.isLoading || received.isLoading) {
    return const AsyncValue.loading();
  }

  final List<TransactionModel> combined = [
    ...(sent.valueOrNull ?? []),
    ...(received.valueOrNull ?? []),
    ...(external.valueOrNull ?? []),
  ];

  combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return AsyncValue.data(combined.take(30).toList());
});

// Wallet operation notifier
final walletProvider =
    StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier(
    ref.watch(firebaseServiceProvider),
    ref.watch(gatewayServiceProvider),
  );
});

class WalletState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const WalletState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  WalletState copyWith({bool? isLoading, String? error, bool? isSuccess}) =>
      WalletState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isSuccess: isSuccess ?? this.isSuccess,
      );

  WalletState reset() => const WalletState();
}

class WalletNotifier extends StateNotifier<WalletState> {
  final FirebaseService _service;
  final GatewayService _gatewayService;
  WalletNotifier(this._service, this._gatewayService) : super(const WalletState());

  Future<bool> transfer(String receiverId, double amount, {CardModel? source}) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      if (source != null && source.platform != 'proterminal') {
        // Execute real external gateway transfer
        final ok = await _gatewayService.executeGatewayTransfer(
          source: source,
          destination: receiverId,
          amount: amount,
        );
        if (!ok) throw Exception('Gateway transfer failed');
      } else {
        // Internal ProTerminal transfer
        await _service.transferFunds(receiverId, amount);
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: _formatError(e.toString()));
      return false;
    }
  }

  Future<bool> payQR(String merchantId, double amount) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await _service.payViaQR(merchantId, amount);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: _formatError(e.toString()));
      return false;
    }
  }

  void reset() => state = state.reset();

  String _formatError(String raw) {
    if (raw.contains('Insufficient balance')) return 'Insufficient balance.';
    if (raw.contains('not-found')) return 'User not found.';
    return 'Operation failed. Please try again.';
  }
}
final homeScreenIndexProvider = StateProvider<int>((ref) => 0);

// Comprehensive Business Intelligence Engine
final businessAnalyticsProvider = Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final transactionsAsync = ref.watch(allTransactionsProvider);
  
  return transactionsAsync.when(
    data: (transactions) {
      // 1. Core Revenue & Trends
      final Map<String, int> transactionsByPlatform = {};
      final Map<String, double> revenueByPlatform = {};
      final Map<String, double> monthlyTrends = {};
      double totalNet = 0;
      double totalRefunds = 0;
      final Set<String> activeRecipientIds = {};
      final Map<String, int> userTransactionCount = {};
      
      final now = DateTime.now();
      
      for (var tx in transactions) {
        if (tx.isIncome) {
          final actualPlatform = tx.platform ?? 'Other';
          // Map Stripe and Chapa to ProShop for e-commerce reporting
          final displayPlatform = (actualPlatform == 'Stripe' || actualPlatform == 'Chapa') 
              ? 'ProShop' 
              : actualPlatform;
          
          final amount = tx.amount;
          
          revenueByPlatform[displayPlatform] = (revenueByPlatform[displayPlatform] ?? 0) + amount;
          transactionsByPlatform[displayPlatform] = (transactionsByPlatform[displayPlatform] ?? 0) + 1;
          totalNet += amount;
          
          userTransactionCount[tx.senderId] = (userTransactionCount[tx.senderId] ?? 0) + 1;

          final txMonth = '${tx.timestamp.year}-${tx.timestamp.month.toString().padLeft(2, '0')}';
          final monthsAgo = (now.year - tx.timestamp.year) * 12 + (now.month - tx.timestamp.month);
          if (monthsAgo >= 0 && monthsAgo < 6) {
            monthlyTrends[txMonth] = (monthlyTrends[txMonth] ?? 0) + amount;
          }
        } else if (tx.type == TransactionType.payment) {
          totalRefunds += tx.amount;
        }
        
        activeRecipientIds.add(tx.receiverId);
      }
      
      // 2. Derive Retention & Churn
      final totalUsers = userTransactionCount.length;
      final retainedUsers = userTransactionCount.values.where((count) => count > 1).length;
      final retentionRate = totalUsers > 0 ? retainedUsers / totalUsers : 0.0;
      final churnRate = 1.0 - retentionRate;
      final avgLTV = totalUsers > 0 ? totalNet / totalUsers : 0.0;

      // 3. Regional Distribution (Dynamic based on platform)
      final Map<String, double> regions = {
        'North America': 0, 'East Africa': 0, 'Europe': 0, 'MENA': 0
      };
      for (var tx in transactions) {
        if (!tx.isIncome) continue;
        if (tx.platform == 'Stripe') {
          regions['North America'] = (regions['North America'] ?? 0) + tx.amount;
        } else if (tx.platform == 'Chapa') {
          regions['East Africa'] = (regions['East Africa'] ?? 0) + tx.amount;
        } else if (tx.platform == 'ProShop') {
          regions['East Africa'] = (regions['East Africa'] ?? 0) + tx.amount;
        } else {
          regions['MENA'] = (regions['MENA'] ?? 0) + tx.amount;
        }
      }

      // 4. Aggregate Real Balances from Gateways
      final cardsAsync = ref.watch(userCardsProvider);
      double totalManagedBalance = 0;
      final Map<String, double> platformBalances = {};
      
      cardsAsync.whenData((cards) {
        for (var card in cards) {
          totalManagedBalance += card.balance;
          platformBalances[card.platform.toUpperCase()] = (platformBalances[card.platform.toUpperCase()] ?? 0) + card.balance;
        }
      });

      final productsAsync = ref.watch(productsProvider);
      final Map<String, double> productRevenue = {};
      final Map<String, double> categoryRevenue = {};
      
      productsAsync.whenData((products) {
        final productMap = {for (var p in products) p.id: p};
        for (var tx in transactions) {
          if (!tx.isIncome || tx.productId == null) continue;
          final product = productMap[tx.productId];
          if (product != null) {
            // Group key including platform for distinct tracking
            final platformKey = '${product.platform}: ${product.name}';
            productRevenue[platformKey] = (productRevenue[platformKey] ?? 0) + tx.amount;
            categoryRevenue[product.category] = (categoryRevenue[product.category] ?? 0) + tx.amount;
          }
        }
      });

      // 5. Advanced Metrics
      final txVelocity = transactions.length / 24; 
      final activeTerminals = activeRecipientIds.length;

      final Map<String, double> aovByPlatform = {};
      transactionsByPlatform.forEach((platform, count) {
        aovByPlatform[platform] = count > 0 ? revenueByPlatform[platform]! / count : 0.0;
      });

      return AsyncValue.data({
        'revenueByPlatform': revenueByPlatform,
        'aovByPlatform': aovByPlatform,
        'monthlyTrends': monthlyTrends,
        'totalNet': totalNet,
        'totalRefunds': totalRefunds,
        'avgLTV': avgLTV,
        'churnRate': churnRate,
        'regionalDistribution': regions,
        'retentionRate': retentionRate,
        'totalManagedBalance': totalManagedBalance,
        'platformBalances': platformBalances,
        'transactionVelocity': txVelocity,
        'activeTerminals': activeTerminals,
        'productRevenue': productRevenue,
        'categoryRevenue': categoryRevenue,
      });
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

// Deprecated: walletStatisticsProvider (replaced by businessAnalyticsProvider)
final walletStatisticsProvider = Provider<AsyncValue<Map<String, double>>>((ref) {
  final analytics = ref.watch(businessAnalyticsProvider);
  return analytics.when(
    data: (data) => AsyncValue.data({
      'income': data['totalNet'] as double,
      'expense': 0.0, // Expenses handled differently in Admin view
    }),
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});
