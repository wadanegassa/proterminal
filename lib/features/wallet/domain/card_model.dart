class CardModel {
  final String id;
  final String cardNumber;
  final String cardHolder;
  final String expiryDate;
  final double balance;
  final String type; // e.g., 'Visa', 'MasterCard', 'Amex'
  final int gradientIndex;
  final bool isDefault;
  final String platform; // 'propay', 'stripe', 'telebirr', 'chapa'
  final String? gatewayId; // ID from external system
  final String walletAddress; // Unique identifier for transfers

  const CardModel({
    required this.id,
    required this.cardNumber,
    required this.cardHolder,
    required this.expiryDate,
    required this.balance,
    required this.type,
    required this.gradientIndex,
    required this.walletAddress,
    this.isDefault = false,
    this.platform = 'propay',
    this.gatewayId,
  });

  factory CardModel.fromMap(Map<String, dynamic> data, String id) {
    // Generate a wallet address if it doesn't exist
    final address = data['walletAddress'] ?? 'PRO-${id.substring(0, 8).toUpperCase()}';
    
    return CardModel(
      id: id,
      cardNumber: data['cardNumber'] ?? '',
      cardHolder: data['cardHolder'] ?? '',
      expiryDate: data['expiryDate'] ?? '',
      balance: (data['balance'] ?? 0.0).toDouble(),
      type: data['type'] ?? 'Visa',
      gradientIndex: data['gradientIndex'] ?? 0,
      walletAddress: address,
      isDefault: data['isDefault'] ?? false,
      platform: data['platform'] ?? 'propay',
      gatewayId: data['gatewayId'],
    );
  }

  Map<String, dynamic> toMap() => {
        'cardNumber': cardNumber,
        'cardHolder': cardHolder,
        'expiryDate': expiryDate,
        'balance': balance,
        'type': type,
        'gradientIndex': gradientIndex,
        'walletAddress': walletAddress,
        'isDefault': isDefault,
        'platform': platform,
        if (gatewayId != null) 'gatewayId': gatewayId,
      };
}
