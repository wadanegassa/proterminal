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
  final MobileScannerController _cameraCtrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    detectionTimeoutMs: 1000,
    formats: [BarcodeFormat.qrCode],
    returnImage: false,
  );
  bool _isProcessing = false;
  bool _torchOn = false;

  late Rect _scanWindow;

  @override
  void initState() {
    super.initState();
    _scanWindow = Rect.fromCenter(
      center: const Offset(0.5, 0.45),
      width: 0.7,
      height: 0.35,
    );
  }

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
    } else if (qrState.detectedUserId != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SendMoneyScreen(prefilledUserId: qrState.detectedUserId),
        ),
      );
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
      content: Text(msg.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 2,
                  decoration: BoxDecoration(
                      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 32),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                    border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                    borderRadius: BorderRadius.circular(4)),
                child:
                    Icon(Icons.storefront_rounded, color: isDark ? Colors.white : Colors.black, size: 32),
              ),
              const SizedBox(height: 24),
              Text(merchant.businessName.toUpperCase(),
                  style: GoogleFonts.inter(
                      fontSize: 16, 
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(merchant.name.toUpperCase(),
                  style: GoogleFonts.inter(
                      fontSize: 10, 
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      letterSpacing: 2)),
              const SizedBox(height: 32),
              if (preAmount == null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                    border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 48, 
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -1),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('\$', style: GoogleFonts.inter(
                              fontSize: 24, 
                              fontWeight: FontWeight.w900, 
                              color: AppColors.primary)),
                          ],
                        ),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ] else ...[
                Text(
                  Formatters.currency(preAmount),
                  style: GoogleFonts.inter(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -1),
                ),
                const SizedBox(height: 12),
                const StatusBadge(label: 'VERIFIED PAYMENT', color: AppColors.primary),
                const SizedBox(height: 32),
              ],
              GradientButton(
                label: 'INSTAT PAY AUTHORIZE',
                icon: Icons.shield_rounded,
                onPressed: () async {
                  final amount = preAmount ??
                      double.tryParse(amountCtrl.text);
                  if (amount == null || amount <= 0) return;

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
                child: Text('CANCEL SESSION', style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
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
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), 
          side: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.darkBackground,
                  border: Border.all(color: AppColors.primary),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.primary, size: 40),
              ),
              const SizedBox(height: 32),
              Text('PAYMENT AUTHORIZED',
                  style: GoogleFonts.inter(
                      fontSize: 18, 
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: 1)),
              const SizedBox(height: 12),
              Text('SUCCESSFULLY TRANSFERRED ${Formatters.currency(amount)} TO ${merchantName.toUpperCase()}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    height: 1.5)),
              const SizedBox(height: 32),
              GradientButton(
                onPressed: () => Navigator.pop(context),
                label: 'CONTINUE',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        title: Text('SCANNER',
            style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 4)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              _cameraCtrl.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
            icon: Icon(
              _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: isDark ? Colors.white : Colors.black,
              size: 20,
            ),
          ),
          IconButton(
            onPressed: () => _cameraCtrl.switchCamera(),
            icon: Icon(Icons.flip_camera_android_rounded,
                color: isDark ? Colors.white : Colors.black, size: 20),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraCtrl,
            scanWindow: _scanWindow,
            onDetect: _onDetect,
          ),
          CustomPaint(
            painter: _ScanOverlayPainter(),
            child: const SizedBox.expand(),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: const Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppColors.primary)),
              ),
            ),
          Positioned(
            bottom: 80,
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
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_note_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
                      const SizedBox(width: 12),
                      Text('MANUAL IDENTIFIER ENTRY',
                          style: GoogleFonts.inter(
                              color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
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
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.7);
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
          ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4))),
      ),
      paint,
    );

    final borderPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    const cLen = 30.0;
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
