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
            label: 'Validation client automatique',
            value: autoClientValidation,
            onChanged: onClientChanged,
          ),
          const SizedBox(height: 16),
          _toggleItem(
            label: 'Validation passage automatique',
            value: autoPassageValidation,
            onChanged: onPassageChanged,
          ),
        ],
      ),
    );
  }

  Widget _toggleItem({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MerchantColors.gold
              .withValues(alpha: MerchantColors.goldBorderStronger),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.check, color: MerchantColors.gold, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 48,
              height: 28,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: value ? MerchantColors.gold : const Color(0xFF444444),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

