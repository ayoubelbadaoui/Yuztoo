import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';

/// Profile avatar (gold-bordered circle) + user info text.
class ProfileAvatarSection extends StatelessWidget {
  const ProfileAvatarSection({super.key});

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── avatar circle ──
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MerchantColors.navyCard,
              border: Border.all(color: MerchantColors.gold, width: 3),
            ),
            child: const Center(
              child: Icon(
                Icons.person,
                color: MerchantColors.gold,
                size: 48,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // ── info lines ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mr Pascal Guyomar',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                _infoLine('42 ans'),
                _infoLine('46 grande rue'),
                _infoLine('90130 Petit-Croix'),
                _infoLine('Tel: 0609526511'),
                _infoLine('Pascal.guyomar@gmail.com'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 13,
          color: MerchantColors.textGrey,
          height: 1.5,
        ),
      ),
    );
  }
}

