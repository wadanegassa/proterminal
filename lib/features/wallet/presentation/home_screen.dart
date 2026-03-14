import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:propay/core/config/constants.dart';
import 'package:propay/features/wallet/presentation/wallet_provider.dart';
import 'package:propay/core/widgets/cards.dart';
import 'package:propay/core/utils/formatters.dart';
import 'package:propay/features/wallet/presentation/send_money_screen.dart';
import 'package:propay/features/transaction/presentation/statistic_screen.dart';
import 'package:propay/features/qr_payment/presentation/qr_scanner_screen.dart';
import 'package:propay/features/auth/presentation/profile_screen.dart';
import 'package:propay/features/wallet/presentation/widgets/stacked_card_carousel.dart';
import 'package:propay/features/wallet/presentation/all_cards_screen.dart';
import 'package:propay/features/wallet/presentation/user_qr_screen.dart';
import 'package:propay/features/transaction/domain/transaction_model.dart';
import 'package:propay/features/auth/domain/user_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<Widget> _pages = [
    const _HomeTab(),
    const UserQrScreen(),
    const QRScannerScreen(),
    const StatisticScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(homeScreenIndexProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Grid
          Positioned.fill(child: CustomPaint(painter: _GridPainter(
            color: isDark ? AppColors.darkGridColor : AppColors.lightGridColor,
          ))),
          IndexedStack(index: currentIndex, children: _pages),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => ref.read(homeScreenIndexProvider.notifier).state = index,
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: isDark ? Colors.white38 : Colors.black26,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_2_rounded), label: 'My QR'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Status'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userModelProvider);
    final cardsAsync = ref.watch(userCardsProvider);
    final user = userAsync.valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      drawer: _buildDrawer(context, user, isDark),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _HeaderAction(icon: Icons.sort_rounded, isDark: isDark, onTap: () => _scaffoldKey.currentState?.openDrawer()),
                Row(
                  children: [
                    _HeaderAction(icon: Icons.notifications_none_rounded, isDark: isDark, onTap: () => _showNotifications(context, isDark)),
                    const SizedBox(width: 12),
                    _HeaderAction(icon: Icons.help_outline_rounded, isDark: isDark, onTap: () {
                      // Placeholder for help/info
                    }),
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
          ref.invalidate(userCardsProvider);
          ref.invalidate(allTransactionsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello ${user?.name.split(' ').first ?? 'User'}!',
                style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                "Your premium cards overview.",
                style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 52), // Increased for carousel overlap

              // Stacked Wallet Card Carousel
              cardsAsync.when(
                data: (cards) {
                  return StackedCardCarousel(
                    cards: cards,
                    onCardChanged: (card) {},
                  );
                },
                loading: () => const AspectRatio(aspectRatio: 1.6, child: Center(child: CircularProgressIndicator())),
                error: (e, s) => const Text('Error loading cards'),
              ),
              
              const SizedBox(height: 48),
              
              // Quick Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  QuickActionBtn(
                    icon: Icons.north_east_rounded,
                    label: 'Send',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SendMoneyScreen())),
                  ),
                  QuickActionBtn(
                    icon: Icons.credit_card_rounded,
                    label: 'Cards',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllCardsScreen())), 
                  ),
                  QuickActionBtn(
                    icon: Icons.qr_code_2_rounded,
                    label: 'Code',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Recent Activity Section
              SectionHeader(
                title: 'Recent Activity',
                actionLabel: 'View All',
                onAction: () => ref.read(homeScreenIndexProvider.notifier).state = 3, // Analytics tab
              ),
              const SizedBox(height: 16),
              ref.watch(allTransactionsProvider).when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'No transactions yet.',
                          style: GoogleFonts.inter(
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length > 5 ? 5 : transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      return TransactionTile(
                        name: tx.senderId == user?.uid ? tx.receiverId : tx.senderId,
                        subtitle: Formatters.date(tx.timestamp),
                        amount: tx.amount,
                        isSent: tx.senderId == user?.uid,
                        icon: tx.type == TransactionType.transfer ? Icons.swap_horiz_rounded : Icons.shopping_bag_outlined,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => const Text('Error loading transactions'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, UserModel? user, bool isDark) {
    return Drawer(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      border: Border.all(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(user?.initials ?? '?', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : Colors.black)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name.toUpperCase() ?? 'USER', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
                        Text('VERIFIED STATUS', style: GoogleFonts.inter(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
            _drawerItem(Icons.settings_overscan_rounded, 'Scan QR', () { Navigator.pop(context); ref.read(homeScreenIndexProvider.notifier).state = 2; }, isDark),
            _drawerItem(Icons.sync_alt_rounded, 'Transfer Funds', () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SendMoneyScreen())); }, isDark),
            _drawerItem(Icons.credit_card_rounded, 'Manage Assets', () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AllCardsScreen())); }, isDark),
            _drawerItem(Icons.bar_chart_rounded, 'Analytics', () { Navigator.pop(context); ref.read(homeScreenIndexProvider.notifier).state = 3; }, isDark),
            const Spacer(),
            Divider(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
            _drawerItem(Icons.support_agent_rounded, 'Priority Support', () {}, isDark),
            _drawerItem(Icons.settings_rounded, 'System config', () { Navigator.pop(context); ref.read(homeScreenIndexProvider.notifier).state = 4; }, isDark),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, bool isDark) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 24),
      title: Text(title.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1, color: isDark ? Colors.white : Colors.black)),
      onTap: onTap,
    );
  }

  void _showNotifications(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        ),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 12, bottom: 24), width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black26, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text('SYSTEM SIGNALS', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, fontSize: 18, letterSpacing: 1)),
                  const Spacer(),
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('CLEAR ALL', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
            ),
            Divider(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _notificationTile(Icons.security_rounded, 'Security Protocol Updated', 'Your encryption keys have been rotated successfully.', '2m ago', isDark),
                  _notificationTile(Icons.download_rounded, 'Asset Received', 'Incoming transfer of \$450.00 from verified source.', '1h ago', isDark),
                  _notificationTile(Icons.update_rounded, 'System Maintenance', 'Scheduled downtime for core infrastructure upgrade in 48h.', '2d ago', isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationTile(IconData icon, String title, String subtitle, String time, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(title.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, fontSize: 12))),
                    Text(time, style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(subtitle, style: GoogleFonts.inter(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;
  const _HeaderAction({required this.icon, required this.isDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface, 
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        ),
        child: Icon(icon, color: isDark ? Colors.white : Colors.black, size: 22),
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
