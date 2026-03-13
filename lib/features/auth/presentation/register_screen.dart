import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/config/constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/cards.dart';
import 'auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePass = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).signUp(
          email: _emailCtrl.text,
          password: _passCtrl.text,
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
        );
    if (!ok && mounted) {
      final err = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Registration failed'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Create Account', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (isDark) ...[
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
            ),
          ],
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Join ProPay',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Get started with the most advanced digital wallet.',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 40),

                    _buildTextField(
                      controller: _nameCtrl,
                      label: 'Full Name',
                      hint: 'John Doe',
                      icon: Icons.person_outline_rounded,
                      validator: Validators.required,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _emailCtrl,
                      label: 'Email',
                      hint: 'your@email.com',
                      icon: Icons.alternate_email_rounded,
                      validator: Validators.email,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _phoneCtrl,
                      label: 'Phone Number',
                      hint: '+251...',
                      icon: Icons.phone_outlined,
                      validator: Validators.phone,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _passCtrl,
                      label: 'Password',
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      validator: Validators.password,
                      obscureText: _obscurePass,
                      isDark: isDark,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _confirmPassCtrl,
                      label: 'Confirm Password',
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Confirm your password';
                        if (v != _passCtrl.text) return 'Passwords do not match';
                        return null;
                      },
                      obscureText: true,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 48),
                    if (authState.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      GradientButton(
                        label: 'Create Account',
                        onPressed: _submit,
                        gradient: AppColors.primaryGradient,
                      ),
                    
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: GoogleFonts.inter(
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'Log In',
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          style: GoogleFonts.inter(
              color: isDark ? Colors.white : AppColors.lightTextPrimary),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isDark ? AppColors.darkCard : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.lightDivider,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.lightDivider,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}
