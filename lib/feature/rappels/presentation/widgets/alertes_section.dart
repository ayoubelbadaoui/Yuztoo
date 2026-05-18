import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../application/providers.dart' as rappels_providers;
import '../../domain/entities/rappel_alert.dart';
import 'rappels_section_header.dart';

/// "Alertes" section on the Rappels screen.
/// Shows computed alerts (expiring promos, pending loyalty, reward-ready clients).
class AlertesSection extends ConsumerWidget {
  const AlertesSection({super.key, required this.merchantId});

  final String merchantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (merchantId.isEmpty) return const SizedBox.shrink();

    final alertsAsync =
        ref.watch(rappels_providers.rappelsAlertsProvider(merchantId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RappelsSectionHeader(
            icon: Icons.warning_amber_rounded,
            title: 'Alertes',
            subtitle: 'Éléments nécessitant votre attention',
          ),
          const SizedBox(height: 16),
          alertsAsync.when(
            data: (alerts) => alerts.isEmpty
                ? _buildEmpty()
                : Column(
                    children: alerts
                        .map((a) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AlertCard(alert: a),
                            ))
                        .toList(),
                  ),
            loading: () => _buildSkeleton(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: MerchantColors.gold, size: 32),
          const SizedBox(height: 8),
          Text(
            'Aucune alerte',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tout est en ordre',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: MerchantColors.textLightGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: List.generate(
        2,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: MerchantColors.navyCard.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Alert card ────────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final RappelAlert alert;

  @override
  Widget build(BuildContext context) {
    final config = _configFor(alert.type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: config.bgColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: config.bgColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: config.bgColor.withValues(alpha: 0.2),
            ),
            child: Icon(config.icon, color: config.bgColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title(alert.count),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (alert.detail != null || config.subtitle(alert.count) != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      alert.detail ?? config.subtitle(alert.count)!,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: MerchantColors.textLightGrey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: config.bgColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${alert.count}',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: config.bgColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _AlertConfig _configFor(RappelAlertType type) {
    switch (type) {
      case RappelAlertType.promoExpiring:
        return _AlertConfig(
          icon: Icons.local_offer_outlined,
          bgColor: const Color(0xFFFF9800),
          title: (n) => n == 1 ? 'Promotion expire bientôt' : '$n promos expirent bientôt',
          subtitle: (_) => 'Dans moins de 3 jours',
        );
      case RappelAlertType.loyaltyRewardReady:
        return _AlertConfig(
          icon: Icons.card_giftcard_outlined,
          bgColor: MerchantColors.gold,
          title: (n) => n == 1 ? '1 client a droit à sa récompense' : '$n clients ont droit à leur récompense',
          subtitle: (_) => 'Objectif fidélité atteint',
        );
    }
  }
}

class _AlertConfig {
  const _AlertConfig({
    required this.icon,
    required this.bgColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color bgColor;
  final String Function(int) title;
  final String? Function(int) subtitle;
}
