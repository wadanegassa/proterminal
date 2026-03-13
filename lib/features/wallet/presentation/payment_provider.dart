import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/payment_service.dart';
// Removed

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier(ref.read(paymentServiceProvider));
});

class PaymentState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final String? checkoutUrl;

  const PaymentState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.checkoutUrl,
  });

  PaymentState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    String? checkoutUrl,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  final PaymentService _service;

  PaymentNotifier(this._service) : super(const PaymentState());

  Future<void> startStripePayment(double amount, String currency) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.makeStripePayment(
        amount: amount,
        currency: currency,
        onPaymentIntentCreated: (secret) {
          // This would be handled inside PaymentService usually
        },
        onPaymentSuccess: () {
          state = state.copyWith(isLoading: false, isSuccess: true);
        },
        onPaymentError: (err) {
          state = state.copyWith(isLoading: false, error: err);
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> startChapaPayment({
    required double amount,
    required String email,
    required String name,
    required String txRef,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final names = name.split(' ');
    final first = names.first;
    final last = names.length > 1 ? names.last : '';

    await _service.initiateChapaPayment(
      amount: amount,
      email: email,
      firstName: first,
      lastName: last,
      txRef: txRef,
      onReady: (url) {
        state = state.copyWith(isLoading: false, checkoutUrl: url);
      },
      onError: (err) {
        state = state.copyWith(isLoading: false, error: err);
      },
    );
  }

  void reset() => state = const PaymentState();
}
