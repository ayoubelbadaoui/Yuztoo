import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';

/// Search section: Mode Pro badge + search input + filter button.
class ClientSearchBar extends StatelessWidget {
  const ClientSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
          // ── Mode Pro badge ──
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: MerchantColors.gold, width: 2),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: MerchantColors.gold,
                  size: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mode Pro',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: MerchantColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // ── search input ──
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Rechercher',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: MerchantColors.textGrey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ── message button ──
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: MerchantColors.gold, width: 2),
            ),
            child: const Icon(
              Icons.mail_outline,
              color: MerchantColors.gold,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

