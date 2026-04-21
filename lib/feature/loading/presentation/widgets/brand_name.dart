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
    return Column(
      children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: 'Yuz',
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: MerchantColors.textWhite,
                letterSpacing: 1.0,
              ),
            ),
            TextSpan(
              text: 'too',
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: MerchantColors.gold,
                letterSpacing: 1.0,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 6),
        Text(
          'Vos commerces. Votre fidélité.',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: MerchantColors.textGrey,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

