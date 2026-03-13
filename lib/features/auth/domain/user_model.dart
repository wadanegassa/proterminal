// Removed unused import

enum UserRole { standard, merchant }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final double walletBalance;
  final UserRole role;
  final String businessName;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.walletBalance,
    required this.role,
    this.businessName = '',
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      walletBalance: ((data['walletBalance'] ?? 0) as num).toDouble(),
      role: (data['role'] as String?) == 'merchant'
          ? UserRole.merchant
          : UserRole.standard,
      businessName: (data['businessName'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'walletBalance': walletBalance,
        'role': role.name,
        'businessName': businessName,
      };

  String get initials {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
