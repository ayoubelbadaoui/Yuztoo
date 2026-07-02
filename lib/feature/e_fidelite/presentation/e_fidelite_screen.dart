import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/snackbar.dart';
import '../../merchant/application/providers.dart';
import '../../merchant/domain/entities/loyalty_program_config.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../../storefront/application/providers.dart' as storefront_providers;
import '../../loyalty/application/client_loyalty_providers.dart'
    show loyaltyProgramsDiffer;
import '../application/e_fidelite_providers.dart';
import '../application/loyalty_program_editing_notifier.dart';
import '../application/loyalty_program_flow.dart';
import 'widgets/loyalty_configuration_wizard.dart';

part 'e_fidelite_screen.part.dart';
part 'loyalty_program_recap.part.dart';
part 'loyalty_quick_edit.part.dart';

/// Merchant "E-Fidélité" — loyalty questionnaire + Firestore persistence.
class EFideliteScreen extends ConsumerStatefulWidget {
  const EFideliteScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  ConsumerState<EFideliteScreen> createState() => _EFideliteScreenState();
}

enum _EFideliteViewMode { recap, wizard, quickEdit }

class _EFideliteScreenState extends ConsumerState<EFideliteScreen> {
  bool _saving = false;
  _EFideliteViewMode? _viewMode;
  bool _editingFromRecap = false;
  int _wizardInitialStep = 0;
  bool _viewModeInitialized = false;

  void _handleEfideliteBack() {
    // Quick-edit is reached from the recap, so "back" should return there
    // (discarding unsaved tweaks) instead of leaving the screen entirely.
    if (_viewMode == _EFideliteViewMode.quickEdit) {
      _cancelQuickEdit();
      return;
    }
    final merchant = ref.read(currentMerchantForOwnerProvider).valueOrNull;
    ref
        .read(loyaltyProgramEditingProvider.notifier)
        .resumeHydrationIfPaused(merchant);
    ref.read(loyaltyWizardMaxStepVisitedProvider.notifier).state = 0;
    widget.onBack?.call();
  }

  /// Opens the compact dropdown-based editor for the existing programme.
  void _openQuickEdit() {
    // editingFromRecap=true keeps the header "Enregistrer" enabled, and
    // marking every step visited satisfies the save gate for active programs.
    ref.read(loyaltyWizardMaxStepVisitedProvider.notifier).state =
        loyaltyWizardLastStepIndex;
    setState(() {
      _viewMode = _EFideliteViewMode.quickEdit;
      _editingFromRecap = true;
    });
  }

  /// Discards in-memory tweaks and returns to the recap.
  void _cancelQuickEdit() {
    final merchant = ref.read(currentMerchantForOwnerProvider).valueOrNull;
    if (merchant != null) {
      ref
          .read(loyaltyProgramEditingProvider.notifier)
          .applySavedMerchant(merchant);
    }
    setState(() {
      _viewMode = _EFideliteViewMode.recap;
      _editingFromRecap = false;
    });
  }

  Future<void> _confirmAndStartNewProgram(Merchant merchant) async {
    final saved = merchant.loyaltyProgram ??
        LoyaltyProgramConfig.fallbackFromFlags(
          loyaltyEnabled: merchant.loyaltyEnabled,
        );
    final validityNote = saved.rewardValidityEnabled &&
            saved.rewardValidityDays != null &&
            saved.rewardValidityDays! > 0
        ? 'Les récompenses déjà attribuées avec l’ancien programme restent soumises '
            'au délai de ${saved.rewardValidityDays} jours à partir de leur '
            'attribution, tel que vous l’aviez configuré.\n\n'
        : 'Sans validité limitée sur les récompenses, les clients terminent '
            'naturellement au fil des utilisations ; l’application n’impose pas '
            'de date de fin automatique pour tous.\n\n';

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouveau programme ?'),
        content: Text(
          'Vous allez reconfigurer la fidélité depuis le début. Les nouveaux '
          'clients suivront le programme que vous enregistrerez ensuite.\n\n'
          '$validityNote'
          'Tant que vous n’avez pas enregistré ce nouveau programme, vous '
          'retrouvez l’ancienne configuration en quittant l’assistant ou via '
          '« Réactiver / modifier ».',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;
    ref.read(loyaltyProgramEditingProvider.notifier).beginFreshProgramDraft(merchant);
    ref.read(loyaltyWizardMaxStepVisitedProvider.notifier).state = 0;
    _openWizard(initialStep: 0, fromRecap: false);
  }

  void _initViewModeIfNeeded(Merchant merchant) {
    if (_viewModeInitialized) return;
    _viewModeInitialized = true;
    final pending = ref.read(pendingLoyaltyConfigurationProvider);
    final mode = resolveEFideliteInitialMode(
      merchant: merchant,
      pendingConfiguration: pending,
    );
    _viewMode =
        mode == EFideliteInitialMode.recap ? _EFideliteViewMode.recap : _EFideliteViewMode.wizard;
  }

  void _openWizard({required int initialStep, bool fromRecap = false}) {
    ref.read(loyaltyWizardMaxStepVisitedProvider.notifier).state =
        fromRecap ? loyaltyWizardLastStepIndex : initialStep;
    setState(() {
      _viewMode = _EFideliteViewMode.wizard;
      _editingFromRecap = fromRecap;
      _wizardInitialStep = initialStep;
    });
  }

  void _disableProgram() {
    ref.read(loyaltyProgramEditingProvider.notifier).setProgramEnabled(false);
    _save();
  }

  Future<void> _save() async {
    final merchant = ref.read(currentMerchantForOwnerProvider).valueOrNull;
    if (merchant == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profil commerçant introuvable.',
            style: merchantSnackBarTextOnDark(),
          ),
          backgroundColor: MerchantColors.bgHeader,
          behavior: SnackBarBehavior.floating,
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
      final String title;
      final String body;
      if (disabling) {
        title = 'Désactiver le programme ?';
        const base =
            'La fidélité sera désactivée sur votre vitrine : plus d’offre visible, '
            'plus de demande de passage fidélité côté client. Les données déjà '
            'enregistrées (historique, fiches « Vos clients ») peuvent rester '
            'consultables pour vous, mais le flux fidélité public s’arrête.\n\n';
        final String clientsEnd;
        if (previous.rewardValidityEnabled &&
            previous.rewardValidityDays != null &&
            previous.rewardValidityDays! > 0) {
          clientsEnd =
              'Pour les clients déjà inscrits, les récompenses déjà attribuées '
              'restent soumises à la validité prévue : à utiliser sous '
              '${previous.rewardValidityDays} jours à partir de leur attribution. '
              'Il n’y a pas d’autre date de fin collective imposée par l’application.\n\n'
              'Ensuite, vous pourrez créer un nouveau programme depuis l’écran '
              'de récapitulatif (bouton « Créer un nouveau programme »).';
        } else {
          clientsEnd =
              'Pour les clients déjà inscrits, la progression et les avantages '
              'déjà obtenus restent valables jusqu’à utilisation. Sans validité '
              'limitée sur les récompenses dans ce programme, il n’y a pas de '
              'date limite automatique pour « tout le monde » : chaque client '
              'termine au fil des utilisations.\n\n'
              'Ensuite, vous pourrez créer un nouveau programme depuis l’écran '
              'de récapitulatif (bouton « Créer un nouveau programme »).';
        }
        body = base + clientsEnd;
      } else {
        title = 'Modifier le programme ?';
        body =
            'Les clients déjà inscrits conservent le programme sous lequel ils '
            'se sont inscrits (historique et récompenses associées). Les nouveaux '
            'passages suivent la configuration que vous enregistrez maintenant.';
      }
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
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
              style: merchantSnackBarTextOnWarmAccent(),
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      (updated) {
        ref.read(loyaltyProgramEditingProvider.notifier).applySavedMerchant(updated);
        ref.read(pendingLoyaltyConfigurationProvider.notifier).state = false;
        ref.invalidate(currentMerchantForOwnerProvider);
        ref.invalidate(storefront_providers.storefrontProvider);
        setState(() {
          _viewMode = _EFideliteViewMode.recap;
          _editingFromRecap = false;
          _viewModeInitialized = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Programme de fidélité enregistré.',
              style: merchantSnackBarTextOnGold(),
            ),
            backgroundColor: MerchantColors.gold,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => _buildEFideliteBody(context);
}
