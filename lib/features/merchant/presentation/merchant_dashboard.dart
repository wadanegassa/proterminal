import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/config/constants.dart';
import '../../wallet/presentation/wallet_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cards.dart';

class MerchantDashboard extends ConsumerWidget {
  const MerchantDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userModelProvider);
    final txAsync = ref.watch(allTransactionsProvider);
    final currentUid = ref.watch(authStateProvider).valueOrNull?.uid ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Merchant Portal', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Profile not found'));
          
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Premium Earnings Card
                PremiumWalletCard(
                  balance: Formatters.currency(user.walletBalance),
                  cardNum: "MERCHANT ID: ${currentUid.substring(0, 8).toUpperCase()}",
                  expDate: "SALES BOX",
                  holderName: user.businessName.toUpperCase(),
                  gradient: AppColors.secondaryGradient,
                ),
                const SizedBox(height: 32),
                
                // Dashboard Stats
                Row(
                  children: [
                    Expanded(
                      child: _DashboardMiniStat(
                        label: 'Gross Volume',
                        value: '\$4,240.50',
                        icon: Icons.payments_rounded,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _DashboardMiniStat(
                        label: 'Total Orders',
                        value: '128',
                        icon: Icons.shopping_bag_rounded,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Quick Actions
                SectionHeader(title: 'Management'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    QuickActionBtn(
                      icon: Icons.qr_code_2_rounded,
                      label: 'My QR',
                      gradient: AppColors.primaryGradient,
                      onTap: () => _showMyQR(context, currentUid),
                    ),
                    QuickActionBtn(
                      icon: Icons.analytics_rounded,
                      label: 'Analytics',
                      gradient: AppColors.sunsetGradient,
                      onTap: () {},
                    ),
                    QuickActionBtn(
                      icon: Icons.campaign_rounded,
                      label: 'Payouts',
                      gradient: AppColors.accentGradient,
                      onTap: () {},
                    ),
                    QuickActionBtn(
                      icon: Icons.tune_rounded,
                      label: 'Setup',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Recent Sales
                SectionHeader(
                  title: 'Recent Sales',
                  actionLabel: 'Details',
                  onAction: () {},
                ),
                const SizedBox(height: 12),
                txAsync.when(
                  data: (txList) {
                    final sales = txList.where((tx) => tx.receiverId == currentUid).toList();
                    if (sales.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text('No recent sales found.',
                              style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sales.length,
                      itemBuilder: (context, index) {
                        final tx = sales[index];
                        return TransactionTile(
                          name: tx.senderName ?? 'Customer',
                          subtitle: Formatters.relativeTime(tx.timestamp),
                          amount: tx.amount,
                          isSent: false,
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Center(child: Text('Error loading sales', style: GoogleFonts.inter(color: AppColors.error))),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading profile')),
      ),
    );
  }

  void _showMyQR(BuildContext context, String merchantId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 32),
            Text('Business QR',
                style: GoogleFonts.inter(
                    fontSize: 22, 
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary)),
            const SizedBox(height: 8),
            Text('Scan this to pay the merchant instantly',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
            const SizedBox(height: 40),
            
            // Premium QR Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: const Icon(Icons.qr_code_2_rounded, size: 200, color: Colors.black),
            ),
            
            const SizedBox(height: 40),
            GradientButton(
              label: 'Share Business ID',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;

  const _DashboardMiniStat({required this.label, required this.value, required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ProCard(
      isGlass: isDark,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.secondary, size: 18),
          ),
          const SizedBox(height: 16),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
        ],
      ),
    );
  }
}
