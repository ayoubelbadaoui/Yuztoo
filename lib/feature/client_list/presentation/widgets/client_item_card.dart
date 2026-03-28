import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';

/// A single client row: avatar + name/subtitle + arrow action button.
class ClientItemCard extends StatelessWidget {
  const ClientItemCard({
    super.key,
    required this.name,
    required this.subtitle,
    this.onTap,
  });

  final String name;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
        child: Row(
          children: [
            // ── avatar ──
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MerchantColors.navyCard,
                border: Border.all(color: MerchantColors.gold, width: 2),
              ),
              child: const Icon(
                Icons.person,
                color: MerchantColors.gold,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),

            // ── name + subtitle ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: MerchantColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),

            // ── arrow action ──
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: MerchantColors.gold, width: 2),
              ),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.only(left: 3),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: MerchantColors.gold,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

