import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../../../core/shared/widgets/snackbar.dart';
import '../../../merchant/application/providers.dart' as merchant_providers;
import '../../../merchant/domain/entities/merchant.dart';
import '../../../storefront/application/providers.dart' as storefront_providers;

/// Auto-accept followers / auto-validate passages — lives under
/// **Vos clients → Validation** (moved off Notifications).
class ValidationAutoToggles extends ConsumerWidget {
  const ValidationAutoToggles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantAsync =
        ref.watch(merchant_providers.currentMerchantForOwnerProvider);

    return merchantAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: _TogglesSkeleton(),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (merchant) {
        if (merchant == null) return const SizedBox.shrink();
        final autoClient = merchant.rappelsAutoClientValidation ?? true;
        final autoPassage = merchant.rappelsAutoPassageValidation ?? true;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Column(
            children: [
              _ToggleItem(
                icon: Icons.person_add_outlined,
                label: 'Validation client automatique',
                subtitle: autoClient
                    ? 'Les nouveaux followers apparaissent tout de suite'
                    : 'Les nouveaux followers restent en attente (Notifications → Nouveaux clients) jusqu\'à votre accord',
                value: autoClient,
                onChanged: (v) => _save(
                  context,
                  ref,
                  merchant,
                  autoClient: v,
                  autoPassage: autoPassage,
                ),
              ),
              const SizedBox(height: 12),
              _ToggleItem(
                icon: Icons.loyalty_outlined,
                label: 'Validation passage automatique',
                subtitle:
                    'Valide les passages fidélité sans confirmation manuelle',
                value: autoPassage,
                onChanged: (v) => _save(
                  context,
                  ref,
                  merchant,
                  autoClient: autoClient,
                  autoPassage: v,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    Merchant merchant, {
    required bool autoClient,
    required bool autoPassage,
  }) async {
    final update = ref.read(merchant_providers.updateRappelsSettingsProvider);
    final result = await update.call(
      merchantId: merchant.id,
      rappelsAutoClientValidation: autoClient,
      rappelsAutoPassageValidation: autoPassage,
    );
    if (!context.mounted) return;
    result.fold(
      (_) {
        showErrorSnackbar(context, 'Erreur lors de l\'enregistrement');
      },
      (_) {
        ref.invalidate(merchant_providers.currentMerchantForOwnerProvider);
        ref.invalidate(storefront_providers.storefrontProvider);
      },
    );
  }
}

class _ToggleItem extends StatelessWidget {
  const _ToggleItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
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
                color: value ? MerchantColors.gold : MerchantColors.textGrey,
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
                color: value ? MerchantColors.gold : const Color(0xFF2A3B55),
                border: value
                    ? null
                    : Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
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

class _TogglesSkeleton extends StatelessWidget {
  const _TogglesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (i) => Padding(
          padding: EdgeInsets.only(bottom: i == 0 ? 12 : 0),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: MerchantColors.navyCard.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderAlpha),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
