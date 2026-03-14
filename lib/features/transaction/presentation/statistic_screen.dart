import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:propay/core/config/constants.dart';
import 'package:propay/core/utils/formatters.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:propay/features/wallet/presentation/wallet_provider.dart';

class StatisticScreen extends ConsumerStatefulWidget {
  const StatisticScreen({super.key});

  @override
  ConsumerState<StatisticScreen> createState() => _StatisticScreenState();
}

class _StatisticScreenState extends ConsumerState<StatisticScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Grid
          Positioned.fill(child: CustomPaint(painter: _GridPainter(
            color: isDark ? AppColors.darkGridColor : AppColors.lightGridColor,
          ))),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMainAnalytics(context),
                      _buildTransactionHistory(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          ),
          Expanded(
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              dividerColor: Colors.transparent,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: isDark ? Colors.white : Colors.black,
              unselectedLabelColor: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
              tabs: const [
                Tab(text: 'ANALYTICS'),
                Tab(text: 'ACTIVITY'),
              ],
            ),
          ),
          const SizedBox(width: 48), // Spacer to balance the back button
        ],
      ),
    );
  }

  Widget _buildMainAnalytics(BuildContext context) {
    final user = ref.watch(userModelProvider).valueOrNull;
    final statsAsync = ref.watch(walletStatisticsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Text(
            'TOTAL BALANCE',
            style: GoogleFonts.inter(
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            Formatters.currency(user?.walletBalance ?? 0.0),
            style: GoogleFonts.inter(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 60),
          
          statsAsync.when(
            data: (stats) => Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _StatisticCard(label: 'INCOME', value: stats['income'] ?? 0.0, color: isDark ? Colors.white : Colors.black)),
                    const SizedBox(width: 16),
                    Expanded(child: _StatisticCard(label: 'EXPENSES', value: stats['expense'] ?? 0.0, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 48),
                _CashflowGraph(),
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (e, s) => Text('Error: $e', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          ),
          
          const SizedBox(height: 48),
          _QuickStatsGrid(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory(BuildContext context) {
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final user = ref.watch(userModelProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return transactionsAsync.when(
      data: (transactions) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final tx = transactions[index];
          final isSent = tx.senderId == user?.uid;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  color: isSent ? AppColors.primary : (isDark ? Colors.white : Colors.black),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSent ? 'TRANSFER TO' : 'RECEIVED FROM',
                        style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isSent ? tx.receiverId : tx.senderId,
                        style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.date(tx.timestamp),
                      style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isSent ? "-" : "+"}${Formatters.currency(tx.amount)}',
                      style: GoogleFonts.inter(
                        color: isSent ? AppColors.primary : (isDark ? Colors.white : Colors.black),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e', style: TextStyle(color: isDark ? Colors.white : Colors.black))),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _StatisticCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 12),
          Text(
            Formatters.currency(value),
            style: GoogleFonts.inter(color: color, fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _CashflowGraph extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CashflowGraph> createState() => _CashflowGraphState();
}

class _CashflowGraphState extends ConsumerState<_CashflowGraph> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final user = ref.watch(userModelProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CASHFLOW ACTIVITY (7 DAYS)', style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 24),
        Container(
          height: 220,
          padding: const EdgeInsets.only(top: 24, bottom: 12, right: 16, left: 0),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
            borderRadius: BorderRadius.circular(4),
          ),
          child: transactionsAsync.when(
            data: (transactions) {
              if (transactions.isEmpty || user == null) {
                return Center(child: Text('NO DATA', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)));
              }

              // Group by day for the last 7 days
              final now = DateTime.now();
              final Map<int, double> dailyBalances = {};
              double runningTotal = 0;

              // Process older to newer to build a cumulative line, or just daily net. Let's do daily net for volatility.
              for (int i = 6; i >= 0; i--) {
                dailyBalances[i] = 0.0;
              }

              for (var tx in transactions) {
                final txDate = tx.timestamp;
                final daysAgo = now.difference(txDate).inDays;
                if (daysAgo >= 0 && daysAgo <= 6) {
                  final amount = tx.amount;
                  if (tx.senderId == user.uid) {
                    dailyBalances[daysAgo] = (dailyBalances[daysAgo] ?? 0) - amount;
                  } else {
                    dailyBalances[daysAgo] = (dailyBalances[daysAgo] ?? 0) + amount;
                  }
                }
              }

              List<FlSpot> spots = [];
              double minY = 0;
              double maxY = 0;
              
              for (int i = 6; i >= 0; i--) {
                final net = dailyBalances[i] ?? 0.0;
                runningTotal += net;
                spots.add(FlSpot((6 - i).toDouble(), runningTotal));
                
                if (runningTotal < minY) minY = runningTotal;
                if (runningTotal > maxY) maxY = runningTotal;
              }
              
              if (minY == maxY) {
                minY -= 100;
                maxY += 100;
              }

              return LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: ((maxY - minY) / 4) == 0 ? 1 : (maxY - minY) / 4,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(color: isDark ? AppColors.darkDivider : AppColors.lightDivider, strokeWidth: 1, dashArray: [4, 4]),
                    getDrawingVerticalLine: (value) => FlLine(color: isDark ? AppColors.darkDivider : AppColors.lightDivider, strokeWidth: 1, dashArray: [4, 4]),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final daysAgo = 6 - value.toInt();
                          final date = now.subtract(Duration(days: daysAgo));
                          final style = GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontWeight: FontWeight.bold, fontSize: 10);
                          Widget text;
                          if (daysAgo == 0) {
                            text = Text('TDA', style: style.copyWith(color: AppColors.primary));
                          } else {
                            text = Text('${date.day}/${date.month}', style: style);
                          }
                          return SideTitleWidget(meta: meta, space: 8, child: text);
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: ((maxY - minY) / 3) == 0 ? 1 : (maxY - minY) / 3,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          return Text(Formatters.compactCurrency(value), 
                              style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontWeight: FontWeight.w800, fontSize: 10), 
                              textAlign: TextAlign.right);
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: minY - ((maxY - minY) * 0.1),
                  maxY: maxY + ((maxY - minY) * 0.1),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: _touchedIndex == index ? 6 : 4,
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            strokeWidth: 2,
                            strokeColor: AppColors.primary,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.3),
                            AppColors.primary.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions || touchResponse == null || touchResponse.lineBarSpots == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = touchResponse.lineBarSpots![0].spotIndex;
                      });
                    },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => isDark ? Colors.white : Colors.black,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          final textStyle = GoogleFonts.inter(
                            color: isDark ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          );
                          return LineTooltipItem(Formatters.currency(touchedSpot.y), textStyle);
                        }).toList();
                      },
                    ),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary))),
            error: (_,__) => const Center(child: Text('ERR')),
          ),
        ),
      ],
    );
  }
}


class _QuickStatsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _miniStat('PROJECTS', '560', isDark),
        _miniStat('ENTRIES', '23', isDark),
        _miniStat('CREATORS', '564', isDark),
        _miniStat('COUNTRIES', '5', isDark),
      ],
    );
  }

  Widget _miniStat(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 14)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ],
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

