import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:propay/core/config/constants.dart';
import 'package:propay/core/utils/formatters.dart';
import 'package:propay/features/product/presentation/product_provider.dart';
import 'package:propay/features/product/domain/product_model.dart';
import 'package:propay/features/wallet/presentation/wallet_provider.dart';

class PlatformScreen extends ConsumerWidget {
  const PlatformScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(businessAnalyticsProvider);
    final productsAsync = ref.watch(productsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('PLATFORM ECOSYSTEM', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2, color: isDark ? Colors.white : Colors.black)),
        centerTitle: true,
      ),
      body: analyticsAsync.when(
        data: (analytics) {
          final revenueByPlatform = analytics['revenueByPlatform'] as Map<String, double>? ?? {};
          
          return productsAsync.when(
            data: (products) {
              // Derive platforms dynamically: union of product platforms + analytics platforms
              final platformSet = <String>{
                ...products.map((p) => p.platform),
                ...revenueByPlatform.keys,
              };
              final platforms = platformSet.toList()..sort();

              if (platforms.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.layers_outlined, size: 64, color: isDark ? Colors.white24 : Colors.black12),
                      const SizedBox(height: 16),
                      Text('NO PLATFORMS REGISTERED', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 11, color: isDark ? Colors.white38 : Colors.black26, letterSpacing: 2)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: platforms.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final platform = platforms[index];
                  final revenue = revenueByPlatform[platform] ?? 0.0;
                  final skus = products.where((p) => p.platform == platform).length;
                  
                  return _PlatformCard(
                    name: platform,
                    revenue: revenue,
                    skus: skus,
                    isDark: isDark,
                    onTap: () {
                      ref.read(selectedProductPlatformProvider.notifier).state = platform;
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PlatformInventoryScreen(platform: platform)));
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading products: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading analytics: $e')),
      ),
    );
  }
}

class _PlatformCard extends StatelessWidget {
  final String name;
  final double revenue;
  final int skus;
  final bool isDark;
  final VoidCallback onTap;

  const _PlatformCard({required this.name, required this.revenue, required this.skus, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color platformColor = AppColors.primary;
    if (name == 'ProMarket') platformColor = Colors.amber;
    if (name == 'ProFood') platformColor = Colors.greenAccent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: platformColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.layers_rounded, color: platformColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.inventory_2_rounded, size: 12, color: isDark ? Colors.white54 : Colors.black54),
                      const SizedBox(width: 4),
                      Text('$skus SKUs Active', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.black54)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('REVENUE', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(Formatters.compactCurrency(revenue), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: platformColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PlatformInventoryScreen extends ConsumerWidget {
  final String platform;
  const PlatformInventoryScreen({super.key, required this.platform});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(filteredProductsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('${platform.toUpperCase()} INVENTORY', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2, color: isDark ? Colors.white : Colors.black)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_box_rounded, color: AppColors.primary, size: 28),
            onPressed: () => _showAddProduct(context),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(isDark: isDark, platform: platform),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: isDark ? Colors.white24 : Colors.black12),
                        const SizedBox(height: 16),
                        Text('NO SKUS FOUND FOR MAPPING', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.black26, fontSize: 12, letterSpacing: 2)),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) => _ProductCard(product: products[index], isDark: isDark),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading products: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddProduct(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product Management module active. Syncing with inventory...')),
    );
  }
}

class _SearchBar extends ConsumerWidget {
  final bool isDark;
  final String platform;
  const _SearchBar({required this.isDark, required this.platform});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
          borderRadius: BorderRadius.circular(4),
        ),
        child: TextField(
          onChanged: (v) => ref.read(productSearchProvider.notifier).state = v,
          style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontSize: 13),
          decoration: InputDecoration(
            icon: Icon(Icons.search_rounded, color: isDark ? Colors.white38 : Colors.black26, size: 20),
            hintText: 'SEARCH $platform...',
            hintStyle: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black26, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isDark;
  const _ProductCard({required this.product, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
              child: product.imageUrl != null 
                ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                : Icon(Icons.image_outlined, color: isDark ? Colors.white24 : Colors.black12, size: 40),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(product.category.toUpperCase(), style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(product.platform.toUpperCase(), style: GoogleFonts.inter(fontSize: 6, fontWeight: FontWeight.w900, color: isDark ? Colors.white54 : Colors.black54)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(product.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(Formatters.currency(product.price), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: product.stockQuantity > 5 ? Colors.greenAccent.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text('${product.stockQuantity} IN STOCK', style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.w900, color: product.stockQuantity > 5 ? Colors.greenAccent : AppColors.primary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
