part of 'merchant_settings_screen.dart';

extension _MerchantSettingsScreenUi on _MerchantSettingsScreenState {
  Widget _buildMerchantSettingsBody(BuildContext context) {
    // Watch the merchant doc and seed local toggle state on first load.
    final merchantAsync = ref.watch(currentMerchantForOwnerProvider);
    merchantAsync.whenData((merchant) {
      if (merchant != null) {
        _seed(
          merchant.messagingEnabled,
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
        systemNavigationBarColor: MerchantColors.bgHeader,
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
    final messaging = _messageConciergerie ?? true;
    final fidelite = _fidelite ?? true;
    final notifications = _notificationsAuto ?? true;
    final galerie = _galerie ?? true;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 80,
      ),
      child: Column(
        children: [
          _buildDescriptionSection(),
          SettingsPreferencesSection(
            onNavigate: widget.onNavigate,
          ),
          _buildInfoBox(),
          SettingsServicesSection(
            services: [
              ServiceToggle(
                icon: Icons.chat_bubble_outline,
                label: 'Message conciergerie',
                value: messaging,
                onChanged: _setMessageConciergerie,
              ),
              ServiceToggle(
                icon: Icons.favorite_outline,
                label: 'Fidélité',
                value: fidelite,
                onChanged: _setFidelite,
                onTap: () => widget.onNavigate?.call('e-fidelite'),
              ),
              ServiceToggle(
                icon: Icons.notifications_outlined,
                label: 'Notifications automatique',
                value: notifications,
                onChanged: _setNotificationsAuto,
              ),
              ServiceToggle(
                icon: Icons.image_outlined,
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

  // ── Loading skeleton (prevents toggle flicker) ────────────────────────────

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
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
              'Paramètres Pro',
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

  Widget _buildDescriptionSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
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
          'Gérez ici tous les paramètres de l\'application',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: MerchantColors.textLightGrey,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MerchantColors.gold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: MerchantColors.gold.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Text(
          'Gardez le contrôle sur vos données et activez vos fonctionnalités préférés.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: MerchantColors.textLightGrey,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showLogoutConfirmationDialog(context);
                if (confirm && mounted) {
                  await ref.read(authControllerProvider.notifier).signOut();
                }
              },
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: Text(
                'Se déconnecter',
                style: GoogleFonts.outfit(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Version 1.0.0',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: MerchantColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}
