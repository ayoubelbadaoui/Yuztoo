import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';

/// Toggle settings section of the Rappels screen.
class RappelsTogglesSection extends StatelessWidget {
  const RappelsTogglesSection({
    super.key,
    required this.autoClientValidation,
    required this.autoPassageValidation,
    required this.onClientChanged,
    required this.onPassageChanged,
  });

  final bool autoClientValidation;
  final bool autoPassageValidation;
  final ValueChanged<bool> onClientChanged;
  final ValueChanged<bool> onPassageChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _toggleItem(
            icon: Icons.person_add_outlined,
            label: 'Validation client automatique',
            subtitle: 'Accepte les nouveaux followers sans action manuelle',
            value: autoClientValidation,
            onChanged: onClientChanged,
          ),
          const SizedBox(height: 16),
          _toggleItem(
            icon: Icons.loyalty_outlined,
            label: 'Validation passage automatique',
            subtitle: 'Valide les passages fidélité sans confirmation manuelle',
            value: autoPassageValidation,
            onChanged: onPassageChanged,
          ),
        ],
      ),
    );
  }

  Widget _toggleItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: MerchantColors.navyCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderStronger)
                : MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderAlpha),
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
                color: value
                    ? MerchantColors.gold.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
              ),
              child: Icon(
                icon,
                color:
                    value ? MerchantColors.gold : MerchantColors.textGrey,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: MerchantColors.textLightGrey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 48,
              height: 28,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: value
                    ? MerchantColors.gold
                    : const Color(0xFF2A3B55),
                border: value
                    ? null
                    : Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
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

