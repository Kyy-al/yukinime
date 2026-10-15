import 'package:flutter/material.dart';

/// YUKINIME Design System — Color Tokens
/// Midnight Anime Experience theme
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF080D18);
  static const Color backgroundSecondary = Color(0xFF0C1423);
  static const Color surface = Color(0xFF111B2E);
  static const Color surfaceElevated = Color(0xFF17243A);

  // Primary
  static const Color primary = Color(0xFF2878F0);
  static const Color accent = Color(0xFF63B3FF);
  static const Color primaryLight = Color(0xFF4A94F7);

  // Text
  static const Color textPrimary = Color(0xFFF4F7FC);
  static const Color textSecondary = Color(0xFF9AA9BF);
  static const Color textTertiary = Color(0xFF6B7A8D);

  // Border
  static const Color border = Color(0xFF26354D);
  static const Color borderLight = Color(0xFF1E2D42);

  // Status
  static const Color error = Color(0xFFFF5252);
  static const Color errorDark = Color(0xFF8B2020);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2878F0), Color(0xFF63B3FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF111B2E), Color(0xFF0C1423)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [
      Color(0xFF111B2E),
      Color(0xFF17243A),
      Color(0xFF111B2E),
    ],
  );
}
