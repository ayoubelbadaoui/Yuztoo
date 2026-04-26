part of 'merchant_profile_summary_screen.dart';

extension _ProfileSummaryUi on _MerchantProfileSummaryScreenState {
  Widget _buildScaffold(
    BuildContext context, {
    required Merchant? merchant,
    required Storefront? storefront,
    required int clientCount,
    required int partnerCount,
    required int cityCount,
    required int weeklyViews,
    required int completionPct,
  }) {
    final merchantName = merchant?.name ?? 'Mon commerce';
    final city = storefront?.city ?? merchant?.city ?? '';
    final bannerUrl = storefront?.bannerImageUrl ?? '';
    final logoUrl = storefront?.profileImageUrl ?? '';

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
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) widget.onBack?.call();
          },
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBannerSection(
                        bannerUrl: bannerUrl,
                        logoUrl: logoUrl,
                        merchantName: merchantName,
                        city: city,
                      ),
                      const SizedBox(height: 20),
                      _buildKpiRow(
                        clients: clientCount,
                        partners: partnerCount,
                        cities: cityCount,
                        weeklyViews: weeklyViews,
                      ),
                      const SizedBox(height: 20),
                      _buildCompletionBar(completionPct),
                      const SizedBox(height: 20),
                      _buildGoogleSyncRow(),
                      const SizedBox(height: 20),
                      _buildEditCta(),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                onTap: widget.onBack,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: MerchantColors.gold, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Mon profil pro',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerSection({
    required String bannerUrl,
    required String logoUrl,
    required String merchantName,
    required String city,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 140,
          width: double.infinity,
          color: MerchantColors.bgHeader,
          child: bannerUrl.isNotEmpty
              ? Image.network(bannerUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox())
              : null,
        ),
        Positioned(
          bottom: -36,
          left: 20,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: MerchantColors.bgMain, width: 3),
              color: MerchantColors.navyCard,
            ),
            child: ClipOval(
              child: logoUrl.isNotEmpty
                  ? Image.network(logoUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.store_rounded,
                          color: MerchantColors.gold,
                          size: 32))
                  : const Icon(Icons.store_rounded,
                      color: MerchantColors.gold, size: 32),
            ),
          ),
        ),
        Positioned(
          bottom: -30,
          left: 104,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                merchantName,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (city.isNotEmpty)
                Text(
                  city,
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: MerchantColors.textGrey),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiRow({
    required int clients,
    required int partners,
    required int cities,
    required int weeklyViews,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
      child: Row(
        children: [
          _kpi('$clients', 'Clients'),
          _kpi('$partners', 'Partenaires'),
          _kpi('$cities', 'Villes'),
          _kpi('$weeklyViews', 'Vues/sem'),
        ],
      ),
    );
  }

  Widget _kpi(String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: MerchantColors.navyCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: MerchantColors.gold.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 9,
                color: MerchantColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionBar(int pct) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: MerchantColors.navyCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: MerchantColors.gold.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profil complété',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$pct%',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: MerchantColors.gold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct / 100,
                backgroundColor: MerchantColors.gold.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    MerchantColors.gold),
                minHeight: 8,
              ),
            ),
            if (pct < 100) ...[
              const SizedBox(height: 8),
              Text(
                'Complétez votre vitrine pour attirer plus de clients.',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: MerchantColors.textGrey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleSyncRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: MerchantColors.navyCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: MerchantColors.gold.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: MerchantColors.gold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sync_rounded,
                  color: MerchantColors.gold, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Synchroniser avec Google Business',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bientôt disponible',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: MerchantColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _googleSyncEnabled,
              onChanged: _onGoogleSyncToggle,
              activeThumbColor: MerchantColors.gold,
              trackColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? MerchantColors.gold.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditCta() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => widget.onNavigate?.call('storefront'),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [MerchantColors.gold, MerchantColors.goldLight],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storefront_rounded,
                    color: MerchantColors.bgHeader, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Modifier ma vitrine',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: MerchantColors.bgHeader,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Coming-soon sheet ─────────────────────────────────────────────────────────
class _ComingSoonSheet extends StatelessWidget {
  const _ComingSoonSheet({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: MerchantColors.textGrey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Icon(Icons.sync_rounded, color: MerchantColors.gold, size: 42),
          const SizedBox(height: 14),
          Text(
            'En cours de déploiement',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Cette fonctionnalité est en cours de déploiement. Nous vous notifierons dès qu\'elle est disponible.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: MerchantColors.textGrey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [MerchantColors.gold, MerchantColors.goldLight],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Compris',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: MerchantColors.bgHeader,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
