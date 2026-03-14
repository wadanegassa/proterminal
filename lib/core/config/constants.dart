import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Stark Aesthetic)
  static const primary = Color(0xFFFF0000); // Stark Red
  static const secondary = Color(0xFFFFFFFF); // Pure White
  static const accent = Color(0xFF1A1A1A); // Stark Grey
  static const amber = Color(0xFFFFD700); 
  
  // Semantic
  static const success = Color(0xFF00FF00); 
  static const warning = Color(0xFFFF8800);
  static const error = Color(0xFFFF0000); // Same as primary for this theme

  // Light Palette (Stark White / Industrial)
  static const lightBackground = Color(0xFFFFFFFF); // Pure White
  static const lightSurface = Color(0xFFF8F8F8); 
  static const lightCard = Color(0xFFFFFFFF); 
  static const lightTextPrimary = Color(0xFF000000); 
  static const lightTextSecondary = Color(0xFF505050); 
  static const lightTextMuted = Color(0xFFAAAAAA);
  static const lightDivider = Color(0xFFE0E0E0);
  static final lightGlass = Colors.black.withValues(alpha: 0.05);

  // Dark Palette (Ultimate Premium Dark/OLED Black)
  static const darkBackground = Color(0xFF000000); // Pure OLED Black
  static const darkSurface = Color(0xFF080808); 
  static const darkCard = Color(0xFF0F0F0F); 
  static const darkTextPrimary = Color(0xFFFFFFFF); 
  static const darkTextSecondary = Color(0xFFA0A0A0); 
  static const darkTextMuted = Color(0xFF404040);
  static const darkDivider = Color(0xFF1A1A1A);
  static final darkGlass = Colors.white.withValues(alpha: 0.05);
  
  // Theme-aware Grid Colors
  static final lightGridColor = Colors.black.withValues(alpha: 0.03);
  static final darkGridColor = Colors.white.withValues(alpha: 0.03);
  static final starkGrid = darkGridColor; // Legacy support

  // Gradients for the "Stacked" Cards and Buttons (Neon & Dynamic)
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF007BFF)], // Cyan to Deep Blue
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cardGradientBlue = LinearGradient(
    colors: [Color(0xFF7C4DFF), Color(0xFF2979FF)], // Violet to Bright Blue
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cardGradientOrange = LinearGradient(
    colors: [Color(0xFFFF2A5F), Color(0xFFFF7043)], // Neon Pink to Orange
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const secondaryGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF1DE9B6)], // Cyan to Teal
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [Color(0xFFD500F9), Color(0xFF651FFF)], // Deep Purple to Neon Violet
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const sunsetGradient = LinearGradient(
    colors: [Color(0xFFFFAB00), Color(0xFFFF6D00)], // Neon Gold to Deep Orange
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkGradient = LinearGradient(
    colors: [Color(0xFF1A1A24), Color(0xFF0A0A0F)], // Premium metallic dark
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
