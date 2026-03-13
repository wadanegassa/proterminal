import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/config/constants.dart';
import 'wallet_provider.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cards.dart';
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
      final user = query.contains('@')
          ? null
          : await svc.getUserByPhone(query.trim());
      setState(() {
        _receiverName = user?.name;
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

    final ok = await ref
        .read(walletProvider.notifier)
        .transfer(_receiverCtrl.text.trim(), double.parse(_amountCtrl.text));

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
    final walletState = ref.watch(walletProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Send Money', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
        child: ScaleTransition(
          scale: _anim,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Wallet Summary
                SectionHeader(title: 'Payment Details'),
                const SizedBox(height: 12),
                
                // Amount Input
                ProCard(
                  isGlass: isDark,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text('Amount to Send',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: Validators.amount,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: GoogleFonts.inter(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                          prefix: Text('\$ ',
                              style: GoogleFonts.inter(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary)),
                          border: InputBorder.none,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Recipient Search
                SectionHeader(title: 'Recipient'),
                const SizedBox(height: 12),
                ProCard(
                  isGlass: isDark,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _receiverCtrl,
                        validator: (v) => Validators.required(v, field: 'Recipient'),
                        onChanged: (v) {
                          if (v.length > 5) _lookupUser(v);
                        },
                        style: GoogleFonts.inter(color: isDark ? Colors.white : AppColors.lightTextPrimary),
                        decoration: InputDecoration(
                          hintText: 'Phone number or Account ID',
                          prefixIcon: const Icon(Icons.person_search_rounded,
                              color: AppColors.primary, size: 20),
                          suffixIcon: _lookingUp
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.primary)),
                                  ))
                              : null,
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.lightSurface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                        ),
                      ),
                      if (_receiverName != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_rounded, color: AppColors.success, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_receiverName!,
                                        style: GoogleFonts.inter(
                                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15)),
                                    Text('Verified ProPay User', 
                                        style: GoogleFonts.inter(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Note
                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 1,
                  style: GoogleFonts.inter(color: isDark ? Colors.white : AppColors.lightTextPrimary),
                  decoration: InputDecoration(
                    hintText: 'What is this for? (optional)',
                    prefixIcon: const Icon(Icons.description_rounded, color: AppColors.primary, size: 20),
                    filled: true,
                    fillColor: isDark ? AppColors.darkCard : Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                if (walletState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  GradientButton(
                    label: 'Transfer Instantly',
                    icon: Icons.bolt_rounded,
                    onPressed: _submit,
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
