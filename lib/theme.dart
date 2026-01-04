import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class YColors {
  static const background = Color(0xFFFFFFFF);
  static const primary = Color(0xFF232A34);
  static const secondary = Color(0xFFC28A1B);
  static const accent = Color(0xFFF5F5F5);
  static const muted = Color(0xFF717182);
  static const border = Color(0x1A000000);
  static const card = Color(0xFFFFFFFF);
  static const destructive = Color(0xFFD4183D);
}

ThemeData buildTheme() {
  final textTheme = GoogleFonts.interTextTheme();

  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: YColors.secondary,
      primary: YColors.primary,
      secondary: YColors.secondary,
      surface: YColors.background,
      error: YColors.destructive,
    ),
    scaffoldBackgroundColor: YColors.background,
    textTheme: textTheme.copyWith(
      headlineLarge:
          textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w600),
      headlineMedium:
          textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
      headlineSmall:
          textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
      bodyMedium: textTheme.bodyMedium?.copyWith(color: YColors.primary),
      bodySmall: textTheme.bodySmall?.copyWith(color: YColors.muted),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: YColors.background,
      foregroundColor: YColors.primary,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: YColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: YColors.border),
      ),
      margin: EdgeInsets.zero,
      elevation: 0,
      shadowColor: Colors.black12,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: YColors.secondary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: YColors.primary,
        side: const BorderSide(color: YColors.border),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF3F3F5),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: YColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: YColors.secondary, width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: YColors.border),
      ),
      hintStyle: const TextStyle(color: YColors.muted),
      labelStyle:
          const TextStyle(color: YColors.primary, fontWeight: FontWeight.w500),
    ),
    dividerTheme: const DividerThemeData(color: YColors.border, thickness: 1),
  );
}
