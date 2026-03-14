import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/config/constants.dart';
import 'wallet_provider.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cards.dart';
import '../domain/card_model.dart';
import '../../../core/utils/biometric_service.dart';

class SendMoneyScreen extends ConsumerStatefulWidget {
  final String? prefilledUserId;
  const SendMoneyScreen({super.key, this.prefilledUserId});

  @override
  ConsumerState<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends ConsumerState<SendMoneyScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _receiverCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _receiverName;
  bool _lookingUp = false;
  String _selectedChannel = 'email'; // Default to Email
  CardModel? _selectedSourceCard;

  final List<Map<String, dynamic>> _channels = [
    {'id': 'email', 'label': 'By Email', 'icon': Icons.email_rounded},
    {'id': 'phone', 'label': 'By Phone', 'icon': Icons.phone_rounded},
    {'id': 'card', 'label': 'By Card', 'icon': Icons.credit_card_rounded},
    {'id': 'address', 'label': 'By Address', 'icon': Icons.account_balance_wallet_rounded},
  ];

  late final AnimationController _animCtrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _animCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _anim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _animCtrl.forward();
    if (widget.prefilledUserId != null) {
      _receiverCtrl.text = widget.prefilledUserId!;
      _lookupUser(widget.prefilledUserId!);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _receiverCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookupUser(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _lookingUp = true);
    try {
      final svc = ref.read(firebaseServiceProvider);
      final users = await svc.searchUsers(query.trim());
      
      setState(() {
        // If it's a phone query and we have a match, or if there's exactly one search result
        if (users.isNotEmpty) {
          _receiverName = users.first.name;
          // If query was likely a phone number, we don't overwrite the controller
          // but if it was a name, we might want to set the controller to the ID later
          // For now, just show the found name
        } else {
          _receiverName = null;
        }
        _lookingUp = false;
      });
    } catch (_) {
      setState(() => _lookingUp = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final confirmed = await _showConfirmDialog();
    if (!mounted || !confirmed) return;

    // Biometric Check
    final authenticated = await biometricService.authenticate(context);
    if (!mounted || !authenticated) return;

    // Simulate Gateway Routing Delay if not internal
    if (_selectedChannel != 'propay') {
      setState(() {
        // Show loading in dialog/UI if we wanted, but walletProvider.transfer handles it for now
      });
      await Future.delayed(const Duration(seconds: 2)); // Simulate external API call
    }

    final ok = await ref
        .read(walletProvider.notifier)
        .transfer(
          _receiverCtrl.text.trim(), 
          double.parse(_amountCtrl.text),
          source: _selectedSourceCard,
        );

    if (!mounted) return;
    if (ok) {
      _showSuccess();
    } else {
      final err = ref.read(walletProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Transfer failed'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _showConfirmDialog() async {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Text('Confirm Payment',
                style: GoogleFonts.inter(fontWeight: FontWeight.w900)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('You are sending',
                    style: GoogleFonts.inter(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                const SizedBox(height: 12),
                Text(Formatters.currency(amount),
                    style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary)),
                const SizedBox(height: 12),
                Text('to',
                    style: GoogleFonts.inter(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                const SizedBox(height: 12),
                Text(
                    _receiverName ?? _receiverCtrl.text.trim(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800, 
                        fontSize: 18,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary)),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  child: const Text('Send Fund')),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccess() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 44),
              ),
              const SizedBox(height: 24),
              Text('Transfer successful!',
                  style: GoogleFonts.inter(
                      fontSize: 22, 
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary)),
              const SizedBox(height: 12),
              Text(
                  'Your payment of ${Formatters.currency(double.tryParse(_amountCtrl.text) ?? 0)} has been processed.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              const SizedBox(height: 32),
              GradientButton(
                onPressed: () {
                  Navigator.pop(context); 
                  Navigator.pop(context); 
                },
                label: 'Back to Wallet',
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
    final walletState = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('TRANSFER FUNDS',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w900, 
              fontSize: 14, 
              letterSpacing: 2,
              color: isDark ? Colors.white : Colors.black,
            )),
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
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 140),
            child: ScaleTransition(
              scale: _anim,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AMOUNT TO TRANSFER', style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    const SizedBox(height: 16),
                    
                    // ─── Amount Input (Stark Design) ─────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: Validators.amount,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                                fontSize: 64,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black,
                                letterSpacing: -2),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              hintStyle: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('\$', style: GoogleFonts.inter(
                                      fontSize: 32, 
                                      fontWeight: FontWeight.w900, 
                                      color: AppColors.primary)),
                                  ],
                                ),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // ─── Source & Recipient Section ──────────────────────────────────────
                    Text('PAYMENT DETAILS', style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Source Account Selection
                      Text('Source Account', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, letterSpacing: 2)),
                      const SizedBox(height: 12),
                      ref.watch(userCardsProvider).when(
                        data: (cards) {
                          if (cards.isEmpty) return const Text('NO ACTIVE ASSETS', style: TextStyle(color: AppColors.error));
                          if (_selectedSourceCard != null) {
                            try {
                              _selectedSourceCard = cards.firstWhere((c) => c.id == _selectedSourceCard!.id);
                            } catch (_) {
                              _selectedSourceCard = cards.first;
                            }
                          } else {
                            _selectedSourceCard = cards.first;
                          }
                          return Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                              border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButtonFormField<CardModel>(
                                isExpanded: true,
                                initialValue: _selectedSourceCard,
                                decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16)),
                                dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                items: cards.map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Row(
                                    children: [
                                      Icon(c.platform == 'stripe' ? Icons.payments_rounded : Icons.account_balance_wallet_rounded, 
                                           color: AppColors.primary, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text('${c.platform.toUpperCase()} [${c.cardNumber.substring(c.cardNumber.length - 4)}] (${Formatters.currency(c.balance)})', 
                                             overflow: TextOverflow.ellipsis,
                                             style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                                onChanged: (val) => setState(() => _selectedSourceCard = val),
                              ),
                            ),
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('Error loading accounts'),
                      ),
                      const SizedBox(height: 24),
                      
                      // Channel Selection
                      Text('Send Method', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, letterSpacing: 2)),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                          border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: _selectedChannel,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white24 : Colors.black26),
                          style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                          items: _channels.map((ch) => DropdownMenuItem(
                            value: ch['id'] as String,
                            child: Row(
                              children: [
                                Icon(ch['icon'] as IconData, color: AppColors.primary, size: 20),
                                const SizedBox(width: 12),
                                Text((ch['label'] as String).toUpperCase()),
                              ],
                            ),
                          )).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedChannel = val;
                                _receiverName = null;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // ID Input
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                          border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: TextFormField(
                          controller: _receiverCtrl,
                          validator: (v) => Validators.required(v, field: 'Recipient'),
                          onChanged: (v) {
                            if (v.length > 5 && (_selectedChannel == 'email' || _selectedChannel == 'phone')) {
                              _lookupUser(v);
                            }
                          },
                          style: GoogleFonts.inter(
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1),
                          decoration: InputDecoration(
                            hintText: _selectedChannel == 'email' ? 'IDENTIFIER: EMAIL' : 
                                      _selectedChannel == 'phone' ? 'IDENTIFIER: PHONE' : 
                                      _selectedChannel == 'card' ? 'IDENTIFIER: CARD' : 'IDENTIFIER: WALLET ADDRESS',
                            hintStyle: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white24 : Colors.black38),
                            prefixIcon: Icon(_selectedChannel == 'email' ? Icons.alternate_email_rounded : 
                                            _selectedChannel == 'phone' ? Icons.phone_android_rounded : 
                                            _selectedChannel == 'card' ? Icons.credit_card_rounded : Icons.account_balance_wallet_rounded,
                                color: AppColors.primary, size: 20),
                            suffixIcon: _lookingUp
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.primary)),
                                    ))
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          ),
                        ),
                      ),
                      if (_receiverName != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00C853), Color(0xFFB2FF59)]),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.success.withValues(alpha: 0.2),
                                      blurRadius: 10, offset: const Offset(0, 4))
                                  ],
                                ),
                                child: Icon(Icons.person_rounded, color: isDark ? Colors.white : Colors.black, size: 22),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_receiverName!,
                                        style: GoogleFonts.inter(
                                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16)),
                                    const SizedBox(height: 2),
                                    Text('Verified ProPay Recipient', 
                                        style: GoogleFonts.inter(
                                          color: AppColors.success, 
                                          fontSize: 12, 
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.verified_rounded, color: AppColors.success, size: 24),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Note Field
                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Add a note (optional)',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white24 : AppColors.lightTextMuted),
                    prefixIcon: const Icon(Icons.sticky_note_2_rounded, color: AppColors.primary, size: 20),
                    filled: true,
                    fillColor: isDark ? AppColors.darkCard : Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.lightDivider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 56),

                if (walletState.isLoading)
                  const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)))
                else
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: GradientButton(
                      label: 'Send Fund Instantly',
                      icon: Icons.bolt_rounded,
                      onPressed: _submit,
                    ),
                  ),
                const SizedBox(height: 60),
              ],
            ),
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
