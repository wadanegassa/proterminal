import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/constants.dart';
import '../utils/formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/wallet/presentation/currency_provider.dart';
import 'package:flutter/services.dart';

// ─── Adaptive Stark Container ─────────────────────────────────────────
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Border? border;
  final EdgeInsetsGeometry? padding;
  final bool disableBlur;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 4, // Stark sharp corners
    this.blur = 16,
    this.color,
    this.border,
    this.padding,
    this.disableBlur = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ??
            (isDark
                ? AppColors.darkSurface
                : Colors.white.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ??
            Border.all(
              color: isDark
                  ? AppColors.darkDivider
                  : Colors.white.withValues(alpha: 0.4),
              width: 1.0,
            ),
      ),
      child: child,
    );

    if (disableBlur || !isDark) {
      return container;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: container,
      ),
    );
  }
}

// ─── Adaptive Pro Card (Stark) ────────────────────────────────────────────────────────
class ProCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final LinearGradient? gradient;
  final bool isGlass;

  const ProCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.onTap,
    this.gradient,
    this.isGlass = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final body = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: gradient == null && !isGlass
            ? (isDark ? AppColors.darkSurface : AppColors.lightCard)
            : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(4), // Stark industrial corners
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
      ),
      child: child,
    );

    return GestureDetector(
      onTap: onTap,
      child: body,
    );
  }
}

// ─── Premium Wallet Card (Stark Edition) ─────────────────────────────────────
class PremiumWalletCard extends StatelessWidget {
  final String balance;
  final String cardNum;
  final String expDate;
  final String holderName;
  final LinearGradient? gradient;
  final String platform;
  final VoidCallback? onTap;
  final String? address;

  const PremiumWalletCard({
    super.key,
    required this.balance,
    required this.cardNum,
    required this.expDate,
    required this.holderName,
    this.address,
    this.gradient,
    this.platform = 'propay',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.6,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPlatformIcon(platform, isDark),
                  Text('.... .... .... ${cardNum.length > 4 ? cardNum.substring(cardNum.length - 4) : cardNum}', 
                      style: GoogleFonts.inter(
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          letterSpacing: 2,
                          fontSize: 12,
                          fontWeight: FontWeight.w900)),
                ],
              ),
              const Spacer(),
              Text('AVAILABLE BALANCE',
                  style: GoogleFonts.inter(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text(balance,
                  style: GoogleFonts.inter(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1)),
              const SizedBox(height: 12),
              if (address != null) 
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: address!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Address copied to clipboard'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(address!, 
                            style: GoogleFonts.inter(
                                color: AppColors.primary, 
                                fontSize: 10, 
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1)),
                        const SizedBox(width: 8),
                        Icon(Icons.copy_rounded, color: isDark ? Colors.white70 : Colors.black54, size: 10),
                      ],
                    ),
                  ),
                ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CARD HOLDER',
                          style: GoogleFonts.inter(
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      Text(holderName.toUpperCase(),
                          style: GoogleFonts.inter(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('EXPIRY',
                          style: GoogleFonts.inter(
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      Text(expDate,
                          style: GoogleFonts.inter(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformIcon(String platform, bool isDark) {
    final iconColor = isDark ? Colors.white : Colors.black;
    switch (platform.toLowerCase()) {
      case 'stripe':
        return Row(
          children: [
            Icon(Icons.payments_rounded, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Text('STRIPE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: iconColor, letterSpacing: 1)),
          ],
        );
      case 'chapa':
        return Text('CHAPA', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: iconColor, letterSpacing: 1));
      default:
        return Icon(Icons.account_balance_wallet_rounded, color: iconColor, size: 20);
    }
  }
}

// ─── Adaptive Quick Action Button (Stark) ─────────────────────────────────────────────
class QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final LinearGradient? gradient;

  const QuickActionBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
            ),
            child: Icon(
              icon,
              color: color ?? (isDark ? Colors.white : Colors.black),
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Adaptive Transaction Tile (Stark) ──────────────────────────────────────────────
class TransactionTile extends ConsumerWidget {
  final String name;
  final String subtitle;
  final double amount;
  final bool isSent;
  final String? initials;
  final IconData? icon;
  final String? platform;

  const TransactionTile({
    super.key,
    required this.name,
    required this.subtitle,
    required this.amount,
    required this.isSent,
    this.initials,
    this.icon,
    this.platform,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefCurrency = ref.watch(displayCurrencyProvider);
    
    final convertedAmount = CurrencyConverter.convert(
      amount: amount,
      from: platform?.toLowerCase() == 'chapa' ? 'ETB' : 'USD',
      to: prefCurrency,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
            ),
            child: Center(
              child: icon != null 
                ? Icon(icon, color: isDark ? Colors.white : Colors.black, size: 18)
                : Text(
                    initials ?? (name.isNotEmpty ? name[0].toUpperCase() : 'T'),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isSent ? '-' : '+'}${Formatters.currency(convertedAmount, symbol: CurrencyConverter.getSymbol(prefCurrency))}',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: isSent ? AppColors.primary : (isDark ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Adaptive Section Header (Stark) ──────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            letterSpacing: 2.5,
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: 1,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Adaptive Status Badge (Stark) ──────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ─── Premium Stark Button ─────────────────────────────────────────────────
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final LinearGradient? gradient;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.gradient,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
            ],
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
