import 'package:flutter/material.dart';

/// Color constants for storefront screen
class StorefrontColors {
  StorefrontColors._();

  // Primary colors
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color navyDark = Color(0xFF0B162C);
  static const Color navyLight = Color(0xFF1A2B4D);
  static const Color creamLight = Color(0xFFFDFBF7);
  static const Color backgroundLight = Color(0xFFFDFBF7);
  static const Color backgroundDark = Color(0xFF0B162C);

  // Text colors
  static const Color textPrimary = Color(0xFF1E293B); // slate-800
  static const Color textSecondary = Color(0xFF64748B); // slate-500
  static const Color textTertiary = Color(0xFF94A3B8); // slate-400
  static const Color textLight = Color(0xFFF1F5F9); // slate-100

  // Border colors
  static const Color borderLight = Color(0x1A000000);
  static const Color borderDark = Color(0x0DFFFFFF);

  // Card colors
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0x661A2B4D); // navy-light with 40% opacity

  // Status colors
  static const Color successGreen = Color(0xFF22C55E); // green-500
}

/// Gold gradient colors for borders
class GoldGradient {
  static const List<Color> colors = [
    Color(0xFFBF953F),
    Color(0xFFFCF6BA),
    Color(0xFFB38728),
    Color(0xFFFBF5B7),
    Color(0xFFAA771C),
  ];
}

