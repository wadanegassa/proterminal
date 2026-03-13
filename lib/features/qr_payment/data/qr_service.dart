// Removed unused import

class QRService {
  // Structure for Dynamic QR: propay:payment?merchantId=...&amount=...&merchantName=...
  // Structure for Static QR: propay:merchant?merchantId=...
  
  static const String scheme = 'propay';

  Map<String, String>? parseQRCode(String code) {
    try {
      if (!code.startsWith('$scheme:')) return null;
      
      final Uri uri = Uri.parse(code);
      return uri.queryParameters;
    } catch (e) {
      return null;
    }
  }

  String generateStaticQR(String merchantId) {
    return '$scheme:merchant?merchantId=$merchantId';
  }

  String generateDynamicQR(String merchantId, double amount, String merchantName) {
    return '$scheme:payment?merchantId=$merchantId&amount=$amount&merchantName=$merchantName';
  }

  bool isValidQR(String code) {
    return code.startsWith('$scheme:');
  }
}
