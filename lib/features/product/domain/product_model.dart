import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String category;
  final double price;
  final String? description;
  final String? imageUrl;
  final int stockQuantity;
  final String platform; // e.g. 'ProShop', 'ProMarket'
  final DateTime createdAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.description,
    this.imageUrl,
    this.stockQuantity = 0,
    this.platform = 'ProShop',
    required this.createdAt,
  });

  factory ProductModel.fromMap(Map<String, dynamic> data, String id) {
    return ProductModel(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? 'General',
      price: (data['price'] ?? 0).toDouble(),
      description: data['description'],
      imageUrl: data['imageUrl'],
      stockQuantity: data['stockQuantity'] ?? 0,
      platform: data['platform'] ?? 'ProShop',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'price': price,
    'description': description,
    'imageUrl': imageUrl,
    'stockQuantity': stockQuantity,
    'platform': platform,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
