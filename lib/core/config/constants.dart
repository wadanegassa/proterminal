import 'package:flutter/material.dart';

class AppColors {
  // Shared Accents
  static const primary = Color(0xFF6366F1); // Indigo
  static const secondary = Color(0xFFF43F5E); // Rose
  static const accent = Color(0xFF10B981); // Emerald
  static const amber = Color(0xFFF59E0B);
  
  // Semantic
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);

  // Light Palette (Inspired by Image 1)
  static const lightBackground = Color(0xFFF1F5F9);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightTextPrimary = Color(0xFF0F172A);
  static const lightTextSecondary = Color(0xFF64748B);
  static const lightTextMuted = Color(0xFF94A3B8);
  static const lightDivider = Color(0xFFE2E8F0);
  static final lightGlass = Colors.white.withValues(alpha: 0.7);

  // Dark Palette (Inspired by Image 2 - Ginko)
  static const darkBackground = Color(0xFF000000); // Pure black for AMOLED
  static const darkSurface = Color(0xFF0B0E11);
  static const darkCard = Color(0xFF15191C);
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFF94A3B8);
  static const darkTextMuted = Color(0xFF64748B);
  static const darkDivider = Color(0xFF1E293B);
  static final darkGlass = Colors.white.withValues(alpha: 0.08);

  static const surface = lightSurface; // Default to light

  // Premium Gradients
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const secondaryGradient = LinearGradient(
    colors: [Color(0xFFF43F5E), Color(0xFFFB7185)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const sunsetGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const blueVioletGradient = LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const glassGradient = LinearGradient(
    colors: [Colors.white24, Colors.white10],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}
