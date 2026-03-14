import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/config/constants.dart';
import '../presentation/wallet_provider.dart';

class UserQrScreen extends ConsumerWidget {
  const UserQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userModelProvider);
    final user = userAsync.valueOrNull;

    if (user == null) return const SizedBox.shrink();

    // Standardized ProPay URI
    final qrData = 'propay://user?uid=${user.uid}&email=${user.email}&name=${Uri.encodeComponent(user.name)}';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('IDENTIFICATION QR', style: GoogleFonts.inter(
          fontWeight: FontWeight.w900, 
          fontSize: 12, 
          letterSpacing: 2,
          color: isDark ? Colors.white : Colors.black,
        )),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      children: [
                        Text(
                          user.name.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.email.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 200.0,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.black,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          'SYSTEM DESIGNATION: AUTHORIZED USER\nSCAN TO INITIATE TRANSACTION',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            height: 1.6,
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.share_rounded, size: 20),
                      label: Text('SHARE IDENTIFIER', style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                        foregroundColor: isDark ? Colors.white : Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
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
