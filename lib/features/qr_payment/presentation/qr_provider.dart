import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/qr_service.dart';
import '../../../core/network/firebase_service.dart';
import '../../merchant/domain/merchant_model.dart';
import '../../../core/providers/service_providers.dart';

final qrProvider = StateNotifierProvider<QRNotifier, QRState>((ref) {
  return QRNotifier(
    ref.read(qrServiceProvider),
    ref.read(firebaseServiceProvider),
  );
});

class QRState {
  final bool isScanning;
  final MerchantModel? detectedMerchant;
  final double? amount;
  final String? error;

  const QRState({
    this.isScanning = false,
    this.detectedMerchant,
    this.amount,
    this.error,
  });

  QRState copyWith({
    bool? isScanning,
    MerchantModel? detectedMerchant,
    double? amount,
    String? error,
  }) =>
      QRState(
        isScanning: isScanning ?? this.isScanning,
        detectedMerchant: detectedMerchant ?? this.detectedMerchant,
        amount: amount ?? this.amount,
        error: error ?? this.error,
      );

  QRState reset() => const QRState();
}

class QRNotifier extends StateNotifier<QRState> {
  final QRService _qrService;
  final FirebaseService _firebaseService;

  QRNotifier(this._qrService, this._firebaseService)
      : super(const QRState());

  Future<void> processCode(String code) async {
    state = state.copyWith(isScanning: true, error: null);
    final params = _qrService.parseQRCode(code);
    if (params == null) {
      state =
          state.copyWith(isScanning: false, error: 'Invalid QR code format');
      return;
    }

    final merchantId = params['merchantId'];
    if (merchantId == null) {
      state = state.copyWith(isScanning: false, error: 'Missing merchant ID');
      return;
    }

    final merchant = await _firebaseService.getMerchantById(merchantId);
    if (merchant == null) {
      state = state.copyWith(
          isScanning: false, error: 'Merchant not registered with ProPay');
      return;
    }

    final amountStr = params['amount'];
    state = state.copyWith(
      isScanning: false,
      detectedMerchant: merchant,
      amount: amountStr != null ? double.tryParse(amountStr) : null,
    );
  }

  String generateStaticQR(String merchantId) =>
      _qrService.generateStaticQR(merchantId);

  String generateDynamicQR(
          String merchantId, double amount, String merchantName) =>
      _qrService.generateDynamicQR(merchantId, amount, merchantName);

  void reset() => state = state.reset();
}
