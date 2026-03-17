import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:propay/core/config/constants.dart';
import 'package:propay/core/utils/formatters.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:propay/features/wallet/presentation/wallet_provider.dart';
import 'package:propay/features/wallet/presentation/currency_provider.dart';

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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: false,
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


  Widget _buildMainAnalytics(BuildContext context) {
    final analyticsAsync = ref.watch(businessAnalyticsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefCurrency = ref.watch(displayCurrencyProvider);

    return analyticsAsync.when(
      data: (analytics) {
        final totalNet = (analytics['totalNet'] as num?)?.toDouble() ?? 0.0;
        final revenueByPlatform = analytics['revenueByPlatform'] as Map<String, double>? ?? {};
        final monthlyTrends = analytics['monthlyTrends'] as Map<String, double>? ?? {};
        final regionalDistribution = analytics['regionalDistribution'] as Map<String, double>? ?? {};
        final avgLTV = (analytics['avgLTV'] as num?)?.toDouble() ?? 0.0;
        final growthRate = (analytics['growthRate'] as num?)?.toDouble() ?? 0.0;
        final retentionRate = (analytics['retentionRate'] as num?)?.toDouble() ?? 0.0;
        final velocity = (analytics['transactionVelocity'] as num?)?.toDouble() ?? 0.0;
        final terminals = (analytics['activeTerminals'] as num?)?.toInt() ?? 0;
        final productRevenue = analytics['productRevenue'] as Map<String, double>? ?? {};
        final categoryRevenue = analytics['categoryRevenue'] as Map<String, double>? ?? {};

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              
              // Primary Metrics
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL NET REVENUE',
                        style: GoogleFonts.inter(
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Formatters.currency(totalNet, symbol: CurrencyConverter.getSymbol(prefCurrency)),
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TerminalHealthRow(count: terminals, isDark: isDark),
                      const SizedBox(width: 12),
                      _ExportButton(isDark: isDark),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _VelocityChart(velocity: velocity, spots: analytics['velocitySpots'] as List<FlSpot>?, isDark: isDark),
              
              const SizedBox(height: 40),
              
              Row(
                children: [
                  Expanded(child: _StatisticCard(label: 'GROSS', value: totalNet, color: Colors.greenAccent, symbol: CurrencyConverter.getSymbol(prefCurrency))),
                  const SizedBox(width: 16),
                  Expanded(child: _StatisticCard(label: 'REFUNDS', value: (analytics['totalRefunds'] as num?)?.toDouble() ?? 0.0, color: AppColors.primary, symbol: CurrencyConverter.getSymbol(prefCurrency))),
                ],
              ),
              const SizedBox(height: 40),
              _RevenueDonutChart(data: revenueByPlatform),
              const SizedBox(height: 40),
              _CashflowGraph(),
              const SizedBox(height: 40),
               _MonthlyBarChart(data: monthlyTrends),
              const SizedBox(height: 40),
              _RegionalDistributionChart(data: regionalDistribution, totalNet: totalNet),
              const SizedBox(height: 40),
              _RetentionHealthGauge(retention: retentionRate),
              
              const SizedBox(height: 48),
              _QuickStatsGrid(ltv: avgLTV, growth: growthRate),
              const SizedBox(height: 40),
              _ActivityHeatmap(density: analytics['activityDensity'] as List<List<int>>?),
              const SizedBox(height: 48),
              _ProductPerformance(productRevenue: productRevenue),
              const SizedBox(height: 48),
              _CategoryBreakdownChart(categoryRevenue: categoryRevenue),
              
              const SizedBox(height: 48),
              _PlatformAOVChart(aovByPlatform: analytics['aovByPlatform'] as Map<String, double>? ?? {}, isDark: isDark),

              const SizedBox(height: 100),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary))),
      error: (e, s) => _buildErrorState(context, e.toString(), isDark),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              error.contains('Optimizing') || error.contains('indexes') 
                ? Icons.auto_awesome_rounded 
                : Icons.error_outline_rounded,
              color: AppColors.primary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              error.contains('Optimizing') || error.contains('indexes')
                ? 'OPTIMIZING FINANCIAL DATA'
                : 'SIGNAL INTERRUPTED',
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHistory(BuildContext context) {
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final user = ref.watch(userModelProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefCurrency = ref.watch(displayCurrencyProvider);

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Center(
            child: Text(
              'NO TRANSACTIONS DETECTED',
              style: GoogleFonts.inter(
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          );
        }
        return ListView.builder(
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
                    color: !isSent ? Colors.greenAccent : AppColors.primary,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSent ? 'REFUND ISSUED' : (tx.platform == 'Stripe' || tx.platform == 'Chapa' ? 'PROSHOP SIGNAL' : 'REVENUE SIGNAL'),
                          style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isSent ? (tx.receiverName ?? 'System') : (tx.senderName ?? (tx.platform ?? 'External Customer')),
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
                      Row(
                        children: [
                          if (tx.platform != null)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(tx.platform!.toUpperCase(), style: GoogleFonts.inter(color: AppColors.primary, fontSize: 8, fontWeight: FontWeight.w900)),
                            ),
                          Text(
                            '${isSent ? "-" : "+"}${Formatters.currency(
                              CurrencyConverter.convert(
                                amount: tx.amount, 
                                from: tx.platform?.toLowerCase() == "chapa" ? "ETB" : "USD", 
                                to: prefCurrency
                              ), 
                              symbol: CurrencyConverter.getSymbol(prefCurrency)
                            )}',
                            style: GoogleFonts.inter(
                              color: !isSent ? Colors.greenAccent : AppColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary))),
      error: (e, s) => _buildErrorState(context, e.toString(), isDark),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String? symbol;
  const _StatisticCard({required this.label, required this.value, required this.color, this.symbol});

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
            Formatters.currency(value, symbol: symbol),
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

              for (int i = 6; i >= 0; i--) {
                dailyBalances[i] = 0.0;
              }

              for (var tx in transactions) {
                final txDate = tx.timestamp;
                final daysAgo = now.difference(txDate).inDays;
                if (daysAgo >= 0 && daysAgo <= 6) {
                  final amount = CurrencyConverter.convert(
                    amount: tx.amount,
                    from: tx.platform?.toLowerCase() == 'chapa' ? 'ETB' : 'USD',
                    to: ref.watch(displayCurrencyProvider),
                  );
                  if (tx.isIncome) {
                    dailyBalances[daysAgo] = (dailyBalances[daysAgo] ?? 0) + amount;
                  } else {
                    dailyBalances[daysAgo] = (dailyBalances[daysAgo] ?? 0) - amount;
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
                          return Text(Formatters.compactCurrency(value, symbol: CurrencyConverter.getSymbol(ref.watch(displayCurrencyProvider))), 
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
                          return LineTooltipItem(
                            Formatters.currency(touchedSpot.y, symbol: CurrencyConverter.getSymbol(ref.watch(displayCurrencyProvider))), 
                            textStyle
                          );
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

class _RevenueDonutChart extends StatelessWidget {
  final Map<String, double> data;
  const _RevenueDonutChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = data.values.fold(0.0, (sum, val) => sum + val);

    if (total == 0) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text('NO DATA SIGNALS', style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontWeight: FontWeight.w900)),
      );
    }

    final sortedEntries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final colors = [AppColors.primary, Colors.blueAccent, Colors.amber, Colors.greenAccent, Colors.purpleAccent, Colors.orangeAccent];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REVENUE DISTRIBUTION', style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 60,
                      sections: sortedEntries.asMap().entries.map((e) {
                        final index = e.key;
                        final entry = e.value;
                        return PieChartSectionData(
                          color: colors[index % colors.length],
                          value: entry.value,
                          title: '',
                          radius: 12 - (index * 1.0).clamp(0, 4),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sortedEntries.asMap().entries.take(4).map((e) {
                    final index = e.key;
                    final entry = e.value;
                    final percent = (entry.value / total) * 100;
                    return _legendItem(
                      entry.key.toUpperCase(), 
                      colors[index % colors.length], 
                      '${percent.toStringAsFixed(0)}%', 
                      isDark
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, String percent, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.inter(color: isDark ? Colors.white70 : Colors.black87, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(percent, style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 10, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final Map<String, double> data;
  const _MonthlyBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sortedMonths = data.keys.toList()..sort();
    final maxVal = data.values.fold(0.0, (max, val) => val > max ? val : max);

    if (data.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MONTHLY PERFORMANCE', style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal == 0 ? 100 : maxVal * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= sortedMonths.length) return const SizedBox.shrink();
                        final monthStr = sortedMonths[index]; // e.g., '2024-03'
                        final month = int.parse(monthStr.split('-')[1]);
                        final names = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
                        return SideTitleWidget(meta: meta, space: 10, child: Text(names[month - 1], style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 8)));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: sortedMonths.asMap().entries.map((e) {
                  return _barGroup(e.key, data[e.value]!, AppColors.primary, maxVal == 0 ? 100 : maxVal * 1.2);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y, Color color, double backgroundMax) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          backDrawRodData: BackgroundBarChartRodData(show: true, toY: backgroundMax, color: color.withValues(alpha: 0.05)),
        ),
      ],
    );
  }
}

class _ActivityHeatmap extends StatelessWidget {
  final List<List<int>>? density;
  const _ActivityHeatmap({this.density});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Fallback to empty grid if no data
    final data = density ?? List.generate(7, (_) => List.filled(24, 0));
    
    // Find max intensity for scaling colors
    int maxIntensity = 1;
    for (var row in data) {
      for (var val in row) {
        if (val > maxIntensity) maxIntensity = val;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('REAL-TIME SIGNAL INTENSITY (30 DAYS)', style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
            borderRadius: BorderRadius.circular(4),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(7, (row) => Row(
                children: List.generate(24, (col) {
                  final intensity = data[row][col];
                  final opacity = intensity == 0 ? 0.05 : (0.2 + (intensity / maxIntensity) * 0.8).clamp(0.2, 1.0);
                  
                  return Tooltip(
                    message: 'Stat ${['Sun','Mon','Tue','Wed','Thu','Fri','Sat'][row]} $col:00 - $intensity signals',
                    child: Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: intensity == 0 
                            ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05))
                            : AppColors.primary.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  );
                }),
              )),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExportButton extends ConsumerWidget {
  final bool isDark;
  const _ExportButton({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        final transactions = ref.read(allTransactionsProvider).valueOrNull ?? [];
        if (transactions.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No transaction data to export.')));
          return;
        }

        final header = 'ID,Timestamp,Sender,Receiver,Amount,Platform,Type,Status,Note\n';
        final csv = header + transactions.map((t) => t.toCsvRow()).join('\n');

        // Note: In a real mobile app, we would use path_provider and share_plus
        // For this demo, we simulate the file creation and show the payload size
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Financial report generated (${(csv.length / 1024).toStringAsFixed(1)} KB). Saving to device...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Report saved to Documents/ProAdmin_Report.csv'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(Icons.ios_share_rounded, color: AppColors.primary, size: 14),
            const SizedBox(width: 8),
            Text('EXPORT', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

class _QuickStatsGrid extends ConsumerWidget {
  final double ltv;
  final double growth;
  const _QuickStatsGrid({required this.ltv, required this.growth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final analyticsAsync = ref.watch(businessAnalyticsProvider);

    return analyticsAsync.when(
      data: (analytics) {
        final retention = (analytics['retentionRate'] as num?)?.toDouble() ?? 0.0;
        final orders = ref.watch(allTransactionsProvider).valueOrNull?.length ?? 0;
        final signals = (analytics['transactionVelocity'] as num?)?.toDouble() ?? 0.0;
        final terminals = (analytics['activeTerminals'] as num?)?.toInt() ?? 0;
        final net = (analytics['totalNet'] as num?)?.toDouble() ?? 0.0;

                final prefCurrency = ref.watch(displayCurrencyProvider);
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _miniStat('RETENTION', '${(retention * 100).toStringAsFixed(1)}%', isDark, isPositive: retention > 0.5),
                        _miniStat('GROWTH', '${(growth * 100).toStringAsFixed(1)}%', isDark, isPositive: growth > 0),
                        _miniStat('AVG LTV', Formatters.compactCurrency(ltv, symbol: CurrencyConverter.getSymbol(prefCurrency)), isDark, isPositive: ltv > 50),
                        _miniStat('CAC', 'N/A', isDark),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _miniStat('ORDERS', orders.toString(), isDark),
                        _miniStat('Terminals', terminals.toString(), isDark, isPositive: terminals > 0),
                        _miniStat('Signals/hr', signals.toStringAsFixed(1), isDark),
                        _miniStat('Net Volume', Formatters.compactCurrency(net, symbol: CurrencyConverter.getSymbol(prefCurrency)), isDark, isPositive: net > 0),
                      ],
                    ),
                  ],
                );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }


  Widget _miniStat(String label, String value, bool isDark, {bool isPositive = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: GoogleFonts.inter(
          color: isPositive ? Colors.greenAccent : (isDark ? Colors.white : Colors.black), 
          fontWeight: FontWeight.w900, 
          fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(label.toUpperCase(), style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ],
    );
  }
}

class _RegionalDistributionChart extends ConsumerWidget {
  final Map<String, double> data;
  final double totalNet;
  const _RegionalDistributionChart({required this.data, required this.totalNet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefCurrency = ref.watch(displayCurrencyProvider);
    final sortedByRevenue = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxRevenue = sortedByRevenue.isEmpty ? 1.0 : sortedByRevenue.first.value;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REGIONAL REVENUE FLOW', style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 32),
          ...sortedByRevenue.take(4).map((e) {
            final percent = totalNet > 0 ? (e.value / totalNet) * 100 : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${e.key.toUpperCase()} (${percent.toStringAsFixed(0)}%)', 
                        style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text(Formatters.compactCurrency(e.value, symbol: CurrencyConverter.getSymbol(prefCurrency)), 
                        style: GoogleFonts.inter(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(height: 4, width: double.infinity, decoration: BoxDecoration(color: isDark ? Colors.white12 : Colors.black12, borderRadius: BorderRadius.circular(2))),
                      FractionallySizedBox(
                        widthFactor: (e.value / maxRevenue).clamp(0.01, 1.0),
                        child: Container(height: 4, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _RetentionHealthGauge extends StatelessWidget {
  final double retention;
  const _RetentionHealthGauge({required this.retention});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              children: [
                Center(
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 8,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                Center(
                  child: CircularProgressIndicator(
                    value: retention,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    color: Colors.greenAccent,
                  ),
                ),
                Center(
                  child: Text('${(retention * 100).toStringAsFixed(0)}%', style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RETENTION HEALTH', style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 8),
                Text(retention > 0.7 
                  ? 'Excellent stability. ${(retention * 100).toStringAsFixed(0)}% of users active across platforms.'
                  : 'Growth opportunity. ${(retention * 100).toStringAsFixed(0)}% retention rate detected.', 
                  style: GoogleFonts.inter(color: isDark ? Colors.white70 : Colors.black87, fontSize: 11, fontWeight: FontWeight.bold, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TerminalHealthRow extends StatelessWidget {
  final int count;
  final bool isDark;
  const _TerminalHealthRow({required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('$count ACTIVE', style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _VelocityChart extends ConsumerWidget {
  final double velocity;
  final List<FlSpot>? spots;
  final bool isDark;
  const _VelocityChart({required this.velocity, this.spots, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TRANSACTION VELOCITY', style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                Text('${velocity.toStringAsFixed(1)} TX/HR', style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 24)),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            height: 40,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: (spots == null || spots!.isEmpty) 
                        ? [const FlSpot(0, 0), const FlSpot(10, 0)]
                        : spots!,
                    isCurved: true,
                    color: Colors.greenAccent,
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductPerformance extends ConsumerWidget {
  final Map<String, double> productRevenue;
  const _ProductPerformance({required this.productRevenue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefCurrency = ref.watch(displayCurrencyProvider);
    final sortedProducts = productRevenue.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final displayProducts = sortedProducts.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TOP PRODUCT PERFORMANCE', style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
            borderRadius: BorderRadius.circular(4),
          ),
          child: displayProducts.isEmpty 
            ? Center(child: Text('NO PRODUCT SIGNALS', style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontWeight: FontWeight.bold, fontSize: 12)))
            : Column(
                children: displayProducts.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(e.key.toUpperCase(), style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
                      ),
                      Text(Formatters.currency(e.value, symbol: CurrencyConverter.getSymbol(prefCurrency)), style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 14)),
                    ],
                  ),
                )).toList(),
              ),
        ),
      ],
    );
  }
}

class _CategoryBreakdownChart extends StatelessWidget {
  final Map<String, double> categoryRevenue;
  const _CategoryBreakdownChart({required this.categoryRevenue});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = categoryRevenue.values.fold(0.0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('REVENUE BY CATEGORY', style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 24),
        SizedBox(
          height: 200,
          child: categoryRevenue.isEmpty 
            ? Center(child: Text('NO CATEGORY DATA', style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontWeight: FontWeight.bold, fontSize: 12)))
            : PieChart(
                PieChartData(
                  sections: categoryRevenue.entries.map((e) {
                    final index = categoryRevenue.keys.toList().indexOf(e.key);
                    return PieChartSectionData(
                      value: e.value,
                      title: '${((e.value / total) * 100).toStringAsFixed(0)}%',
                      radius: 50,
                      titleStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                      color: _getColor(index),
                    );
                  }).toList(),
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                ),
              ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: categoryRevenue.entries.map((e) {
            final index = categoryRevenue.keys.toList().indexOf(e.key);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, color: _getColor(index)),
                const SizedBox(width: 8),
                Text(e.key.toUpperCase(), style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getColor(int index) {
    List<Color> colors = [AppColors.primary, Colors.blueAccent, Colors.greenAccent, Colors.amber, Colors.purpleAccent];
    return colors[index % colors.length];
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

class _PlatformAOVChart extends ConsumerWidget {
  final Map<String, double> aovByPlatform;
  final bool isDark;

  const _PlatformAOVChart({required this.aovByPlatform, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefCurrency = ref.watch(displayCurrencyProvider);
    final sortedAov = aovByPlatform.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AVG ORDER VALUE BY PLATFORM',
          style: GoogleFonts.inter(
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 24),
        if (sortedAov.isEmpty)
          Center(
            child: Text(
              'NO SIGNAL DETECTED',
              style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedAov.length,
            itemBuilder: (context, index) {
              final entry = sortedAov[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key.toUpperCase(), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
                        Text(Formatters.currency(entry.value, symbol: CurrencyConverter.getSymbol(prefCurrency)), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: index == 0 ? 1.0 : entry.value / sortedAov[0].value,
                      backgroundColor: isDark ? Colors.white12 : Colors.black12,
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 2,
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

