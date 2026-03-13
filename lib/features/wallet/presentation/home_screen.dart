import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/config/constants.dart';
import '../../auth/presentation/auth_provider.dart';
import 'wallet_provider.dart';
import '../../auth/domain/user_model.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/utils/formatters.dart';
import 'send_money_screen.dart';
import 'add_money_screen.dart';
import '../../qr_payment/presentation/qr_scanner_screen.dart';
import '../../transaction/presentation/statistic_screen.dart';
import '../../auth/presentation/profile_screen.dart';
import '../../merchant/presentation/merchant_dashboard.dart';
import '../../../core/providers/theme_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _HomeTab(),
    const AddMoneyScreen(),
    const QRScannerScreen(),
    const StatisticScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _pages),
          _buildFloatingBottomNav(isDark),
        ],
      ),
    );
  }

  Widget _buildFloatingBottomNav(bool isDark) {
    return Positioned(
      bottom: 24,
      left: 20,
      right: 20,
      child: GlassContainer(
        borderRadius: 28,
        blur: 20,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        color: isDark 
            ? Colors.white.withValues(alpha: 0.08) 
            : Colors.white.withValues(alpha: 0.8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home_rounded, 0, isDark),
            _navItem(Icons.account_balance_wallet_rounded, 1, isDark),
            _navItem(Icons.qr_code_scanner_rounded, 2, isDark, isCenter: true),
            _navItem(Icons.analytics_rounded, 3, isDark),
            _navItem(Icons.person_rounded, 4, isDark),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index, bool isDark, {bool isCenter = false}) {
    final isSelected = _currentIndex == index;
    
    if (isCenter) {
      return GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 26),
        ),
      );
    }

    return IconButton(
      onPressed: () => setState(() => _currentIndex = index),
      icon: Icon(
        icon,
        color: isSelected 
            ? AppColors.primary 
            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        size: 26,
      ),
    );
  }
}

class _HomeTab extends ConsumerStatefulWidget {
  const _HomeTab();

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userModelProvider);
    final txAsync = ref.watch(allTransactionsProvider);
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.uid ?? '';
    final user = userAsync.valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Hello,',
                        style: GoogleFonts.inter(
                            fontSize: 14, 
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            fontWeight: FontWeight.w500)),
                    Text(
                      user?.name.split(' ').first ?? 'Friend',
                      style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Theme Toggle
                    IconButton(
                      onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
                      icon: Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: isDark ? Colors.amber : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _HeaderAction(icon: Icons.notifications_none_rounded, isDark: isDark),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userModelProvider);
          ref.invalidate(allTransactionsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium Wallet Card (Stacked effect placeholder)
              PremiumWalletCard(
                balance: Formatters.currency(user?.walletBalance ?? 0),
                cardNum: "4560 1234 5678 2585",
                expDate: "08/26",
                holderName: user?.name.toUpperCase() ?? "PRO USER",
                gradient: AppColors.primaryGradient,
              ),
              const SizedBox(height: 32),
              
              // Quick Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  QuickActionBtn(
                    icon: Icons.send_rounded,
                    label: 'Send',
                    gradient: AppColors.secondaryGradient,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SendMoneyScreen())),
                  ),
                  QuickActionBtn(
                    icon: Icons.add_rounded,
                    label: 'TopUp',
                    gradient: AppColors.accentGradient,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMoneyScreen())),
                  ),
                  QuickActionBtn(
                    icon: Icons.history_rounded,
                    label: 'History',
                    gradient: AppColors.sunsetGradient,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticScreen())),
                  ),
                  QuickActionBtn(
                    icon: Icons.grid_view_rounded,
                    label: 'More',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Merchant Dashboard (Adaptive)
              if (user?.role == UserRole.merchant) ...[
                ProCard(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MerchantDashboard())),
                  gradient: isDark ? AppColors.darkGradient : null,
                  isGlass: isDark,
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Merchant Portal', 
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800, 
                                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                  fontSize: 16)),
                            const SizedBox(height: 2),
                            Text('Manage business and payouts', 
                                style: GoogleFonts.inter(
                                  fontSize: 12, 
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, 
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, 
                          size: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Transactions Section
              SectionHeader(
                title: 'Transactions',
                actionLabel: 'See All',
                onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticScreen())),
              ),
              const SizedBox(height: 8),
              _buildTransactionsList(txAsync, currentUserId, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList(AsyncValue txAsync, String currentUserId, bool isDark) {
    return txAsync.when(
      data: (txList) {
        if (txList.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text('No recent activity.', 
                  style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: txList.length > 5 ? 5 : txList.length,
          itemBuilder: (context, index) {
            final tx = txList[index];
            final isSent = tx.senderId == currentUserId;
            final other = isSent ? (tx.receiverName ?? 'Unknown') : (tx.senderName ?? 'Unknown');
            return TransactionTile(
              name: other,
              subtitle: Formatters.relativeTime(tx.timestamp),
              amount: tx.amount,
              isSent: isSent,
            );
          },
        );
      },
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(),
      )),
      error: (_, __) => Center(child: Text('Error loading transactions', 
          style: GoogleFonts.inter(color: AppColors.error))),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  const _HeaderAction({required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 16,
      blur: 10,
      padding: const EdgeInsets.all(10),
      child: Icon(icon, color: isDark ? Colors.white : AppColors.lightTextPrimary, size: 22),
    );
  }
}
