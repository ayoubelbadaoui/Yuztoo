import 'package:flutter/material.dart';

/// Shared color palette for all dark merchant screens
/// (Rappels, Promotions, Notifications auto., etc.)
///
/// Sourced from design.md.
abstract final class MerchantColors {
  static const bgMain = Color(0xFF0E2A44);
  static const bgHeader = Color(0xFF0B1F33);
  static const gold = Color(0xFFD4A017);
  static const navyCard = Color(0xFF1A2B4D);
  static const cream = Color(0xFFE8D5B7);
  static const textGrey = Color(0xFF999999);
  static const textLightGrey = Color(0xFFCCCCCC);
  static const textWhite = Colors.white;

  /// Border alpha values
  static const goldBorderAlpha = 0.1;
  static const goldBorderStronger = 0.25;

  /// Common dark background used for inputs / dark card overlays
  static const darkOverlay = Color(0xFF0B162C);
}

