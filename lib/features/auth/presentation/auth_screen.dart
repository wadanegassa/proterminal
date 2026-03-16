import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/config/constants.dart';
import '../../../core/utils/validators.dart';
import 'auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  
  bool _obscurePass = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final ok = await ref.read(authProvider.notifier).signIn(
      _emailCtrl.text, 
      _passCtrl.text,
    );

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
          // ─── Background Grid ──────────────────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(
                color: isDark ? AppColors.darkGridColor : AppColors.lightGridColor,
              ),
            ),
          ),
          
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final h = constraints.maxHeight;
                final scale = (h / 750).clamp(0.6, 1.0);
                final headerGap = 48.0 * scale;
                final fieldGap = 12.0 * scale;

                return Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 8 * scale),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildHeader(isDark, scale),
                            SizedBox(height: headerGap),
                            Form(
                              key: _formKey,
                            child: Column(
                              children: [
                                _buildStarkTextField(
                                  controller: _emailCtrl,
                                  label: 'CORPORATE IDENTIFIER',
                                  hint: 'ID@COMPANY.COM',
                                  icon: Icons.alternate_email_rounded,
                                  validator: Validators.email,
                                  isDark: isDark,
                                  scale: scale,
                                ),
                                SizedBox(height: fieldGap),
                                _buildStarkTextField(
                                  controller: _passCtrl,
                                  label: 'ACCESS KEY',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  validator: Validators.password,
                                  obscureText: _obscurePass,
                                  isDark: isDark,
                                  scale: scale,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                      size: 18 * scale,
                                    ),
                                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                                  ),
                                ),
                                
                                SizedBox(height: 12 * scale),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () {},
                                    child: Text(
                                      'FORGOT ACCESS KEY?',
                                      style: GoogleFonts.inter(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 9 * scale,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: 48 * scale),
                                if (authState.isLoading)
                                  const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)))
                                else
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52 * scale,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        elevation: 0,
                                      ),
                                      onPressed: _submit,
                                      child: Text(
                                        'INITIALIZE SESSION',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13 * scale,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'PROADMIN TERMINAL',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 9 * scale,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            letterSpacing: 4 * scale,
          ),
        ),
        SizedBox(height: 12 * scale),
        Text(
          'ADMINISTRATOR\nACCESS',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 48 * scale,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: -2.0 * scale,
            height: 1.0,
          ),
        ),
        SizedBox(height: 16 * scale),
        Text(
          'Multi-platform business intelligence & revenue monitoring.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11 * scale,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }


  Widget _buildStarkTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    required double scale,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 6 * scale),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 8 * scale,
              fontWeight: FontWeight.w900,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              letterSpacing: 1.5 * scale,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            validator: validator,
            style: GoogleFonts.inter(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 12 * scale,
                fontWeight: FontWeight.w600),
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                fontWeight: FontWeight.w400,
                fontSize: 12 * scale,
              ),
              prefixIcon: Icon(icon, color: AppColors.primary, size: 16 * scale),
              suffixIcon: suffixIcon,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 16 * scale),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
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
