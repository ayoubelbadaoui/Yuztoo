import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';

/// Gold-bordered card box with icon and "Présentez votre carte Yuztoo".
class YuztooCardBox extends StatelessWidget {
  const YuztooCardBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
            width: 1,
          ),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
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
                Icons.credit_card,
                color: MerchantColors.gold,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),

            // ── text ──
            Text(
              'Présentez votre carte\nYuztoo',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: MerchantColors.textLightGrey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

