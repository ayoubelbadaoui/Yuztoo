import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';

/// Gold-bordered info summary box: icon + title + description text.
class FideliteInfoBox extends StatelessWidget {
  const FideliteInfoBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MerchantColors.gold, width: 1),
        ),
        child: Column(
          children: [
            // ── icon box ──
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: MerchantColors.gold, width: 2),
              ),
              child: const Icon(
                Icons.info_outline,
                color: MerchantColors.gold,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),

            // ── title ──
            Text(
              'Votre offre fidélité',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: MerchantColors.gold,
              ),
            ),
            const SizedBox(height: 8),

            // ── description ──
            Text(
              'Bon d\'achat équivalant à 10% de vos dépenses après '
              '10 passages en caisse validés de plus de 50€',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: MerchantColors.textLightGrey,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

