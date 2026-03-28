import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';

/// "PRÉFÉRENCES DU COMPTE PRO" section with navigable items.
class SettingsPreferencesSection extends StatelessWidget {
  const SettingsPreferencesSection({super.key, this.onNavigate});

  final ValueChanged<String>? onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRÉFÉRENCES DU COMPTE PRO',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: MerchantColors.textGrey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          _settingsItem(
            icon: Icons.person_outline,
            label: 'Préférences du compte pro',
            onTap: () => onNavigate?.call('account-preferences'),
          ),
          _settingsItem(
            icon: Icons.lock_outline,
            label: 'Identification et sécurité',
          ),
          _settingsItem(
            icon: Icons.shield_outlined,
            label: 'Confidentialité des données',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _settingsItem({
    required IconData icon,
    required String label,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: MerchantColors.gold.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(Icons.chevron_right,
                color: MerchantColors.textGrey, size: 20),
          ],
        ),
      ),
    );
  }
}

