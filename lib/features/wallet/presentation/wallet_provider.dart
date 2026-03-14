import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/firebase_service.dart';
import '../../auth/domain/user_model.dart';
import '../../transaction/domain/transaction_model.dart';
import '../../auth/presentation/auth_provider.dart';
import '../domain/card_model.dart';
import '../../../core/providers/service_providers.dart';

import '../data/gateway_service.dart';

// Stream of cards stored in Firebase (ProPay cards)
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
      if (source != null && source.platform != 'propay') {
        // Execute real external gateway transfer
        final ok = await _gatewayService.executeGatewayTransfer(
          source: source,
          destination: receiverId,
          amount: amount,
        );
        if (!ok) throw Exception('Gateway transfer failed');
      } else {
        // Internal ProPay transfer
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

// Statistics calculator
final walletStatisticsProvider = Provider<AsyncValue<Map<String, double>>>((ref) {
  final transactionsAsync = ref.watch(allTransactionsProvider);
  final authAsync = ref.watch(authStateProvider);
  final user = authAsync.valueOrNull;

  return transactionsAsync.when(
    data: (transactions) {
      double income = 0;
      double expense = 0;
      for (var tx in transactions) {
        // If the current user is the sender, it's an expense.
        // If not (e.g., from a gateway where receiverId is 'Merchant' or similar), it's income.
        if (tx.senderId == user?.uid) {
          expense += tx.amount;
        } else {
          income += tx.amount;
        }
      }
      return AsyncValue.data({
        'income': income,
        'expense': expense,
      });
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});
