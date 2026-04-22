part of 'rappels_screen.dart';

extension _RappelsScreenUi on _RappelsScreenState {
  Widget _buildRappelsScaffold(
    BuildContext context, {
    required AsyncValue<Storefront?> storefrontAsync,
    required AsyncValue<Merchant?> merchantAsync,
    required Merchant? merchant,
    required bool isManualPassageValidation,
    required int totalPendingPassages,
  }) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: MerchantColors.bgHeader,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 80,
                ),
                child: Column(
                  children: [
                    storefrontAsync.when(
                      data: (storefront) => RappelsClientsSection(
                        connectedClientsThisMonth:
                            storefront?.rappelsMonthlyConnectedClients ?? 0,
                        validatedPassagesThisMonth:
                            storefront?.rappelsMonthlyValidatedPassages ?? 0,
                        pendingLoyaltyPassagesToConfirm: totalPendingPassages,
                        isManualPassageValidation: isManualPassageValidation,
                        onConfirmPendingPassagesTap:
                            _ensurePendingLoyaltySectionVisible,
                      ),
                      loading: () => RappelsClientsSection(
                        connectedClientsThisMonth: 0,
                        validatedPassagesThisMonth: 0,
                        pendingLoyaltyPassagesToConfirm: totalPendingPassages,
                        isManualPassageValidation: isManualPassageValidation,
                        onConfirmPendingPassagesTap:
                            _ensurePendingLoyaltySectionVisible,
                      ),
                      error: (_, __) => RappelsClientsSection(
                        connectedClientsThisMonth: 0,
                        validatedPassagesThisMonth: 0,
                        pendingLoyaltyPassagesToConfirm: totalPendingPassages,
                        isManualPassageValidation: isManualPassageValidation,
                        onConfirmPendingPassagesTap:
                            _ensurePendingLoyaltySectionVisible,
                      ),
                    ),
                    merchantAsync.when(
                      data: (Merchant? m) {
                        if (m == null) return const SizedBox.shrink();
                        return PendingLoyaltyValidationsSection(
                          key: _pendingLoyaltySectionKey,
                          merchant: m,
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const RappelsProductSection(),
                    storefrontAsync.when(
                      data: (storefront) {
                        final autoClient =
                            storefront?.rappelsAutoClientValidation ?? true;
                        final autoPassage =
                            storefront?.rappelsAutoPassageValidation ?? true;
                        final sid = storefront?.id;
                        return RappelsTogglesSection(
                          autoClientValidation: autoClient,
                          autoPassageValidation: autoPassage,
                          onClientChanged: sid != null
                              ? (v) => _saveRappels(ref, sid, v, autoPassage)
                              : (_) {},
                          onPassageChanged: sid != null
                              ? (v) => _saveRappels(ref, sid, autoClient, v)
                              : (_) {},
                        );
                      },
                      loading: () => RappelsTogglesSection(
                        autoClientValidation: true,
                        autoPassageValidation: true,
                        onClientChanged: (_) {},
                        onPassageChanged: (_) {},
                      ),
                      error: (_, __) => RappelsTogglesSection(
                        autoClientValidation: true,
                        autoPassageValidation: true,
                        onClientChanged: (_) {},
                        onPassageChanged: (_) {},
                      ),
                    ),
                    NotificationsAutoEntry(
                      onTap: () =>
                          widget.onNavigate?.call('notifications-auto'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: MerchantColors.bgHeader,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
          child: Center(
            child: Text(
              'Vos rappels',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
