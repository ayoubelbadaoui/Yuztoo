import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';

/// Gold-bordered info box with "Vos clients vous appartiennent…" text.
class ClientInfoBox extends StatelessWidget {
  const ClientInfoBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MerchantColors.gold, width: 1),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Vos clients vous appartiennent désormais. ',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: MerchantColors.textLightGrey,
                  height: 1.6,
                ),
              ),
              TextSpan(
                text: 'Yuztoo',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MerchantColors.gold,
                  height: 1.6,
                ),
              ),
              TextSpan(
                text: ' vous aide à les garder',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: MerchantColors.textLightGrey,
                  height: 1.6,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

