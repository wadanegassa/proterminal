import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:propay/core/config/constants.dart';
import 'package:propay/features/wallet/presentation/wallet_provider.dart';
import 'package:propay/core/widgets/cards.dart';
import 'package:propay/features/wallet/presentation/currency_provider.dart';
import 'package:propay/core/utils/formatters.dart';
import 'package:propay/features/transaction/presentation/statistic_screen.dart';
import 'package:propay/features/qr_payment/presentation/receive_qr_screen.dart';
import 'package:propay/features/product/presentation/product_provider.dart';
import 'package:propay/features/auth/presentation/profile_screen.dart';
import 'package:propay/features/wallet/presentation/all_cards_screen.dart';
import 'package:propay/features/transaction/domain/transaction_model.dart';
import 'package:propay/features/auth/domain/user_model.dart';
import 'package:propay/features/product/presentation/product_list_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  final List<Widget> _pages = [
    const _HomeTab(),
    const PlatformScreen(), // New page at index 1
    const ReceiveQRScreen(),
    const StatisticScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(homeScreenIndexProvider);
    final user = ref.watch(userModelProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefCurrency = ref.watch(displayCurrencyProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: _buildDrawer(context, user, isDark),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _HeaderAction(icon: Icons.sort_rounded, isDark: isDark, onTap: () => _scaffoldKey.currentState?.openDrawer()),
                Row(
                  children: [
                    Consumer(builder: (context, ref, _) {
                      final pref = ref.watch(displayCurrencyProvider);
                      return GestureDetector(
                        onTap: () => ref.read(displayCurrencyProvider.notifier).state = 
                            pref == DisplayCurrency.usd ? DisplayCurrency.etb : DisplayCurrency.usd,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            pref == DisplayCurrency.usd ? 'USD' : 'ETB',
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      );
                    }),
                    Stack(
                      children: [
                        _HeaderAction(icon: Icons.notifications_none_rounded, isDark: isDark, onTap: () => _showNotifications(context, isDark, prefCurrency)),
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: isDark ? AppColors.darkSurface : Colors.white, width: 1.5)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
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
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 10),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.hub_rounded, size: 20), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.layers_rounded, size: 20), label: 'Platforms'),
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale_rounded, size: 20), label: 'Receive'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded, size: 20), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_rounded, size: 20), label: 'Admin'),
        ],
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
            _drawerItem(Icons.settings_overscan_rounded, 'Pay at Office', () { Navigator.pop(context); ref.read(homeScreenIndexProvider.notifier).state = 2; }, isDark),
            _drawerItem(Icons.layers_rounded, 'Platform Ecosystem', () { 
              Navigator.pop(context);
              ref.read(homeScreenIndexProvider.notifier).state = 1;
            }, isDark),
            _drawerItem(Icons.credit_card_rounded, 'Manage Assets', () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AllCardsScreen())); }, isDark),
            _drawerItem(Icons.bar_chart_rounded, 'Analytics', () { Navigator.pop(context); ref.read(homeScreenIndexProvider.notifier).state = 3; }, isDark),
            const Spacer(),
            Divider(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
            _drawerItem(Icons.support_agent_rounded, 'Priority Support', () => _showSupport(context, isDark), isDark),
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

  void _showNotifications(BuildContext context, bool isDark, DisplayCurrency prefCurrency) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Consumer(
        builder: (context, ref, child) {
          final txsAsync = ref.watch(allTransactionsProvider);
          
          return Container(
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
                      TextButton(onPressed: () => Navigator.pop(context), child: Text('DISMISS', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                ),
                Divider(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                Expanded(
                  child: txsAsync.when(
                    data: (txs) {
                      if (txs.isEmpty) {
                        return Center(
                          child: Text('NO SYSTEM SIGNALS', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.black26, letterSpacing: 2)),
                        );
                      }
                      
                      return ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: txs.take(5).length,
                        itemBuilder: (context, index) {
                          final tx = txs[index];
                          return _notificationTile(
                            tx.isIncome ? Icons.download_rounded : Icons.outbox_rounded, 
                            tx.isIncome ? 'REVENUE SIGNAL' : 'DISBURSEMENT', 
                            '${tx.isIncome ? '+' : '-'}${Formatters.currency(
                              CurrencyConverter.convert(
                                amount: tx.amount,
                                from: tx.platform?.toLowerCase() == 'chapa' ? 'ETB' : 'USD',
                                to: prefCurrency,
                              ),
                              symbol: CurrencyConverter.getSymbol(prefCurrency),
                            )} via ${tx.platform ?? "System"}', 
                            Formatters.date(tx.timestamp), 
                            isDark
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_,__) => Center(child: Text('SIGNAL ERROR', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: AppColors.error))),
                  ),
                ),
              ],
            ),
          );
        }
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
  void _showSupport(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black26, borderRadius: BorderRadius.circular(2)), margin: const EdgeInsets.only(bottom: 24)),
            Text('PRIORITY SUPPORT', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : Colors.black, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text('Direct line to technical operations. 24/7 coverage.', style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 12)),
            const SizedBox(height: 32),
            _SupportAction(icon: Icons.phone_in_talk_rounded, label: 'CALL OPERATOR', color: Colors.greenAccent, isDark: isDark),
            const SizedBox(height: 12),
            _SupportAction(icon: Icons.chat_bubble_rounded, label: 'SECURE CHAT', color: AppColors.primary, isDark: isDark),
            const SizedBox(height: 12),
            _SupportAction(icon: Icons.bug_report_rounded, label: 'REPORT INCIDENT', color: Colors.amber, isDark: isDark),
            const SizedBox(height: 24),
          ],
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userModelProvider);
        ref.invalidate(userCardsProvider);
        ref.invalidate(allTransactionsProvider);
        ref.invalidate(businessAnalyticsProvider);
      },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Business Health Overview',
                style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                "Cross-platform managed balances & performance.",
                style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32), 
              
              _CrossPlatformBalanceCard(isDark: isDark),

              const SizedBox(height: 40), 

              // Platform Performance Hub
              _PlatformRevenueGrid(isDark: isDark),
              
              const SizedBox(height: 48),

              // Inventory Health Snapshot
              SectionHeader(
                title: 'Inventory Health',
                actionLabel: 'Manage',
                onAction: () => ref.read(homeScreenIndexProvider.notifier).state = 1,
              ),
              const SizedBox(height: 16),
              _InventorySnapshot(isDark: isDark),

              const SizedBox(height: 48),
              
              // Key Metrics
              ref.watch(businessAnalyticsProvider).when(
                data: (analytics) {
                  final prefCurrency = ref.watch(displayCurrencyProvider);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _MetricMiniCard(
                        label: 'Total Net', 
                        value: Formatters.compactCurrency((analytics['totalNet'] as num?)?.toDouble() ?? 0.0, symbol: CurrencyConverter.getSymbol(prefCurrency)), 
                        isDark: isDark,
                        isPositive: true,
                      ),
                      _MetricMiniCard(
                        label: 'Avg LTV', 
                        value: Formatters.compactCurrency((analytics['avgLTV'] as num?)?.toDouble() ?? 0.0, symbol: CurrencyConverter.getSymbol(prefCurrency)), 
                        isDark: isDark,
                        isPositive: true,
                      ),
                      _MetricMiniCard(
                        label: 'Growth', 
                        value: '${(((analytics['growthRate'] as num?)?.toDouble() ?? 0.0) * 100).toStringAsFixed(1)}%', 
                        isDark: isDark, 
                        isPositive: ((analytics['growthRate'] as num?)?.toDouble() ?? 0.0) >= 0,
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: LinearProgressIndicator()),
                error: (e, s) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 40),

              // Platform Performance Signals
              SectionHeader(
                title: 'Platform Signals',
                actionLabel: 'Details',
                onAction: () => ref.read(homeScreenIndexProvider.notifier).state = 3, 
              ),
              const SizedBox(height: 16),
              ref.watch(allTransactionsProvider).when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'No signals detected.',
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
                        name: tx.receiverName ?? (tx.type == TransactionType.payment ? 'ProShop Order' : 'System Credit'),
                        subtitle: '${Formatters.date(tx.timestamp)} • ${tx.platform?.toUpperCase() ?? 'POS'}',
                        amount: tx.amount,
                        isSent: false,
                        icon: Icons.signal_cellular_alt_rounded,
                        platform: tx.platform,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => const Text('Error loading signals'),
              ),
            ],
          ),
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

class _PlatformRevenueGrid extends ConsumerWidget {
  final bool isDark;
  const _PlatformRevenueGrid({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(businessAnalyticsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return analyticsAsync.when(
      data: (analytics) {
        final prefCurrency = ref.watch(displayCurrencyProvider);
        final revenueByPlatform = analytics['revenueByPlatform'] as Map<String, double>;
        final totalNet = (analytics['totalNet'] as num).toDouble();
        final sortedPlatforms = revenueByPlatform.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

        if (revenueByPlatform.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text('NO DATA SIGNALS DETECTED', style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2)),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: sortedPlatforms.map((entry) {
                final platform = entry.key;
                final revenue = entry.value;
                final progress = totalNet > 0 ? (revenue / totalNet) : 0.0;
                
                return _PlatformMiniCard(
                  name: platform.toUpperCase(), 
                  revenue: Formatters.currency(revenue, symbol: CurrencyConverter.getSymbol(prefCurrency)), 
                  progress: progress, 
                  color: _getPlatformColor(platform), 
                  isDark: isDark
                );
              }).toList(),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Data Error', style: TextStyle(color: isDark ? Colors.white : Colors.black))),
    );
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'proshop': return AppColors.primary;
      case 'prodev': return Colors.blueAccent;
      case 'office': return Colors.greenAccent;
      case 'stripe': return const Color(0xFF6772E5);
      case 'chapa': return const Color(0xFF00C3DA);
      default: return Colors.amber;
    }
  }
}

class _PlatformMiniCard extends StatelessWidget {
  final String name;
  final String revenue;
  final double progress;
  final Color color;
  final bool isDark;

  const _PlatformMiniCard({
    required this.name, 
    required this.revenue, 
    required this.progress, 
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 64) / 2,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Text(revenue, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: isDark ? Colors.white12 : Colors.black12,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 2,
          ),
        ],
      ),
    );
  }
}

class _MetricMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool isPositive;

  const _MetricMiniCard({
    required this.label, 
    required this.value, 
    required this.isDark,
    this.isPositive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: isPositive ? Colors.greenAccent : (isDark ? Colors.white : Colors.black))),
        const SizedBox(height: 4),
        Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, letterSpacing: 1)),
      ],
    );
  }
}

class _CrossPlatformBalanceCard extends ConsumerWidget {
  final bool isDark;
  const _CrossPlatformBalanceCard({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(businessAnalyticsProvider);

    return analyticsAsync.when(
      data: (data) {
        final prefCurrency = ref.watch(displayCurrencyProvider);
        final totalBalance = (data['totalManagedBalance'] as num).toDouble();
        final platformData = data['platformBalances'] as Map<String, Map<String, dynamic>>;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOTAL MANAGED ASSETS', style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 12),
              Text(
                Formatters.currency(totalBalance, symbol: CurrencyConverter.getSymbol(prefCurrency)), 
                style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)
              ),
              const SizedBox(height: 24),
              Divider(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: platformData.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.key, style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text(Formatters.compactCurrency((e.value['balance'] as num).toDouble(), symbol: CurrencyConverter.getSymbol(prefCurrency)), 
                             style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w800, fontSize: 16)),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: LinearProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SupportAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  const _SupportAction({required this.icon, required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, fontSize: 12, letterSpacing: 1)),
          const Spacer(),
          Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white12 : Colors.black12),
        ],
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

class _InventorySnapshot extends ConsumerWidget {
  final bool isDark;
  const _InventorySnapshot({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return productsAsync.when(
      data: (products) {
        final totalSKUs = products.length;
        final outOfStock = products.where((p) => p.stockQuantity == 0).length;
        final lowStock = products.where((p) => p.stockQuantity > 0 && p.stockQuantity <= 5).length;

        return Row(
          children: [
            Expanded(
              child: _SnapshotTile(
                label: 'TOTAL SKUS',
                value: totalSKUs.toString(),
                icon: Icons.inventory_2_rounded,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SnapshotTile(
                label: 'LOW STOCK',
                value: lowStock.toString(),
                icon: Icons.warning_amber_rounded,
                isDark: isDark,
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SnapshotTile(
                label: 'OUT OF STOCK',
                value: outOfStock.toString(),
                icon: Icons.error_outline_rounded,
                isDark: isDark,
                color: AppColors.primary,
              ),
            ),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SnapshotTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;
  final Color? color;

  const _SnapshotTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color ?? (isDark ? Colors.white38 : Colors.black26)),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.w900, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, letterSpacing: 1)),
        ],
      ),
    );
  }
}
