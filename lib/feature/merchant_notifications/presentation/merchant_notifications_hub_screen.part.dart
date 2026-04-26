part of 'merchant_notifications_hub_screen.dart';

extension _HubUi on _MerchantNotificationsHubScreenState {
  Widget _buildScaffold(
    BuildContext context, {
    required Merchant? merchant,
    required String merchantId,
    required AsyncValue historyAsync,
    required int autoCount,
    required int clientCount,
    required List<MerchantPartner> partners,
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
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                behavior: HitTestBehavior.translucent,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 80,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Volume indicators ────────────────────────────────
                      if (clientCount > 0) _buildVolumeRow(clientCount),

                      // ── Compose + send + history ─────────────────────────
                      if (merchant != null)
                        QuickSendSection(
                          merchantId: merchant.id,
                          merchantName: merchant.name,
                          onSend: _onQuickSend,
                          history: historyAsync.valueOrNull ?? [],
                          historyLoading: historyAsync.isLoading,
                          quotaLabel: merchant.weeklyQuotaLabel,
                          quotaExceeded: !merchant.canSendNotification,
                        )
                      else
                        _buildMerchantLoading(),

                      const SizedBox(height: 8),

                      // ── Auto-notifications entry ──────────────────────────
                      _buildAutoNotificationsEntry(autoCount),

                      // ── Partners block ────────────────────────────────────
                      if (partners.isNotEmpty)
                        _buildPartnersBlock(partners),
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
              GestureDetector(
                onTap: () => widget.onNavigate?.call('switch-to-client'),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: MerchantColors.gold
                          .withValues(alpha: MerchantColors.goldBorderAlpha),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.switch_account,
                      color: MerchantColors.gold,
                      size: 20,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Vos notifications',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Auto-notifications shortcut icon
              GestureDetector(
                onTap: () => widget.onNavigate?.call('notifications-auto'),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: MerchantColors.gold
                          .withValues(alpha: MerchantColors.goldBorderStronger),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: MerchantColors.gold,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeRow(int clientCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          const Icon(
            Icons.people_outline_rounded,
            color: MerchantColors.textGrey,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            '$clientCount abonné${clientCount > 1 ? 's' : ''}',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: MerchantColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantLoading() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: CircularProgressIndicator(
          color: MerchantColors.gold,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildAutoNotificationsEntry(int autoCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GestureDetector(
        onTap: () => widget.onNavigate?.call('notifications-auto'),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: MerchantColors.navyCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: MerchantColors.gold
                  .withValues(alpha: MerchantColors.goldBorderAlpha),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: MerchantColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: MerchantColors.gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications automatiques',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      autoCount > 0
                          ? '$autoCount règle${autoCount > 1 ? 's' : ''} active${autoCount > 1 ? 's' : ''}'
                          : 'Configurer des envois automatiques',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: MerchantColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: MerchantColors.gold.withValues(alpha: 0.6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartnersBlock(List<MerchantPartner> partners) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MerchantColors.navyCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mettre en avant des partenaires',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: () => widget.onNavigate?.call('partners'),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Text(
                        'Gérer',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: MerchantColors.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: MerchantColors.gold,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: partners
                  .take(3)
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: MerchantColors.gold
                                  .withValues(alpha: 0.1),
                              border: Border.all(
                                color: MerchantColors.gold
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: p.partnerLogoUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      p.partnerLogoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(
                                        Icons.store_rounded,
                                        color: MerchantColors.gold,
                                        size: 20,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.store_rounded,
                                    color: MerchantColors.gold,
                                    size: 20,
                                  ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 52,
                            child: Text(
                              p.partnerName,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                color: MerchantColors.textGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
