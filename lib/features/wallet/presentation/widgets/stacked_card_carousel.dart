import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:propay/core/config/constants.dart';
import 'package:propay/core/widgets/cards.dart';
import 'package:propay/features/wallet/domain/card_model.dart';
import 'package:propay/core/utils/formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:propay/features/wallet/presentation/currency_provider.dart';

class StackedCardCarousel extends ConsumerStatefulWidget {
  final List<CardModel> cards;
  final Function(CardModel) onCardChanged;

  const StackedCardCarousel({
    super.key,
    required this.cards,
    required this.onCardChanged,
  });

  @override
  ConsumerState<StackedCardCarousel> createState() => _StackedCardCarouselState();
}

class _StackedCardCarouselState extends ConsumerState<StackedCardCarousel> with SingleTickerProviderStateMixin {
  late List<CardModel> _cards;
  double _dragDy = 0.0;
  late AnimationController _animCtrl;
  Animation<double>? _slideAnim;

  @override
  void initState() {
    super.initState();
    _cards = List.from(widget.cards);
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _animCtrl.addListener(() {
      if (_slideAnim != null) {
        setState(() {
          _dragDy = _slideAnim!.value;
        });
      }
    });
    _animCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_dragDy <= -150) {
          _cycleCard();
        } else {
          setState(() {
            _dragDy = 0.0;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(StackedCardCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cards.length != oldWidget.cards.length) {
      setState(() {
        _cards = List.from(widget.cards);
      });
    }
  }

  void _cycleCard() {
    if (_cards.length < 2) return;
    setState(() {
      final topCard = _cards.removeAt(0);
      _cards.add(topCard);
      _dragDy = 0.0;
    });
    widget.onCardChanged(_cards.first);
  }

  void _showCardDetails(CardModel card) {
    if (_dragDy != 0.0 || _animCtrl.isAnimating) return; // Prevent tap while dragging
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(4))),
            ),
            const SizedBox(height: 24),
            Text('Card Details', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 24),
            _detailRow('Platform', card.type, isDark),
            const SizedBox(height: 16),
            _detailRow(card.platform == 'visa' || card.platform == 'mastercard' ? 'Card Number' : 'Account/Phone', card.cardNumber, isDark),
            const SizedBox(height: 16),
            _detailRow('Holder/Name', card.cardHolder, isDark),
            if (card.expiryDate != 'N/A') ...[
              const SizedBox(height: 16),
              _detailRow('Expiry Date', card.expiryDate, isDark),
              const SizedBox(height: 16),
              _detailRow('CVV', '***', isDark),
            ],
            const SizedBox(height: 32),
            GradientButton(
              label: 'Close',
              onPressed: () => Navigator.pop(context),
              gradient: AppColors.primaryGradient,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white54 : Colors.black54)),
        Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) {
      return const PremiumWalletCard(
        balance: r'$0.00',
        cardNum: 'xxxx xxxx xxxx xxxx',
        expDate: 'MM/YY',
        holderName: 'NO CARD',
        gradient: AppColors.primaryGradient,
        platform: 'propay',
      );
    }

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (_animCtrl.isAnimating) return;
        setState(() {
          _dragDy += details.delta.dy;
          if (_dragDy > 0) _dragDy = 0; // Prevent dragging down
        });
      },
      onVerticalDragEnd: (details) {
        if (_animCtrl.isAnimating) return;
        final velocity = details.velocity.pixelsPerSecond.dy;
        if (_dragDy < -80.0 || velocity < -500) {
          _slideAnim = Tween<double>(begin: _dragDy, end: -200.0).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
        } else {
          _slideAnim = Tween<double>(begin: _dragDy, end: 0.0).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
        }
        _animCtrl.forward(from: 0);
      },
      child: AspectRatio(
        aspectRatio: 1.6,
        child: Stack(
          clipBehavior: Clip.none,
          children: _buildStack(),
        ),
      ),
    );
  }

  List<Widget> _buildStack() {
    final List<Widget> items = [];
    final int count = _cards.length > 3 ? 3 : _cards.length;

    final prefCurrency = ref.watch(displayCurrencyProvider);

    for (int i = count - 1; i >= 0; i--) {
      final card = _cards[i];
      final bool isTop = i == 0;
      
      final convertedBalance = CurrencyConverter.convert(
        amount: card.balance,
        from: card.currency,
        to: prefCurrency,
      );

      items.add(
        Positioned(
          top: isTop ? _dragDy.clamp(-200.0, 0.0) : (i * -16.0),
          left: 0,
          right: 0,
          child: Opacity(
            opacity: (1.0 - (i * 0.15)).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: (1.0 - (i * 0.05)).clamp(0.85, 1.0),
              child: PremiumWalletCard(
                balance: Formatters.currency(convertedBalance, symbol: CurrencyConverter.getSymbol(prefCurrency)),
                cardNum: card.cardNumber,
                expDate: card.expiryDate,
                holderName: card.cardHolder,
                gradient: _getGradient(card.gradientIndex),
                platform: card.platform,
                onTap: isTop ? () => _showCardDetails(card) : null,
              ),
            ),
          ),
        ),
      );
    }
    return items;
  }

  LinearGradient _getGradient(int index) {
    switch (index) {
      case 1: return AppColors.secondaryGradient;
      case 2: return AppColors.accentGradient;
      case 3: return AppColors.cardGradientOrange;
      default: return AppColors.primaryGradient;
    }
  }
}
