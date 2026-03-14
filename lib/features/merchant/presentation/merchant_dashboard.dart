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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('MERCHANT PORTAL', 
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w900, 
              fontSize: 16, 
              letterSpacing: 2,
              color: isDark ? Colors.white : Colors.black,
            )),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Profile not found'));
          
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Premium Earnings Card
                PremiumWalletCard(
                  balance: Formatters.currency(user.walletBalance),
                  cardNum: "MERCHANT: ${currentUid.substring(0, 10).toUpperCase()}",
                  expDate: "ACTIVE",
                  holderName: user.businessName.toUpperCase(),
                  gradient: AppColors.secondaryGradient,
                ),
                const SizedBox(height: 40),
                
                txAsync.when(
                  data: (txList) {
                    final sales = txList.where((tx) => tx.receiverId == currentUid).toList();
                    final grossVolume = sales.fold(0.0, (sum, tx) => sum + tx.amount);
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _DashboardMiniStat(
                                label: 'Gross Volume',
                                value: Formatters.currency(grossVolume),
                                icon: Icons.payments_rounded,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _DashboardMiniStat(
                                label: 'Sales Count',
                                value: sales.length.toString(),
                                icon: Icons.analytics_rounded,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),

                        // Management Actions
                        SectionHeader(title: 'Quick Management'),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            QuickActionBtn(
                              icon: Icons.qr_code_scanner_rounded,
                              label: 'Business QR',
                              gradient: AppColors.primaryGradient,
                              onTap: () => _showMyQR(context, currentUid),
                            ),
                            QuickActionBtn(
                              icon: Icons.insights_rounded,
                              label: 'Audience',
                              gradient: AppColors.secondaryGradient,
                              onTap: () {},
                            ),
                            QuickActionBtn(
                              icon: Icons.account_balance_wallet_rounded,
                              label: 'Withdraw',
                              gradient: AppColors.accentGradient,
                              onTap: () {},
                            ),
                            QuickActionBtn(
                              icon: Icons.settings_suggest_rounded,
                              label: 'Store',
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),

                        // Recent Sales
                        SectionHeader(
                          title: 'Latest Sales',
                          actionLabel: 'View All',
                          onAction: () {},
                        ),
                        const SizedBox(height: 12),
                        if (sales.isEmpty)
                          ProCard(
                            isGlass: isDark,
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.receipt_long_rounded, 
                                      color: isDark ? Colors.white10 : AppColors.lightDivider, size: 48),
                                  const SizedBox(height: 16),
                                  Text('No sales record found.',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3))),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: sales.length > 5 ? 5 : sales.length,
                            itemBuilder: (context, index) {
                              final tx = sales[index];
                              return TransactionTile(
                                name: tx.senderName ?? 'Customer',
                                subtitle: Formatters.relativeTime(tx.timestamp),
                                amount: tx.amount,
                                isSent: false,
                              );
                            },
                          ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary))),
                  error: (_, __) => Center(child: Text('Could not fetch sales', style: GoogleFonts.inter(color: AppColors.error))),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary))),
        error: (_, __) => const Center(child: Text('Error loading business profile')),
      ),
    );
  }

  void _showMyQR(BuildContext context, String merchantId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 60),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 48),
            Text('Point of Sale QR',
                style: GoogleFonts.inter(
                    fontSize: 26, 
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.5)),
            const SizedBox(height: 12),
            Text('Customers scan this to pay your business instantly.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
            const SizedBox(height: 48),
            
            // Premium QR Presentation
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_2_rounded, size: 220, color: Colors.black),
                  const SizedBox(height: 20),
                  Text('MERCHANT ID: ${merchantId.substring(0, 12).toUpperCase()}',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 12, 
                          fontWeight: FontWeight.w800, 
                          color: Colors.black26)),
                ],
              ),
            ),
            
            const SizedBox(height: 56),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: GradientButton(
                label: 'Download Payment Kit',
                icon: Icons.download_rounded,
                onPressed: () => Navigator.pop(context),
              ),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.secondary, size: 20),
          ),
          const SizedBox(height: 20),
          Text(label, 
              style: GoogleFonts.inter(
                fontSize: 13, 
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary, 
                fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(value, 
              style: GoogleFonts.inter(
                fontSize: 22, 
                fontWeight: FontWeight.w900, 
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                letterSpacing: -1)),
        ],
      ),
    );
  }
}
