import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:propay/features/product/domain/product_model.dart';

final productsProvider = StreamProvider<List<ProductModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('products')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList());
});

final productSearchProvider = StateProvider<String>((ref) => '');
final selectedProductPlatformProvider = StateProvider<String?>((ref) => null);

final filteredProductsProvider = Provider<AsyncValue<List<ProductModel>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final searchQuery = ref.watch(productSearchProvider).toLowerCase();
  final selectedPlatform = ref.watch(selectedProductPlatformProvider);

  return productsAsync.whenData((products) {
    return products.where((p) {
      final matchesSearch = searchQuery.isEmpty || 
          p.name.toLowerCase().contains(searchQuery) || 
          p.category.toLowerCase().contains(searchQuery);
      
      final matchesPlatform = selectedPlatform == null || p.platform == selectedPlatform;
      
      return matchesSearch && matchesPlatform;
    }).toList();
  });
});
