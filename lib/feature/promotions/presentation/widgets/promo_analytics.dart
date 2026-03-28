import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';

/// Analytics section – gold-bordered card with stats + upgrade button.
class PromoAnalytics extends StatelessWidget {
  const PromoAnalytics({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visualisez l\'impact de vos promotions',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // ── analytics box ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MerchantColors.navyCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderStronger),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _item('Nombre de clients ciblés X'),
                const SizedBox(height: 8),
                _item('Nombre d\'impression X'),
                const SizedBox(height: 8),
                _item('Nombre de vue X'),
                const SizedBox(height: 8),
                _item('Nombre de visite X'),
                const SizedBox(height: 8),
                _item('Nouveaux clients X'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── upgrade button (gold, same design language) ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: MerchantColors.gold,
                foregroundColor: MerchantColors.darkOverlay,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: Text(
                'Passez en Premium',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: MerchantColors.gold,
      ),
    );
  }
}
