import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/merchant_colors.dart';

/// Text style for [SnackBar] content on dark merchant surfaces
/// ([MerchantColors.bgHeader], [bgMain], [navyCard]). The app [ThemeData]
/// uses dark body text for light scaffolds; without an explicit color,
/// inherited text on these backgrounds is effectively invisible.
TextStyle merchantSnackBarTextOnDark({FontWeight? fontWeight}) =>
    GoogleFonts.outfit(
      fontSize: 14,
      fontWeight: fontWeight ?? FontWeight.w500,
      color: Colors.white,
      height: 1.35,
    );

/// Text on [MerchantColors.gold] SnackBars — dark for contrast.
TextStyle merchantSnackBarTextOnGold({FontWeight? fontWeight}) =>
    GoogleFonts.outfit(
      fontSize: 14,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: MerchantColors.darkOverlay,
      height: 1.35,
    );

/// Text on red / orange SnackBars (errors, warnings).
TextStyle merchantSnackBarTextOnWarmAccent() => GoogleFonts.outfit(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Colors.white,
      height: 1.35,
    );

/// Shows an error snackbar with French styling
void showErrorSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}

/// Shows a success snackbar with French styling
void showSuccessSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}

