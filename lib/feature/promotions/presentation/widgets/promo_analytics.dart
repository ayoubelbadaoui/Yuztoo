import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../domain/entities/promotion.dart';

/// Analytics section — shows real promotion metrics only.
class PromoAnalytics extends StatelessWidget {
  const PromoAnalytics({super.key, required this.promotions});

  final List<Promotion> promotions;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final totalViews =
        promotions.fold<int>(0, (sum, p) => sum + p.viewCount);
    final activeCount =
        promotions.where((p) => p.isOnline && p.dateTo.isAfter(now)).length;
    final totalCount = promotions.length;
    final totalEstimatedReach =
        promotions.fold<int>(0, (sum, p) => sum + p.estimatedReach);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Impact de vos promotions',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
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
                _statRow(
                  icon: Icons.local_offer_outlined,
                  label: 'Promotions actives',
                  value: '$activeCount / $totalCount',
                ),
                const SizedBox(height: 10),
                _statRow(
                  icon: Icons.visibility_outlined,
                  label: 'Vues totales',
                  value: '$totalViews',
                ),
                const SizedBox(height: 10),
                _statRow(
                  icon: Icons.people_outline_rounded,
                  label: 'Clients ciblés',
                  value: totalEstimatedReach > 0
                      ? '$totalEstimatedReach'
                      : '—',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon,
            size: 16,
            color: MerchantColors.gold.withValues(alpha: 0.85)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: MerchantColors.textLightGrey,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
