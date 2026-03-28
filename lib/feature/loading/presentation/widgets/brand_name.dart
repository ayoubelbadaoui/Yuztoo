import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';

/// Brand text: "Yuz" (white w600) + "too" (gold w700).
///
/// CSS: font-size:28px, Outfit, letter-spacing 0.5px.
class BrandName extends StatelessWidget {
  const BrandName({super.key});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: [
        TextSpan(
          text: 'Yuz',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: MerchantColors.textWhite,
            letterSpacing: 0.5,
          ),
        ),
        TextSpan(
          text: 'too',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: MerchantColors.gold,
            letterSpacing: 0.5,
          ),
        ),
      ]),
    );
  }
}

