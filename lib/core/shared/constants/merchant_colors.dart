import 'package:flutter/material.dart';

/// Shared color palette for all dark merchant screens
/// (Rappels, Promotions, Notifications auto., etc.)
///
/// Sourced from design.md.
abstract final class MerchantColors {
  static const bgMain = Color(0xFF0E2A44);
  static const bgHeader = Color(0xFF0B1F33);
  static const gold = Color(0xFFD4A017);
  static const goldLight = Color(0xFFD4AF37);
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

  /// Canonical fill for ALL text inputs on dark navy surfaces.
  ///
  /// Why this exists:
  /// - The codebase historically picked between [bgHeader] (too dark,
  ///   inputs disappear into the scaffold), [bgMain] (same as the
  ///   scaffold, no contrast), and ad-hoc hex values like `0xFF0B2540`,
  ///   producing inputs whose blue varied screen-to-screen — which is
  ///   exactly the "le bleu des champs de saisie doit être plus clair
  ///   et homogénéiser" feedback we received.
  /// - Aliased to [navyCard] so inputs read as a raised surface above
  ///   [bgMain] / [bgHeader], with a single source of truth.
  ///
  /// Use [inputFill] (NOT [bgHeader] / [bgMain]) for `TextField` /
  /// `TextFormField` `fillColor` on every dark merchant or signup
  /// surface. New input designs MUST resolve to this token.
  static const Color inputFill = navyCard;

  /// Use on dark merchant surfaces so [TextField] / [TextFormField] do not keep
  /// the app theme’s pale fill behind a light [TextStyle] (unreadable text).
  static InputDecoration inputDecorationOnDarkSurface(
    InputDecoration base,
  ) {
    return base.copyWith(
      filled: true,
      fillColor: Colors.transparent,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
    );
  }
}

