import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';

/// "PRÉFÉRENCES DU COMPTE PRO" section with navigable items.
class SettingsPreferencesSection extends StatelessWidget {
  const SettingsPreferencesSection({super.key, this.onNavigate});

  final ValueChanged<String>? onNavigate;

  void _showPrivacySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PrivacySheet(),
    );
  }

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
            onTap: () => onNavigate?.call('security'),
          ),
          _settingsItem(
            icon: Icons.shield_outlined,
            label: 'Confidentialité des données',
            onTap: () => _showPrivacySheet(context),
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

class _PrivacySheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Container(
      decoration: const BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).padding.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: MerchantColors.textGrey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: MerchantColors.gold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined,
                    color: MerchantColors.gold, size: 22),
              ),
              const SizedBox(width: 14),
              Text(
                'Confidentialité des données',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _privacyItem(
            icon: Icons.lock_outline,
            title: 'Données chiffrées',
            subtitle:
                'Toutes vos données sont stockées de manière sécurisée sur Firebase.',
          ),
          const SizedBox(height: 14),
          _privacyItem(
            icon: Icons.person_off_outlined,
            title: 'Aucune revente',
            subtitle:
                'Vos informations ne sont jamais partagées ou revendues à des tiers.',
          ),
          const SizedBox(height: 14),
          _privacyItem(
            icon: Icons.delete_outline,
            title: 'Droit à l\'effacement',
            subtitle:
                'Vous pouvez supprimer votre compte et toutes vos données depuis "Identification et sécurité".',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [MerchantColors.gold, Color(0xFFD4AF37)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Compris',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: MerchantColors.bgHeader,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _privacyItem(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: MerchantColors.gold, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: MerchantColors.textGrey,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

