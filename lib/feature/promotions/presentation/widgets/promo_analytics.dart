import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../domain/entities/promotion.dart';

/// Analytics section — shows real view data plus locked premium metrics.
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

          // ── real stats ──
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
                  locked: false,
                ),
                const SizedBox(height: 10),
                _statRow(
                  icon: Icons.visibility_outlined,
                  label: 'Vues totales',
                  value: '$totalViews',
                  locked: false,
                ),
                const SizedBox(height: 10),
                _statRow(
                  icon: Icons.people_outline_rounded,
                  label: 'Clients ciblés',
                  value: totalEstimatedReach > 0
                      ? '$totalEstimatedReach'
                      : '—',
                  locked: false,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                    height: 1,
                    color: Color(0xFF2A3A4C),
                  ),
                ),
                _statRow(
                  icon: Icons.ads_click_outlined,
                  label: 'Impressions',
                  value: '—',
                  locked: true,
                ),
                const SizedBox(height: 10),
                _statRow(
                  icon: Icons.touch_app_outlined,
                  label: 'Visites',
                  value: '—',
                  locked: true,
                ),
                const SizedBox(height: 10),
                _statRow(
                  icon: Icons.person_add_outlined,
                  label: 'Nouveaux clients',
                  value: '—',
                  locked: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── upgrade CTA ──
          Builder(
            builder: (ctx) => TextButton(
              onPressed: () {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Bientôt disponible.',
                      style: GoogleFonts.outfit(),
                    ),
                    backgroundColor: MerchantColors.navyCard,
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 0),
                backgroundColor:
                    MerchantColors.gold.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: MerchantColors.gold
                        .withValues(alpha: MerchantColors.goldBorderStronger),
                  ),
                ),
              ),
              child: Text(
                'Statistiques avancées — Bientôt disponible',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MerchantColors.gold,
                ),
              ),
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
    required bool locked,
  }) {
    return Row(
      children: [
        Icon(icon,
            size: 16,
            color: locked
                ? MerchantColors.textGrey
                : MerchantColors.gold),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: locked ? MerchantColors.textGrey : Colors.white,
            ),
          ),
        ),
        if (locked)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 12, color: MerchantColors.gold),
              const SizedBox(width: 4),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: MerchantColors.textGrey,
                ),
              ),
            ],
          )
        else
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: MerchantColors.gold,
            ),
          ),
      ],
    );
  }
}
