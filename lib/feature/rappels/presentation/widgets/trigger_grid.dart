import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../domain/auto_notification_triggers.dart';

/// Trigger definition with label and icon.
class _Trigger {
  final String label;
  final IconData icon;
  const _Trigger(this.label, this.icon);
}

/// Trigger labels shown in [TriggerGrid] (cloud-wired triggers only).
List<String> get triggerLabels => AutoNotificationTriggers.selectableTriggerLabels;

const _allTriggers = [
  _Trigger('Date anniversaire', Icons.cake_outlined),
  _Trigger('Changement statut', Icons.swap_horiz_rounded),
  _Trigger('Nouveau client', Icons.person_add_outlined),
  _Trigger('Visite détectée', Icons.storefront_outlined),
  _Trigger('Fidélité validé', Icons.loyalty_outlined),
  _Trigger('Client inactif', Icons.schedule_outlined),
  _Trigger('Récompense dispo', Icons.card_giftcard_outlined),
  _Trigger('Récompense proche', Icons.star_outline_rounded),
  _Trigger('Fermeture excep.', Icons.event_busy_outlined),
  _Trigger('Nouveau partenaire', Icons.handshake_outlined),
  _Trigger('Anniversaire connexion', Icons.celebration_outlined),
];

List<_Trigger> get _selectableTriggers {
  final labels = AutoNotificationTriggers.selectableTriggerLabels;
  final result = <_Trigger>[];
  for (var i = 0; i < AutoNotificationTriggers.triggerLabels.length; i++) {
    if (labels.contains(AutoNotificationTriggers.triggerLabels[i])) {
      result.add(_allTriggers[i]);
    }
  }
  return result;
}

/// Trigger selection grid – icon-based mini cards in a 3-column layout.
class TriggerGrid extends StatelessWidget {
  const TriggerGrid({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const crossCount = 3;
    const spacing = 10.0;
    const cardHeight = 100.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth - spacing * (crossCount - 1)) / crossCount;
        final aspectRatio = cardWidth / cardHeight;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: aspectRatio,
          ),
          itemCount: _selectableTriggers.length,
          itemBuilder: (context, index) {
            final trigger = _selectableTriggers[index];
            final isSelected = selectedIndex == index;
            return _triggerCard(trigger, isSelected, index);
          },
        );
      },
    );
  }

  Widget _triggerCard(
    _Trigger trigger,
    bool isSelected,
    int index,
  ) {
    return GestureDetector(
      onTap: () => onSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? MerchantColors.gold.withValues(alpha: 0.15)
              : MerchantColors.navyCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? MerchantColors.gold
                : Colors.white.withValues(alpha: 0.06),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? MerchantColors.gold
                    : Colors.white.withValues(alpha: 0.06),
              ),
              child: Icon(
                trigger.icon,
                size: 18,
                color: isSelected
                    ? MerchantColors.darkOverlay
                    : MerchantColors.textGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              trigger.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? MerchantColors.gold : Colors.white,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
