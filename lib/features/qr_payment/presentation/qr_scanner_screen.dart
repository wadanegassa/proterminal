import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/config/constants.dart';
import '../../wallet/presentation/wallet_provider.dart';
import 'qr_provider.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cards.dart';
import '../../wallet/presentation/send_money_screen.dart';
import '../../../core/utils/biometric_service.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  final MobileScannerController _cameraCtrl = MobileScannerController();
  bool _isProcessing = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _cameraCtrl.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    setState(() => _isProcessing = true);
    _cameraCtrl.stop();

    final qrSvc = ref.read(qrServiceProvider);
    if (qrSvc.isValidQR(raw)) {
      await ref.read(qrProvider.notifier).processCode(raw);
      final qrState = ref.read(qrProvider);
      if (qrState.detectedMerchant != null && mounted) {
        _showPaymentSheet(raw);
      } else if (mounted) {
        _showError(qrState.error ?? 'Invalid QR Code');
      }
    } else {
      _showError('Not a valid ProPay QR Code');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    _cameraCtrl.start();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showPaymentSheet(String rawCode) {
    final qrState = ref.read(qrProvider);
    final merchant = qrState.detectedMerchant!;
    final preAmount = qrState.amount;
    final amountCtrl = TextEditingController(
        text: preAmount != null ? preAmount.toStringAsFixed(2) : '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 24),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    gradient: AppColors.secondaryGradient,
                    borderRadius: BorderRadius.circular(20)),
                child:
                    const Icon(Icons.storefront_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              Text(merchant.businessName,
                  style: GoogleFonts.inter(
                      fontSize: 20, 
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary)),
              Text(merchant.name,
                  style: GoogleFonts.inter(
                      fontSize: 14, 
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              const SizedBox(height: 24),
              if (preAmount == null) ...[
                TextField(
                  controller: amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 40, 
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefix: Text('\$ ',
                        style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                Text(
                  Formatters.currency(preAmount),
                  style: GoogleFonts.inter(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                const StatusBadge(label: 'Fixed Payment', color: AppColors.primary),
                const SizedBox(height: 24),
              ],
              GradientButton(
                label: 'Confirm Payment',
                icon: Icons.shield_rounded,
                gradient: AppColors.primaryGradient,
                onPressed: () async {
                  final amount = preAmount ??
                      double.tryParse(amountCtrl.text);
                  if (amount == null || amount <= 0) return;

                  // Biometric Check
                  final authenticated = await biometricService.authenticate(context);
                  if (!mounted || !authenticated) return;

                  Navigator.pop(context);
                  final ok = await ref
                      .read(walletProvider.notifier)
                      .payQR(merchant.id, amount);
                  if (mounted) {
                    if (ok) {
                      _showSuccessResult(amount, merchant.businessName);
                    } else {
                      _showError(ref.read(walletProvider).error ??
                          'Payment failed');
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _isProcessing = false);
                  _cameraCtrl.start();
                  ref.read(qrProvider.notifier).reset();
                },
                child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      if (_isProcessing) {
        setState(() => _isProcessing = false);
        _cameraCtrl.start();
        ref.read(qrProvider.notifier).reset();
      }
    });
  }

  void _showSuccessResult(double amount, String merchantName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              Text('Payment Sent!',
                  style: GoogleFonts.inter(
                      fontSize: 22, 
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary)),
              const SizedBox(height: 12),
              Text('You have successfully paid ${Formatters.currency(amount)} to $merchantName',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontSize: 14)),
              const SizedBox(height: 32),
              GradientButton(
                onPressed: () => Navigator.pop(context),
                label: 'Continue',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Payment Scanner',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            onPressed: () {
              _cameraCtrl.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
            icon: Icon(
              _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () => _cameraCtrl.switchCamera(),
            icon: const Icon(Icons.flip_camera_android_rounded,
                color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraCtrl,
            onDetect: _onDetect,
          ),
          // Adaptive Overlay
          CustomPaint(
            painter: _ScanOverlayPainter(),
            child: const SizedBox.expand(),
          ),
          // Processing status
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: const Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppColors.primary)),
              ),
            ),
          // Bottom Manual Entry
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SendMoneyScreen()));
                },
                child: GlassContainer(
                  borderRadius: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_note_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text('Enter ID Manually',
                          style: GoogleFonts.inter(
                              color: Colors.white, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.6);
    const rectSize = 250.0;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 40),
      width: rectSize,
      height: rectSize,
    );

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(30))),
      ),
      paint,
    );

    final borderPaint = Paint()
      ..shader = AppColors.primaryGradient.createShader(rect)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cLen = 40.0;
    final corners = [
      [rect.topLeft, const Offset(cLen, 0), const Offset(0, cLen)],
      [rect.topRight, const Offset(-cLen, 0), const Offset(0, cLen)],
      [rect.bottomLeft, const Offset(cLen, 0), const Offset(0, -cLen)],
      [rect.bottomRight, const Offset(-cLen, 0), const Offset(0, -cLen)],
    ];

    for (final c in corners) {
      final origin = c[0];
      final h = c[1];
      final v = c[2];
      canvas.drawLine(origin, origin + h, borderPaint);
      canvas.drawLine(origin, origin + v, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
