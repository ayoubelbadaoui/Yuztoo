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
    required List<String> linkedProviders,
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
                      _buildLinkedAccountsRow(linkedProviders),
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

  Widget _buildLinkedAccountsRow(List<String> linkedProviders) {
    final googleLinked = linkedProviders.contains('google.com');
    final appleLinked = linkedProviders.contains('apple.com');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: MerchantColors.navyCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MerchantColors.gold.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comptes liés',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            // Google row
            _buildProviderRow(
              icon: Icons.g_mobiledata_rounded,
              label: 'Google',
              isLinked: googleLinked,
              isLoading: _linkingGoogle,
              onLink: googleLinked ? null : _linkGoogle,
            ),
            if (appleLinked) ...[
              const SizedBox(height: 10),
              _buildProviderRow(
                icon: Icons.apple_rounded,
                label: 'Apple',
                isLinked: true,
                isLoading: false,
                onLink: null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProviderRow({
    required IconData icon,
    required String label,
    required bool isLinked,
    required bool isLoading,
    VoidCallback? onLink,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isLinked
                ? const Color(0xFF1A6B3C).withValues(alpha: 0.3)
                : MerchantColors.gold.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isLinked ? const Color(0xFF4CAF50) : MerchantColors.textGrey,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isLinked ? 'Connecté ✓' : 'Non associé',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: isLinked
                      ? const Color(0xFF4CAF50)
                      : MerchantColors.textGrey,
                ),
              ),
            ],
          ),
        ),
        if (!isLinked)
          isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: MerchantColors.gold,
                  ),
                )
              : GestureDetector(
                  onTap: onLink,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [MerchantColors.gold, MerchantColors.goldLight],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Connecter',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: MerchantColors.bgHeader,
                      ),
                    ),
                  ),
                ),
      ],
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

