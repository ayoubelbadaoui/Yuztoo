import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import 'step_header.dart';

/// Step 2 – choose audience (Tous / Certains) + optional segment selector.
class AudienceSection extends StatelessWidget {
  const AudienceSection({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    this.targetSegments = const [],
    this.onSegmentToggled,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final List<String> targetSegments;
  final ValueChanged<String>? onSegmentToggled;

  // Segments match the canonical passage-based model (computeSegment in Cloud Functions).
  // 'abonne' is retired — it was heart-based and inconsistent with notification targeting.
  static const _segments = [
    _SegmentDef('vip', 'VIP', Icons.workspace_premium_outlined),
    _SegmentDef('habitue', 'Habitué', Icons.repeat_rounded),
    _SegmentDef('nouveau', 'Nouveau', Icons.person_add_outlined),
    _SegmentDef('inactif', 'Inactifs', Icons.schedule_outlined),
  ];

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
          // Segment chips – only visible when "Certains clients" is selected
          if (selectedIndex == 1) ...[
            const SizedBox(height: 16),
            Text(
              'Cibler les segments',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: MerchantColors.textGrey,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _segments.map((s) {
                final isOn = targetSegments.contains(s.key);
                return GestureDetector(
                  onTap: () => onSegmentToggled?.call(s.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isOn
                          ? MerchantColors.gold.withValues(alpha: 0.15)
                          : MerchantColors.navyCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isOn
                            ? MerchantColors.gold
                            : Colors.white.withValues(alpha: 0.1),
                        width: isOn ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(s.icon,
                            size: 14,
                            color: isOn
                                ? MerchantColors.gold
                                : MerchantColors.textGrey),
                        const SizedBox(width: 6),
                        Text(
                          s.label,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: isOn
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isOn
                                ? MerchantColors.gold
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (targetSegments.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 14, color: Color(0xFFFFB300)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Sélectionnez au moins un segment pour cibler des clients spécifiques.',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFFFFB300),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
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

class _SegmentDef {
  const _SegmentDef(this.key, this.label, this.icon);
  final String key;
  final String label;
  final IconData icon;
}
