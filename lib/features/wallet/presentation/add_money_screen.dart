import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/constants.dart';
import '../../../core/widgets/cards.dart';
import 'payment_provider.dart';
import 'wallet_provider.dart';

class AddMoneyScreen extends ConsumerWidget {
  const AddMoneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(paymentProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppColors.error),
        );
      }
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Successful!'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
      if (next.checkoutUrl != null) {
        _launchUrl(next.checkoutUrl!);
      }
    });

    final paymentState = ref.watch(paymentProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Top Up Wallet', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: 'Payment Methods'),
                const SizedBox(height: 12),
                _MethodCard(
                  title: 'Credit / Debit Card',
                  subtitle: 'International Payments via Stripe',
                  label: 'Cards / Apple Pay',
                  icon: Icons.credit_card_rounded,
                  gradient: AppColors.primaryGradient,
                  isDark: isDark,
                  onTap: () => _showAmountSheet(context, ref, 'Stripe'),
                ),
                const SizedBox(height: 16),
                _MethodCard(
                  title: 'Local Transfers',
                  subtitle: 'Payments via Chapa Gateway',
                  label: 'CBE / Telebirr',
                  icon: Icons.account_balance_rounded,
                  gradient: AppColors.secondaryGradient,
                  isDark: isDark,
                  onTap: () => _showAmountSheet(context, ref, 'Chapa'),
                ),
                const SizedBox(height: 16),
                _MethodCard(
                  title: 'Bank Wire',
                  subtitle: 'Direct deposit to bank',
                  label: '1-3 Business Days',
                  icon: Icons.home_work_rounded,
                  gradient: AppColors.sunsetGradient,
                  isDark: isDark,
                  onTap: () => _showAmountSheet(context, ref, 'Bank Transfer'),
                ),
                
                const SizedBox(height: 40),
                ProCard(
                  isGlass: isDark,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Secure Transaction', 
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800, 
                                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                  fontSize: 15)),
                            const SizedBox(height: 2),
                            Text('Encrypted through bank-grade security protocols.', 
                                style: GoogleFonts.inter(
                                  fontSize: 12, 
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (paymentState.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary))),
            ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  void _showAmountSheet(BuildContext context, WidgetRef ref, String method) {
    final amountCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 48),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                        borderRadius: BorderRadius.circular(4))),
              ),
              const SizedBox(height: 32),
              Text('Top Up Amount',
                  style: GoogleFonts.inter(
                      fontSize: 22, 
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary)),
              const SizedBox(height: 8),
              Text('How much would you like to add via $method?',
                  style: GoogleFonts.inter(
                      fontSize: 14, 
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              const SizedBox(height: 40),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 48, 
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary),
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefix: Text('\$ ',
                      style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['50', '100', '250', '500'].map((v) {
                  return GestureDetector(
                    onTap: () => amountCtrl.text = v,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text('\$$v',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.primary)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 48),
              GradientButton(
                label: 'Confirm Deposit',
                icon: Icons.bolt_rounded,
                onPressed: () async {
                  final amount = double.tryParse(amountCtrl.text);
                  if (amount == null || amount <= 0) return;

                  Navigator.pop(context);

                  if (method == 'Stripe') {
                    await ref.read(paymentProvider.notifier).startStripePayment(amount, 'USD');
                  } else if (method == 'Chapa') {
                    final user = ref.read(userModelProvider).value;
                    if (user == null) return;
                    await ref.read(paymentProvider.notifier).startChapaPayment(
                      amount: amount,
                      email: user.email,
                      name: user.name,
                      txRef: 'propay-${DateTime.now().millisecondsSinceEpoch}',
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final String title, subtitle, label;
  final IconData icon;
  final LinearGradient gradient;
  final bool isDark;
  final VoidCallback onTap;

  const _MethodCard({
    required this.title,
    required this.subtitle,
    required this.label,
    required this.icon,
    required this.gradient,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ProCard(
      onTap: onTap,
      isGlass: isDark,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.last.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 12, 
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                const SizedBox(height: 6),
                StatusBadge(label: label, color: isDark ? AppColors.primary : AppColors.primary),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
        ],
      ),
    );
  }
}
