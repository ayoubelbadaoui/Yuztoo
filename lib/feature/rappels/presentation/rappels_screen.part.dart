part of 'rappels_screen.dart';

extension _RappelsScreenUi on _RappelsScreenState {
  Widget _buildRappelsScaffold(
    BuildContext context, {
    required AsyncValue<Storefront?> storefrontAsync,
    required AsyncValue<Merchant?> merchantAsync,
    required Merchant? merchant,
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
                  bottom: MediaQuery.of(context).padding.bottom +
                      MediaQuery.of(context).viewInsets.bottom +
                      80,
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
                          createdByUid: m.ownerUid,
                          onSend: _onQuickSend,
                          history: historyAsync.valueOrNull ?? [],
                          historyLoading: historyAsync.isLoading,
                          quotaLabel: m.weeklyQuotaLabel,
                          quotaExceeded: !m.canSendNotification,
                        );
                      },
                      // Loading: visible placeholder instead of `SizedBox.shrink()`
                      // so the merchant doesn't see a flash of empty space while
                      // their profile resolves. Same intent for error.
                      loading: () => const _RappelsSectionPlaceholder(height: 220),
                      error: (_, __) =>
                          const _RappelsSectionPlaceholder(height: 220, isError: true),
                    ),
                    // ── Clients + stats ─────────────────────────────────────
                    storefrontAsync.when(
                      data: (storefront) => RappelsClientsSection(
                        connectedClientsThisMonth:
                            storefront?.rappelsMonthlyConnectedClients ?? 0,
                        validatedPassagesThisMonth:
                            storefront?.rappelsMonthlyValidatedPassages ?? 0,
                        onAutoTap: _scrollToToggles,
                      ),
                      loading: () => RappelsClientsSection(
                        connectedClientsThisMonth: 0,
                        validatedPassagesThisMonth: 0,
                        onAutoTap: _scrollToToggles,
                      ),
                      error: (_, __) => RappelsClientsSection(
                        connectedClientsThisMonth: 0,
                        validatedPassagesThisMonth: 0,
                        onAutoTap: _scrollToToggles,
                      ),
                    ),
                    // ── Récompenses à remettre (bons disponibles) ───────────
                    merchantAsync.when(
                      data: (Merchant? m) {
                        if (m == null) return const SizedBox.shrink();
                        return RewardRedemptionSection(merchant: m);
                      },
                      loading: () => const _RappelsSectionPlaceholder(height: 120),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    // Nouveaux clients section — shown when auto-client-validation is OFF.
                    storefrontAsync.when(
                      data: (storefront) => PendingClientsSection(
                        merchantId: storefront?.id ?? '',
                        isAutoValidation:
                            storefront?.rappelsAutoClientValidation ?? true,
                      ),
                      loading: () => const _RappelsSectionPlaceholder(height: 120),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    // Alertes — actionable items first, before promotional content
                    storefrontAsync.when(
                      data: (storefront) => AlertesSection(
                        merchantId: storefront?.id ?? '',
                      ),
                      loading: () => const _RappelsSectionPlaceholder(height: 100),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    // RappelsProductSection (the NFC plaque marketing
                    // block) is hidden while plaque-programming is out
                    // of scope. Kept in source as a SizedBox.shrink()
                    // wrapper so the existing widget + its callback
                    // wiring survive a future re-enable. The new model
                    // is phone-to-phone NFC handled on the client
                    // scanner; merchants don't need a plaque flow.
                    const SizedBox.shrink(),
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
                    'Notifications',
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

/// Minimal placeholder used while a Rappels section's data is loading.
/// Just the plain spinner the rest of the app uses — no logo, no card
/// styling. Without something here the section would collapse to zero
/// height and snap open once data lands, making the page look broken.
class _RappelsSectionPlaceholder extends StatelessWidget {
  const _RappelsSectionPlaceholder({
    required this.height,
    this.isError = false,
  });

  final double height;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: isError
            ? Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade300.withValues(alpha: 0.7),
                size: 22,
              )
            : const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: MerchantColors.gold,
                ),
              ),
      ),
    );
  }
}
