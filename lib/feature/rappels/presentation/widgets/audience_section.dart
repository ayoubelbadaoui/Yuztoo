import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import 'step_header.dart';

/// Step 2 – choose audience (Tous / Certains).
class AudienceSection extends StatelessWidget {
  const AudienceSection({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _sectionBorder(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(
            step: 2,
            title: 'Audience',
            icon: Icons.people_outline_rounded,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _audienceCard(
                      'Tous mes clients', Icons.groups_outlined, 0)),
              const SizedBox(width: 12),
              Expanded(
                  child: _audienceCard(
                      'Certains clients', Icons.person_search_outlined, 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _audienceCard(String label, IconData icon, int index) {
    final isActive = selectedIndex == index;
    return GestureDetector(
      onTap: () => onChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive
              ? MerchantColors.gold.withValues(alpha: 0.15)
              : MerchantColors.navyCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? MerchantColors.gold
                : Colors.white.withValues(alpha: 0.08),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? MerchantColors.gold
                    : Colors.white.withValues(alpha: 0.08),
              ),
              child: Icon(
                icon,
                color: isActive
                    ? MerchantColors.darkOverlay
                    : MerchantColors.textGrey,
                size: 22,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? MerchantColors.gold : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _sectionBorder() {
    return BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: MerchantColors.gold
              .withValues(alpha: MerchantColors.goldBorderAlpha),
          width: 1,
        ),
      ),
    );
  }
}

