import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:propay/core/config/constants.dart';
import 'package:propay/core/widgets/cards.dart';
import 'package:propay/core/utils/formatters.dart';
import 'package:propay/features/wallet/presentation/wallet_provider.dart';
import 'package:propay/features/wallet/presentation/currency_provider.dart';

class AllCardsScreen extends ConsumerWidget {
  const AllCardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(userCardsProvider);
    final prefCurrency = ref.watch(displayCurrencyProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('CARD VAULT',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w900, 
              fontSize: 12, 
              letterSpacing: 4,
              color: isDark ? Colors.white : Colors.black,
            )),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter(
            color: isDark ? AppColors.darkGridColor : AppColors.lightGridColor,
          ))),
          cardsAsync.when(
            data: (cards) {
              if (cards.isEmpty) {
                return _buildEmptyState(context);
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: PremiumWalletCard(
                      balance: Formatters.currency(
                        CurrencyConverter.convert(
                          amount: card.balance,
                          from: card.currency,
                          to: prefCurrency,
                        ),
                        symbol: CurrencyConverter.getSymbol(prefCurrency),
                      ),
                      cardNum: card.cardNumber,
                      expDate: card.expiryDate,
                      holderName: card.cardHolder,
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary))),
            error: (e, s) => Center(child: Text('DATA LOSS ERROR: $e', style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w900, fontSize: 10))),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_off_rounded, size: 64, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
          const SizedBox(height: 32),
          Text(
            'VACANT VAULT',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No digital assets discovered in the card vault.\nInitialize a new card to proceed.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              height: 1.6,
            ),
          ),
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
