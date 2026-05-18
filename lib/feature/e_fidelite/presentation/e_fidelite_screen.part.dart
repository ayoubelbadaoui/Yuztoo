part of 'e_fidelite_screen.dart';

extension _EFideliteScreenUi on _EFideliteScreenState {
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

  Widget _buildEFideliteBody(BuildContext context) {
    final asyncMerchant = ref.watch(currentMerchantForOwnerProvider);
    final config = ref.watch(loyaltyProgramEditingProvider);
    final maxStepVisited = ref.watch(loyaltyWizardMaxStepVisitedProvider);

    ref.listen<AsyncValue<Merchant?>>(currentMerchantForOwnerProvider,
        (previous, next) {
      next.whenData((merchant) {
        if (merchant != null) {
          ref
              .read(loyaltyProgramEditingProvider.notifier)
              .hydrateFromMerchantIfNeeded(merchant);
          _initViewModeIfNeeded(merchant);
        }
      });
    });

    final merchant = asyncMerchant.valueOrNull;
    if (merchant != null) {
      _initViewModeIfNeeded(merchant);
    }

    final inRecap = _viewMode == _EFideliteViewMode.recap;
    final saveEnabled = merchant != null &&
        !_saving &&
        !inRecap &&
        loyaltyWizardSaveEnabled(
          config: config,
          hasSavedLoyaltyProgram: merchant.hasSavedLoyaltyProgram,
          editingFromRecap: _editingFromRecap,
          maxStepVisited: maxStepVisited,
        );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        widget.onBack?.call();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: MerchantColors.bgHeader,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: MerchantColors.bgMain,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: MerchantColors.bgMain,
          resizeToAvoidBottomInset: true,
          body: Column(
            children: [
              _EFideliteHeader(
                onBack: widget.onBack,
                onSave: _save,
                showSave: !inRecap,
                saveEnabled: saveEnabled,
                saving: _saving,
              ),
              Expanded(
                child: asyncMerchant.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: MerchantColors.gold),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.redAccent.withValues(alpha: 0.1),
                            ),
                            child: const Icon(
                              Icons.cloud_off_outlined,
                              color: Colors.redAccent,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Impossible de charger le programme',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vérifiez votre connexion et réessayez.',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: MerchantColors.textGrey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => ref.invalidate(
                                currentMerchantForOwnerProvider),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    MerchantColors.gold,
                                    Color(0xFFD4AF37),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: MerchantColors.gold
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Réessayer',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: MerchantColors.bgHeader,
                                ),
                              ),
                            ),
                          ),
                        ],
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

                    if (_viewMode == _EFideliteViewMode.recap) {
                      final saved = merchant.loyaltyProgram ?? config;
                      return LoyaltyProgramRecap(
                        config: saved,
                        saving: _saving,
                        onEdit: ({required int initialStep}) =>
                            _openWizard(
                          initialStep: initialStep,
                          fromRecap: true,
                        ),
                        onDisable: _disableProgram,
                      );
                    }

                    return LoyaltyConfigurationWizard(
                      key: ValueKey(
                        'wizard_${_wizardInitialStep}_$_editingFromRecap',
                      ),
                      onSave: _save,
                      saveEnabled: saveEnabled,
                      saving: _saving,
                      initialStep: _wizardInitialStep,
                      editingFromRecap: _editingFromRecap,
                    );
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

class _EFideliteHeader extends StatelessWidget {
  const _EFideliteHeader({
    this.onBack,
    required this.onSave,
    required this.showSave,
    required this.saveEnabled,
    required this.saving,
  });

  final VoidCallback? onBack;
  final VoidCallback onSave;
  final bool showSave;
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
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onBack,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: MerchantColors.gold,
                    size: 20,
                  ),
                ),
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
              if (showSave)
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
                  )
              else
                const SizedBox(width: 44),
            ],
          ),
        ),
      ),
    );
  }
}
