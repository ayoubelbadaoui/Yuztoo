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
              child: YuztooPullRefresh(
                onRefresh: _onPullRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
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
                            guideKeys: _quickKeys,
                          );
                        },
                        // Loading: visible placeholder instead of `SizedBox.shrink()`
                        // so the merchant doesn't see a flash of empty space while
                        // their profile resolves. Same intent for error.
                        loading: () =>
                            const _RappelsSectionPlaceholder(height: 220),
                        error: (_, __) => const _RappelsSectionPlaceholder(
                            height: 220, isError: true),
                      ),
                      // ── Récompenses à remettre (bons disponibles) ───────────
                      merchantAsync.when(
                        data: (Merchant? m) {
                          if (m == null) return const SizedBox.shrink();
                          return KeyedSubtree(
                            key: _rewardsKey,
                            child: RewardRedemptionSection(merchant: m),
                          );
                        },
                        loading: () =>
                            const _RappelsSectionPlaceholder(height: 120),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      // Nouveaux clients section — shown when auto-client-validation is OFF.
                      storefrontAsync.when(
                        data: (storefront) => KeyedSubtree(
                          key: _pendingKey,
                          child: PendingClientsSection(
                            merchantId: storefront?.id ?? '',
                            isAutoValidation:
                                storefront?.rappelsAutoClientValidation ?? true,
                          ),
                        ),
                        loading: () =>
                            const _RappelsSectionPlaceholder(height: 120),
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
                      // Auto-validation toggles moved to Vos clients → Validation.
                      KeyedSubtree(
                        key: _autoKey,
                        child: NotificationsAutoEntry(
                          onTap: () =>
                              widget.onNavigate?.call('notifications-auto'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return YuztooTabHeader(
      title: YuztooTabHeader.gradientTitle('Notifications'),
      onBack: widget.onBack,
      actions: [
        IconButton(
          tooltip: 'Guide de la page',
          onPressed: _showPageGuide,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.info_outline_rounded,
              color: MerchantColors.gold, size: 19),
        ),
      ],
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
