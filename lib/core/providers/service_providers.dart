import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/firebase_service.dart';
import '../../features/qr_payment/data/qr_service.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

final qrServiceProvider = Provider<QRService>((ref) {
  return QRService();
});
