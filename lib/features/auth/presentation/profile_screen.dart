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
import 'package:fl_chart/fl_chart.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userModelProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('SYSTEM PROFILE',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w900, 
              fontSize: 12, 
              letterSpacing: 2,
              color: isDark ? Colors.white : Colors.black,
            )),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter(
            color: isDark ? AppColors.darkGridColor : AppColors.lightGridColor,
          ))),
          userAsync.when(
            data: (user) {
              if (user == null) return const Center(child: Text('DATA CORRUPT'));
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 140),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // ─── Industrial Identity Block ──────────────────────────
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          border: Border.all(color: AppColors.primary, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            user.initials,
                            style: GoogleFonts.inter(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(user.name.toUpperCase(),
                        style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 8),
                    Text(user.email.toUpperCase(),
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                    const SizedBox(height: 24),
                    StatusBadge(
                      label: 'ACCESS LEVEL: ${user.role.name.toUpperCase()}',
                      color: user.role == UserRole.merchant ? AppColors.secondary : AppColors.primary,
                    ),
                    
                    const SizedBox(height: 48),

                    // ─── Identity Parameters ───────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _ProfileStat(
                            icon: Icons.account_balance_wallet_rounded,
                            label: 'LIQUIDITY',
                            value: Formatters.currency(user.walletBalance),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ProfileStat(
                            icon: Icons.verified_user_rounded,
                            label: 'SECURITY',
                            value: 'ENCRYPTED',
                          ),
                        ),
                      ],
                    ),
                    // ─── Sparkline ─────────────────────────────────────────
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 16,
                            top: 0,
                            child: Text('NETWORK ACTIVITY', style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2)),
                          ),
                          Positioned(
                            right: 16,
                            top: 0,
                            child: Row(
                              children: [
                                Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Text('LIVE', style: GoogleFonts.inter(color: AppColors.success, fontSize: 8, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: IgnorePointer(
                              child: LineChart(
                                LineChartData(
                                  gridData: const FlGridData(show: false),
                                  titlesData: const FlTitlesData(show: false),
                                  borderData: FlBorderData(show: false),
                                  minX: 0, maxX: 6, minY: 0, maxY: 10,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: const [
                                        FlSpot(0, 3), FlSpot(1, 4), FlSpot(2, 3.5),
                                        FlSpot(3, 8), FlSpot(4, 5), FlSpot(5, 7),
                                        FlSpot(6, 6),
                                      ],
                                      isCurved: true,
                                      color: AppColors.primary,
                                      barWidth: 2,
                                      isStrokeCapRound: true,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [AppColors.primary.withValues(alpha: 0.3), AppColors.primary.withValues(alpha: 0.0)],
                                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ─── Configuration ─────────────────────────────────────
                    SectionHeader(title: 'SYSTEM CONFIG'),
                    _SettingsTile(
                      icon: Icons.dark_mode_rounded,
                      label: 'HIGH CONTRAST MODE',
                      trailing: Switch.adaptive(
                        value: isDark,
                        activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) => ref.read(themeModeProvider.notifier).toggleTheme(),
                      ),
                    ),
                    const SizedBox(height: 40),

                    SectionHeader(title: 'AUTHORIZED MODULES'),
                    const SizedBox(height: 12),
                    if (user.role == UserRole.merchant)
                      _SettingsTile(
                        icon: Icons.storefront_rounded,
                        label: 'MERCHANT PORTAL',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MerchantDashboard())),
                      ),
                    _SettingsTile(icon: Icons.security_rounded, label: 'ENCRYPTION PROTOCOLS', onTap: () => _mockDialog(context, 'Security modules are operating normally.', isDark)),
                    _SettingsTile(icon: Icons.notifications_rounded, label: 'SIGNAL PREFERENCES', onTap: () => _mockDialog(context, 'Notification signals routed securely via device.', isDark)),
                    _SettingsTile(icon: Icons.help_rounded, label: 'KNOWLEDGE BASE', onTap: () => _mockDialog(context, 'Accessing distributed support documents...', isDark)),
                    
                    const SizedBox(height: 48),
                    // ─── Termination ─────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () => _signOut(context, ref),
                        icon: const Icon(Icons.logout_rounded, size: 20),
                        label: Text('TERMINATE SESSION', 
                            style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary))),
            error: (_, __) => const Center(child: Text('DATA ERROR')),
          ),
        ],
      ),
    );
  }

  void _mockDialog(BuildContext context, String message, bool isDark) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        title: Text('SYSTEM MODULE', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
        content: Text(message, style: GoogleFonts.inter(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ACKNOWLEDGE', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), 
          side: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('TERMINATE SESSION', 
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900, 
                    color: isDark ? Colors.white : Colors.black, 
                    fontSize: 16, 
                    letterSpacing: 1,
                  )),
              const SizedBox(height: 16),
              Text('Are you sure you want to end the current encrypted session?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    height: 1.5, 
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, 
                    fontSize: 12,
                  )),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false), 
                      child: Text('ABORT', style: GoogleFonts.inter(
                        color: isDark ? Colors.white : Colors.black, 
                        fontWeight: FontWeight.w900, 
                        fontSize: 12,
                      ))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GradientButton(
                      label: 'CONFIRM',
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).signOut();
    }
  }

}

class _ProfileStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 16),
          Text(label, 
              style: GoogleFonts.inter(
                  fontSize: 10, 
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, 
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2)),
          const SizedBox(height: 4),
          Text(value, 
              style: GoogleFonts.inter(
                  fontSize: 16, 
                  fontWeight: FontWeight.w900, 
                  color: isDark ? Colors.white : Colors.black)),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({required this.icon, required this.label, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(icon, color: isDark ? Colors.white70 : Colors.black87, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Text(label,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: 0.5)),
              ),
              trailing ?? Icon(Icons.chevron_right_rounded, 
                  color: isDark ? Colors.white12 : Colors.black12,
                  size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    const step = 40.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
