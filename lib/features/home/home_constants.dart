import 'package:flutter/material.dart';

/// Layout tokens for the premium home screen.
class HomeConstants {
  HomeConstants._();

  static const Color background = Color(0xFFF7FAFF);
  static const Color navyText = Color(0xFF0F172A);
  static const Color greySubtitle = Color(0xFF64748B);
  static const Color linkBlue = Color(0xFF2B7FFF);

  static const double screenPadding = 20;
  static const double sectionGap = 18;
  static const double bannerRadius = 22;
  static const double cardRadius = 18;
  static const double scanCardRadius = 22;

  static const List<Color> scanGradient = [
    Color(0xFF3B8BFF),
    Color(0xFF1A6FE8),
    Color(0xFF1558C7),
  ];

  static const List<Color> proGradient = [
    Color(0xFF3B8BFF),
    Color(0xFF2563EB),
  ];

  static BoxShadow softShadow({double blur = 16, double y = 6, double opacity = 0.08}) {
    return BoxShadow(
      color: Colors.black.withValues(alpha: opacity),
      blurRadius: blur,
      offset: Offset(0, y),
    );
  }
}
