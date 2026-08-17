import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Ocean Blue
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color lightBlue = Color(0xFFEFF6FF);

  // Teal
  static const Color tealPrimary = Color(0xFF0D9488);
  static const Color tealDark = Color(0xFF0F766E);
  static const Color tealAccent = Color(0xFF14B8A6);
  static const Color tealLight = Color(0xFFF0FDFA);

  // Indigo
  static const Color indigoPrimary = Color(0xFF4F46E5);
  static const Color indigoDark = Color(0xFF3730A3);
  static const Color indigoAccent = Color(0xFF6366F1);
  static const Color indigoLight = Color(0xFFEEF2FF);

  // Royal Navy — default premium palette
  static const Color royalPrimary = Color(0xFF1A3352);
  static const Color royalDark = Color(0xFF0C1B2E);
  static const Color royalMid = Color(0xFF2A4A73);
  static const Color royalAccent = Color(0xFF3D6A99);
  static const Color royalGold = Color(0xFFD4AF37);
  static const Color royalGoldDark = Color(0xFFB8942E);
  static const Color royalGoldLight = Color(0xFFFFF8E7);
  static const Color royalSky = Color(0xFF5B9BD5);
  static const Color royalLight = Color(0xFFF4F7FB);
  static const Color royalSurface = Color(0xFFE8EEF5);

  /// Light → full dark blue (animated shimmer between both sets).
  static const List<Color> animatedGradientColors = [
    // Light blues
    Color(0xFF7EC0FF),
    Color(0xFF5BAEFF),
    Color(0xFF3B8BFF),
    // Dark blues (full dark end)
    Color(0xFF2563EB),
    Color(0xFF1A6FE8),
    Color(0xFF1558C7),
    Color(0xFF1E40AF),
    Color(0xFF1A3352),
  ];

  static const Color surfaceWhite = Color(0xFFF8FAFC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color successGreen = Color(0xFF059669);
  static const Color warningOrange = Color(0xFFD97706);
  static const Color errorRed = Color(0xFFDC2626);
  static const Color scannerLine = Color(0xFF5B9BD5);
  static const Color edgeOverlay = Color(0xFF22C55E);

  // Home mockup accent colors
  static const Color scanBlue = Color(0xFF2B7FFF);
  static const Color scanBlueDark = Color(0xFF1A5FD4);
  static const Color toolGreen = Color(0xFF22C55E);
  static const Color toolPurple = Color(0xFF8B5CF6);
  static const Color toolOrange = Color(0xFFF97316);
  static const Color toolYellow = Color(0xFFEAB308);
  static const Color toolRed = Color(0xFFEF4444);

  /// Premium Royal Navy gradient for headers & hero sections.
  static const List<Color> royalPremiumGradient = [
    royalPrimary,
    royalMid,
    royalDark,
  ];

  static const List<Color> royalGoldGradient = [
    royalGold,
    royalGoldDark,
  ];
}

enum AppAccent { ocean, teal, indigo, royal }

extension AppAccentColors on AppAccent {
  Color get primary => switch (this) {
        AppAccent.ocean => AppColors.primaryBlue,
        AppAccent.teal => AppColors.tealPrimary,
        AppAccent.indigo => AppColors.indigoPrimary,
        AppAccent.royal => AppColors.royalPrimary,
      };

  Color get dark => switch (this) {
        AppAccent.ocean => AppColors.primaryDark,
        AppAccent.teal => AppColors.tealDark,
        AppAccent.indigo => AppColors.indigoDark,
        AppAccent.royal => AppColors.royalDark,
      };

  Color get accent => switch (this) {
        AppAccent.ocean => AppColors.accentBlue,
        AppAccent.teal => AppColors.tealAccent,
        AppAccent.indigo => AppColors.indigoAccent,
        AppAccent.royal => AppColors.royalSky,
      };

  Color get highlight => switch (this) {
        AppAccent.ocean => AppColors.accentBlue,
        AppAccent.teal => AppColors.tealAccent,
        AppAccent.indigo => AppColors.indigoAccent,
        AppAccent.royal => AppColors.royalSky,
      };

  Color get light => switch (this) {
        AppAccent.ocean => AppColors.lightBlue,
        AppAccent.teal => AppColors.tealLight,
        AppAccent.indigo => AppColors.indigoLight,
        AppAccent.royal => AppColors.royalLight,
      };

  String get label => switch (this) {
        AppAccent.ocean => 'Ocean Blue',
        AppAccent.teal => 'Fresh Teal',
        AppAccent.indigo => 'Modern Indigo',
        AppAccent.royal => 'Royal Navy',
      };
}
