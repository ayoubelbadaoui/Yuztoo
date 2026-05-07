part of 'merchant_settings_screen.dart';

extension _MerchantSettingsScreenUi on _MerchantSettingsScreenState {
  Widget _buildMerchantSettingsBody(BuildContext context) {
    // Watch the merchant doc and seed local toggle state on first load.
    final merchantAsync = ref.watch(currentMerchantForOwnerProvider);
    merchantAsync.whenData((merchant) {
      if (merchant != null) {
        _seed(
          merchant.loyaltyEnabled,
          merchant.notificationsAutoEnabled,
          merchant.galerieEnabled,
        );
      }
    });

    final isLoading = !_initialised;

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
            _buildHeader(),
            Expanded(
              child: isLoading
                  ? _buildLoadingSkeleton()
                  : _buildContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final fidelite = _fidelite ?? true;
    final notifications = _notificationsAuto ?? true;
    final galerie = _galerie ?? true;
    final merchantAsync = ref.watch(currentMerchantForOwnerProvider);
    final merchant = merchantAsync.valueOrNull;

    return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 80,
      ),
      child: Column(
        children: [
          if (merchant != null) _buildMerchantMiniHeader(merchant.name),
          SettingsPreferencesSection(
            onNavigate: widget.onNavigate,
          ),
          SettingsServicesSection(
            services: [
              ServiceToggle(
                label: 'Fidélité',
                value: fidelite,
                onChanged: _setFidelite,
                onTap: () => widget.onNavigate?.call('e-fidelite'),
              ),
              ServiceToggle(
                label: 'Notifications automatique',
                value: notifications,
                onChanged: _setNotificationsAuto,
              ),
              ServiceToggle(
                label: 'Galerie',
                value: galerie,
                onChanged: _setGalerie,
              ),
            ],
          ),
          _buildLogoutSection(),
        ],
      ),
    );
  }

  Widget _buildMerchantMiniHeader(String name) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MerchantColors.gold.withValues(alpha: MerchantColors.goldBorderAlpha),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: MerchantColors.gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: MerchantColors.gold.withValues(alpha: 0.4), width: 1.5),
            ),
            child: const Icon(Icons.storefront_outlined,
                color: MerchantColors.gold, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded,
                        color: MerchantColors.gold, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Plan Gratuit',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: MerchantColors.gold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Loading skeleton (prevents toggle flicker) ────────────────────────────

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: List.generate(
          6,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
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

  Widget _buildHeader() {
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
                    'Paramètres Pro',
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




  Widget _buildLogoutSection() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(24, 32, 24, 0),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showLogoutConfirmationDialog(context);
                if (confirm && mounted) {
                  await ref.read(authControllerProvider.notifier).signOut();
                }
              },
              icon: const Icon(Icons.logout_rounded,
                  color: Colors.redAccent, size: 20),
              label: Text(
                'Se déconnecter',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Version 1.0.0 · Yuztoo',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: MerchantColors.textGrey.withValues(alpha: 0.5),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
