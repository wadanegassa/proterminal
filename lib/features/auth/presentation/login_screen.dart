import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/config/constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/cards.dart';
import 'auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authProvider.notifier)
        .signIn(_emailCtrl.text, _passCtrl.text);
    if (!ok && mounted) {
      final err = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Login failed'),
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
      body: Stack(
        children: [
          // Background Gradient Ornaments for Dark Mode
          if (isDark) ...[
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withValues(alpha: 0.1),
                ),
              ),
            ),
          ],
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  // App Icon
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, 
                        color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Welcome Back',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to access your premium features.',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 48),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email Field
                        _buildTextField(
                          controller: _emailCtrl,
                          label: 'Email',
                          hint: 'your@email.com',
                          icon: Icons.alternate_email_rounded,
                          validator: Validators.email,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 24),
                        // Password Field
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
                        
                        const SizedBox(height: 16),
                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: Text(
                              'Forgot Password?',
                              style: GoogleFonts.inter(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                        // Submit Button
                        if (authState.isLoading)
                          const CircularProgressIndicator()
                        else
                          GradientButton(
                            label: 'Log In',
                            onPressed: _submit,
                            gradient: AppColors.primaryGradient,
                          ),

                        const SizedBox(height: 32),
                        // Register Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: GoogleFonts.inter(
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RegisterScreen())),
                              child: Text(
                                'Sign Up',
                                style: GoogleFonts.inter(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
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
