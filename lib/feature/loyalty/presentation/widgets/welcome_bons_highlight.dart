import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../application/client_loyalty_providers.dart';
import '../../domain/entities/client_reward_item.dart';

/// Home-level highlight surfacing pending welcome bons in their own section,
/// because they were previously buried inside "Mes avantages" and clients
/// missed them entirely.
///
/// Renders nothing when the connected client has no claimable welcome bon —
/// it must never steal vertical space outside its purpose.
///
/// Tapping a card delegates to [onTapBon] so the parent decides where the
/// claim flow lives. The home delegates to the loyalty tab (single entry
/// point for the actual claim sheet, which lives there to avoid duplicating
/// `claimWelcomeBonProvider` wiring).
class WelcomeBonsHighlight extends ConsumerWidget {
  const WelcomeBonsHighlight({
    super.key,
    required this.onTapBon,
    this.horizontalPadding = 24,
  });

  /// Called with the tapped welcome bon. The home implementation routes the
  /// user to the loyalty tab, where the existing detail sheet handles the
  /// claim transaction.
  final void Function(ClientRewardItem reward) onTapBon;

  /// External horizontal padding so the section can align with the rest of
  /// the home content while keeping its own internal scroll padding.
  final double horizontalPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(availableClientRewardsProvider);
    return rewardsAsync.maybeWhen(
      data: (rewards) {
        final welcome = rewards
            .where((r) => r.kind == ClientRewardKind.welcome)
            .toList(growable: false);
        if (welcome.isEmpty) return const SizedBox.shrink();
        return _Section(
          welcomeBons: welcome,
          onTapBon: onTapBon,
          horizontalPadding: horizontalPadding,
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.welcomeBons,
    required this.onTapBon,
    required this.horizontalPadding,
  });

  final List<ClientRewardItem> welcomeBons;
  final void Function(ClientRewardItem reward) onTapBon;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final count = welcomeBons.length;
    final subtitle = count == 1
        ? '1 bon de bienvenue à récupérer'
        : '$count bons de bienvenue à récupérer';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.card_giftcard_rounded,
                color: MerchantColors.gold,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cadeaux de bienvenue',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: MerchantColors.gold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: MerchantColors.textLightGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            itemCount: welcomeBons.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final reward = welcomeBons[index];
              return _WelcomeBonTile(
                reward: reward,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTapBon(reward);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _WelcomeBonTile extends StatelessWidget {
  const _WelcomeBonTile({required this.reward, required this.onTap});

  final ClientRewardItem reward;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final merchantName = reward.merchant.displayName?.isNotEmpty == true
        ? reward.merchant.displayName!
        : reward.merchant.name;
    final now = DateTime.now();
    final daysLeft = reward.daysLeftAt(now);
    final isExpiringSoon = reward.isExpiringSoonAt(now);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MerchantColors.navyCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isExpiringSoon
                ? const Color(0xFFE8A93C)
                : MerchantColors.gold.withValues(alpha: 0.55),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: MerchantColors.gold.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: MerchantColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.card_giftcard_rounded,
                    color: MerchantColors.gold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    merchantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              reward.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: MerchantColors.gold,
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Text(
                reward.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  height: 1.3,
                  color: MerchantColors.textLightGrey,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (daysLeft != null && isExpiringSoon)
                  Expanded(
                    child: Text(
                      daysLeft <= 0
                          ? 'Expire aujourd’hui'
                          : (daysLeft == 1
                              ? 'Plus qu’un jour'
                              : 'Expire dans $daysLeft jours'),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE8A93C),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Text(
                      'À récupérer',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: MerchantColors.gold,
                      ),
                    ),
                  ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: MerchantColors.gold,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
