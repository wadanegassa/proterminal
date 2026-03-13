import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/config/constants.dart';
import '../../wallet/presentation/wallet_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cards.dart';

class StatisticScreen extends ConsumerWidget {
  const StatisticScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(allTransactionsProvider);
    final currentUid = ref.watch(authStateProvider).valueOrNull?.uid ?? '';
    final userAsync = ref.watch(userModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent, // Controlled by parent stack/scaffold
      appBar: AppBar(
        title: Text('Insights', 
            style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: txAsync.when(
        data: (txList) {
          double totalIncome = 0;
          double totalExpense = 0;
          for (final tx in txList) {
            if (tx.senderId == currentUid) {
              totalExpense += tx.amount;
            } else {
              totalIncome += tx.amount;
            }
          }
          final recentTxs = txList.take(3).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Card
                ProCard(
                  gradient: isDark ? AppColors.darkGradient : null,
                  isGlass: isDark,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Wallet Balance',
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            userAsync.when(
                              data: (u) => Text(
                                Formatters.currency(u?.walletBalance ?? 0),
                                style: GoogleFonts.inter(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    letterSpacing: -1),
                              ),
                              loading: () => const CircularProgressIndicator(),
                              error: (_, __) => const Text('--'),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.show_chart_rounded, color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Income / Expense Stats
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Income',
                        amount: totalIncome,
                        icon: Icons.arrow_downward_rounded,
                        color: AppColors.success,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        label: 'Expenses',
                        amount: totalExpense,
                        icon: Icons.arrow_upward_rounded,
                        color: AppColors.error,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Analytics Chart
                ProCard(
                  isGlass: isDark,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Spending Chart',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: isDark ? Colors.white : AppColors.lightTextPrimary)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('MTD', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 180,
                        child: _DonutChart(
                          income: totalIncome,
                          expense: totalExpense,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Legend(color: AppColors.success, label: 'Income', isDark: isDark),
                          const SizedBox(width: 32),
                          _Legend(color: AppColors.error, label: 'Expenses', isDark: isDark),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Transaction History List
                SectionHeader(
                  title: 'Activity',
                  actionLabel: 'Details',
                  onAction: () {},
                ),
                const SizedBox(height: 12),
                if (recentTxs.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('No historical data available.',
                          style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                    ),
                  )
                else
                  ...recentTxs.map((tx) {
                    final isSent = tx.senderId == currentUid;
                    final other = isSent ? (tx.receiverName ?? 'Unknown') : (tx.senderName ?? 'Unknown');
                    return TransactionTile(
                      name: other,
                      subtitle: Formatters.dateTime(tx.timestamp),
                      amount: tx.amount,
                      isSent: isSent,
                    );
                  }),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load insights.')),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ProCard(
      isGlass: isDark,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13, 
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(Formatters.currency(amount),
              style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary)),
        ],
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  final double income;
  final double expense;
  final bool isDark;

  const _DonutChart({required this.income, required this.expense, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final total = income + expense;
    final incomeRatio = total > 0 ? income / total : 0.5;

    return CustomPaint(
      painter: _DonutPainter(incomeRatio: incomeRatio, isDark: isDark),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Cashflow',
                style: GoogleFonts.inter(
                    fontSize: 13, 
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    fontWeight: FontWeight.w600)),
            Text(Formatters.currency(income - expense),
                style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: income >= expense ? AppColors.success : AppColors.error,
                    letterSpacing: -0.5)),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double incomeRatio;
  final bool isDark;
  const _DonutPainter({required this.incomeRatio, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 10;
    const strokeWidth = 32.0;

    final bgPaint = Paint()
      ..color = isDark ? AppColors.darkDivider : AppColors.lightDivider
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final incomePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final expensePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Background of chart (Track)
    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = 2 * 3.14159 * incomeRatio;
    
    // Draw Income Segment
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      sweepAngle,
      false,
      incomePaint,
    );

    // Draw Expense Segment (remainder)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2 + sweepAngle,
      2 * 3.14159 - sweepAngle,
      false,
      expensePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;

  const _Legend({required this.color, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color, 
            shape: BoxShape.circle,
            boxShadow: [
              if (isDark) BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
      ],
    );
  }
}
