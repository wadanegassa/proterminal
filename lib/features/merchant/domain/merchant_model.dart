class MerchantModel {
  final String id;
  final String name;
  final String businessName;
  final String qrCodeData;
  final String? logoUrl;

  MerchantModel({
    required this.id,
    required this.name,
    required this.businessName,
    required this.qrCodeData,
    this.logoUrl,
  });

  factory MerchantModel.fromMap(Map<String, dynamic> data, String documentId) {
    return MerchantModel(
      id: documentId,
      name: data['name'] ?? '',
      businessName: data['businessName'] ?? '',
      qrCodeData: data['qrCodeData'] ?? '',
      logoUrl: data['logoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'businessName': businessName,
      'qrCodeData': qrCodeData,
      'logoUrl': logoUrl,
    };
  }
}
