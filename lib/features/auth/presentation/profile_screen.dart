import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/config/constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cards.dart';
import 'auth_provider.dart';
import '../../wallet/presentation/wallet_provider.dart';
import '../domain/user_model.dart';
import '../../merchant/presentation/merchant_dashboard.dart';
import '../../../core/providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Account', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('No profile data'));
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Premium Avatar Section
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            user.initials,
                            style: GoogleFonts.inter(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(user.name,
                          style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppColors.lightTextPrimary)),
                      const SizedBox(height: 4),
                      Text(user.email,
                          style: GoogleFonts.inter(
                              fontSize: 14, 
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 16),
                      StatusBadge(
                        label: user.role.name.toUpperCase(),
                        color: user.role == UserRole.merchant ? AppColors.secondary : AppColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Quick Info Row
                Row(
                  children: [
                    Expanded(
                      child: _ProfileStat(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Balance',
                        value: Formatters.currency(user.walletBalance),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ProfileStat(
                        icon: Icons.verified_user_rounded,
                        label: 'Safety',
                        value: 'Tier 2',
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Theme Management Section
                SectionHeader(title: 'Appearance'),
                const SizedBox(height: 12),
                ProCard(
                  isGlass: isDark,
                  child: Row(
                    children: [
                      Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, 
                          color: AppColors.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          isDark ? 'Dark Mode Active' : 'Light Mode Active',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: isDark,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) => ref.read(themeModeProvider.notifier).toggleTheme(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Settings & Actions
                SectionHeader(title: 'Settings'),
                const SizedBox(height: 12),
                if (user.role == UserRole.merchant)
                  _SettingsTile(
                    icon: Icons.storefront_rounded,
                    label: 'Merchant Business Portal',
                    isDark: isDark,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MerchantDashboard())),
                  ),
                _SettingsTile(icon: Icons.security_rounded, label: 'Security & Biometrics', isDark: isDark, onTap: () {}),
                _SettingsTile(icon: Icons.notifications_rounded, label: 'Push Notifications', isDark: isDark, onTap: () {}),
                _SettingsTile(icon: Icons.help_rounded, label: 'Support & FAQ', isDark: isDark, onTap: () {}),
                
                const SizedBox(height: 40),
                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _signOut(context, ref),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                      foregroundColor: AppColors.error,
                      elevation: 0,
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
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

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Sign Out', style: GoogleFonts.inter(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).signOut();
    }
  }

  void _edit(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings coming soon!'), behavior: SnackBarBehavior.floating),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _ProfileStat({required this.icon, required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ProCard(
      isGlass: isDark,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 12),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.label, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ProCard(
        onTap: onTap,
        isGlass: isDark,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary)),
            ),
            Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          ],
        ),
      ),
    );
  }
}
