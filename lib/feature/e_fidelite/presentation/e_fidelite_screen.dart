import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../merchant/application/providers.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../../storefront/application/providers.dart' as storefront_providers;
import '../application/e_fidelite_providers.dart';
import 'widgets/loyalty_configuration_wizard.dart';

/// Merchant "E-Fidélité" — loyalty questionnaire + Firestore persistence.
class EFideliteScreen extends ConsumerStatefulWidget {
  const EFideliteScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  ConsumerState<EFideliteScreen> createState() => _EFideliteScreenState();
}

class _EFideliteScreenState extends ConsumerState<EFideliteScreen> {
  bool _saving = false;

  Future<void> _save() async {
    final merchant =
        ref.read(currentMerchantForOwnerProvider).valueOrNull;
    if (merchant == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil commerçant introuvable.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final config = ref.read(loyaltyProgramEditingProvider);
    final result = await ref.read(updateMerchantLoyaltyProgramProvider).call(
          merchantId: merchant.id,
          config: config,
        );
    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failure.message.isNotEmpty
                  ? failure.message
                  : 'Enregistrement impossible.',
            ),
          ),
        );
      },
      (updated) {
        ref.read(loyaltyProgramEditingProvider.notifier).applySavedMerchant(updated);
        ref.invalidate(currentMerchantForOwnerProvider);
        ref.invalidate(storefront_providers.storefrontProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Programme fidélité enregistré.')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncMerchant = ref.watch(currentMerchantForOwnerProvider);

    ref.listen<AsyncValue<Merchant?>>(currentMerchantForOwnerProvider,
        (previous, next) {
      next.whenData((merchant) {
        if (merchant != null) {
          ref
              .read(loyaltyProgramEditingProvider.notifier)
              .hydrateFromMerchantIfNeeded(merchant);
        }
      });
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        // Same as header back: return to Paramètres (nested stack in [YuztooApp]).
        widget.onBack?.call();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: MerchantColors.bgHeader,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: MerchantColors.bgHeader,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: MerchantColors.bgMain,
          resizeToAvoidBottomInset: true,
          body: Column(
            children: [
              _Header(
                onBack: widget.onBack,
                onSave: _save,
                saveEnabled: asyncMerchant.hasValue &&
                    asyncMerchant.value != null &&
                    !_saving,
                saving: _saving,
              ),
              Expanded(
                child: asyncMerchant.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: MerchantColors.gold),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Impossible de charger le commerce.\n$e',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: MerchantColors.textLightGrey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                data: (merchant) {
                  if (merchant == null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Aucun commerce lié à ce compte. Terminez l’onboarding marchand.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: MerchantColors.textLightGrey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }
                  return const LoyaltyConfigurationWizard();
                },
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    this.onBack,
    required this.onSave,
    required this.saveEnabled,
    required this.saving,
  });

  final VoidCallback? onBack;
  final VoidCallback onSave;
  final bool saveEnabled;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MerchantColors.bgHeader,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: MerchantColors.bgHeader,
            border: Border(
              bottom: BorderSide(
                color: MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderAlpha),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                style: IconButton.styleFrom(
                  foregroundColor: MerchantColors.gold,
                  side: const BorderSide(color: MerchantColors.gold, width: 2),
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.arrow_back_ios_new, size: 16),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'E-Fidélité',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              if (saving)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: MerchantColors.gold,
                  ),
                )
              else
                TextButton(
                  onPressed: saveEnabled ? onSave : null,
                  child: Text(
                    'Enregistrer',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: saveEnabled
                          ? MerchantColors.gold
                          : MerchantColors.textLightGrey,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
