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
        systemNavigationBarColor: MerchantColors.bgMain,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 80,
                ),
                child: Column(
                  children: [
                    // ── Quick-send notification composer ────────────────────
                    merchantAsync.when(
                      data: (m) {
                        if (m == null) return const SizedBox.shrink();
                        final historyAsync = ref.watch(
                          rappels_providers.sentNotificationsProvider(m.id),
                        );
                        return QuickSendSection(
                          merchantId: m.id,
                          merchantName: m.name,
                          onSend: _onQuickSend,
                          history: historyAsync.valueOrNull ?? [],
                          historyLoading: historyAsync.isLoading,
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    // ── Clients + stats ─────────────────────────────────────
                    storefrontAsync.when(
                      data: (storefront) => RappelsClientsSection(
                        connectedClientsThisMonth: _kRappelsDummy
                            ? _kDummyConnected
                            : (storefront?.rappelsMonthlyConnectedClients ?? 0),
                        validatedPassagesThisMonth: _kRappelsDummy
                            ? _kDummyValidatedPassages
                            : (storefront?.rappelsMonthlyValidatedPassages ?? 0),
                        pendingLoyaltyPassagesToConfirm: totalPendingPassages,
                        isManualPassageValidation: isManualPassageValidation,
                        onConfirmPendingPassagesTap:
                            _ensurePendingLoyaltySectionVisible,
                        onAutoTap: _scrollToToggles,
                      ),
                      loading: () => RappelsClientsSection(
                        connectedClientsThisMonth: _kRappelsDummy ? _kDummyConnected : 0,
                        validatedPassagesThisMonth: _kRappelsDummy ? _kDummyValidatedPassages : 0,
                        pendingLoyaltyPassagesToConfirm: totalPendingPassages,
                        isManualPassageValidation: isManualPassageValidation,
                        onConfirmPendingPassagesTap:
                            _ensurePendingLoyaltySectionVisible,
                        onAutoTap: _scrollToToggles,
                      ),
                      error: (_, __) => RappelsClientsSection(
                        connectedClientsThisMonth: _kRappelsDummy ? _kDummyConnected : 0,
                        validatedPassagesThisMonth: _kRappelsDummy ? _kDummyValidatedPassages : 0,
                        pendingLoyaltyPassagesToConfirm: totalPendingPassages,
                        isManualPassageValidation: isManualPassageValidation,
                        onConfirmPendingPassagesTap:
                            _ensurePendingLoyaltySectionVisible,
                        onAutoTap: _scrollToToggles,
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
                    // Nouveaux clients section — shown when auto-client-validation is OFF.
                    storefrontAsync.when(
                      data: (storefront) => PendingClientsSection(
                        merchantId: storefront?.id ?? '',
                        isAutoValidation:
                            storefront?.rappelsAutoClientValidation ?? true,
                        showDummyWhenEmpty: _kRappelsDummy,
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    // Alertes — actionable items first, before promotional content
                    storefrontAsync.when(
                      data: (storefront) => AlertesSection(
                        merchantId: storefront?.id ?? '',
                      ),
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
                        return KeyedSubtree(
                          key: _togglesSectionKey,
                          child: RappelsTogglesSection(
                            autoClientValidation: autoClient,
                            autoPassageValidation: autoPassage,
                            onClientChanged: sid != null
                                ? (v) => _saveRappels(ref, sid, v, autoPassage)
                                : (_) {},
                            onPassageChanged: sid != null
                                ? (v) => _saveRappels(ref, sid, autoClient, v)
                                : (_) {},
                          ),
                        );
                      },
                      loading: () => const _RappelsTogglesSkeleton(),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
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
              const SizedBox(width: 44),
              Expanded(
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
              const SizedBox(width: 44),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Toggle loading skeleton ───────────────────────────────────────────────────

class _RappelsTogglesSkeleton extends StatelessWidget {
  const _RappelsTogglesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: List.generate(
          2,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: i == 0 ? 16 : 0),
            child: Container(
              height: 54,
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
      ),
    );
  }
}
