import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../merchant/application/providers.dart';
import '../../merchant/domain/entities/loyalty_program_config.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../../storefront/application/providers.dart' as storefront_providers;
import '../../loyalty/application/client_loyalty_providers.dart'
    show loyaltyProgramsDiffer;
import '../application/e_fidelite_providers.dart';
import 'widgets/loyalty_configuration_wizard.dart';

part 'e_fidelite_screen.part.dart';

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
    final merchant = ref.read(currentMerchantForOwnerProvider).valueOrNull;
    if (merchant == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil commerçant introuvable.'),
        ),
      );
      return;
    }

    final config = ref.read(loyaltyProgramEditingProvider);
    final previous = merchant.loyaltyProgram ??
        LoyaltyProgramConfig.fallbackFromFlags(
          loyaltyEnabled: merchant.loyaltyEnabled,
        );
    final programChanged = loyaltyProgramsDiffer(previous, config);
    final disabling = previous.programEnabled && !config.programEnabled;

    if (programChanged || disabling) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Modifier le programme ?'),
          content: const Text(
            'Les clients déjà inscrits conservent leur programme actuel. '
            'Seuls les nouveaux clients suivront le nouveau programme.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    setState(() => _saving = true);
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
          const SnackBar(content: Text('Programme de fidélité enregistré.')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => _buildEFideliteBody(context);
}
