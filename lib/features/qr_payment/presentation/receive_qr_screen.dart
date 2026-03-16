import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/config/constants.dart';
import '../../wallet/presentation/wallet_provider.dart';
import '../../../core/utils/formatters.dart';

class ReceiveQRScreen extends ConsumerWidget {
  const ReceiveQRScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userModelProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen for real-time payments
    ref.listen(receivedTransactionsProvider, (previous, next) {
      if (next.valueOrNull != null && previous?.valueOrNull != null) {
        if (next.value!.length > previous!.value!.length) {
          final latestTx = next.value!.first;
          _showPaymentSuccess(context, latestTx.amount, latestTx.senderName ?? 'Customer', isDark);
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'OFFICE POS TERMINAL',
                style: GoogleFonts.inter(
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Receive Payments',
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 48),
              
              // Terminal Frame
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    if (user != null)
                      QrImageView(
                        data: user.uid,
                        version: QrVersions.auto,
                        size: 240.0,
                        eyeStyle: QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        dataModuleStyle: QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      )
                    else
                      const CircularProgressIndicator(),
                    
                    const SizedBox(height: 32),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        user?.uid.toUpperCase() ?? 'ID UNKNOWN',
                        style: GoogleFonts.jetBrainsMono(
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'TERMINAL ACTIVE & LISTENING',
                    style: GoogleFonts.inter(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentSuccess(BuildContext context, double amount, String sender, bool isDark) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            border: Border.all(color: AppColors.primary, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 64),
              const SizedBox(height: 24),
              Text(
                'PAYMENT RECEIVED',
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${Formatters.currency(amount)} from $sender',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
