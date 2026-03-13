import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/firebase_service.dart';
import '../../auth/domain/user_model.dart';
import '../../transaction/domain/transaction_model.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../core/providers/service_providers.dart';

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

// Combined transaction list
final allTransactionsProvider = Provider<AsyncValue<List<TransactionModel>>>((ref) {
  final sent = ref.watch(sentTransactionsProvider);
  final received = ref.watch(receivedTransactionsProvider);

  return sent.when(
    data: (sentList) {
      return received.when(
        data: (receivedList) {
          final combined = [...sentList, ...receivedList];
          combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return AsyncValue.data(combined.take(30).toList());
        },
        loading: () => const AsyncValue.loading(),
        error: (e, s) => AsyncValue.error(e, s),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

// Wallet operation notifier
final walletProvider =
    StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier(ref.watch(firebaseServiceProvider));
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
  WalletNotifier(this._service) : super(const WalletState());

  Future<bool> transfer(String receiverId, double amount) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await _service.transferFunds(receiverId, amount);
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
