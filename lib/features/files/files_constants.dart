import 'package:flutter/material.dart';

class FilesConstants {
  FilesConstants._();

  static const Color background = Color(0xFFF7FAFF);
  static const Color navyText = Color(0xFF0F172A);
  static const Color greySubtitle = Color(0xFF64748B);
  static const Color accentBlue = Color(0xFF2B7FFF);
  static const Color chipBorder = Color(0xFFE8EDF3);
  static const Color cardBorder = Color(0xFFEEF2F7);

  static const double screenPadding = 20;
  static const double cardRadius = 16;

  static BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.04),
    blurRadius: 10,
    offset: const Offset(0, 4),
  );
}
