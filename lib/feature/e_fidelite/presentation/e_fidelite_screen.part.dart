part of 'e_fidelite_screen.dart';

extension _EFideliteScreenUi on _EFideliteScreenState {
  Widget _buildEFideliteBody(BuildContext context) {
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
              _EFideliteHeader(
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
                    return LoyaltyConfigurationWizard(
                      onSave: _save,
                      saveEnabled: asyncMerchant.hasValue &&
                          asyncMerchant.value != null &&
                          !_saving,
                      saving: _saving,
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
