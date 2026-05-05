part of 'storefront_screen.dart';

class _StorefrontImagePickerOption extends StatelessWidget {
  const _StorefrontImagePickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 120,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: StorefrontColors.primaryGold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: StorefrontColors.primaryGold.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: StorefrontColors.primaryGold,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: StorefrontColors.navyDark,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: StorefrontColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorefrontScreenHeader extends StatelessWidget {
  const _StorefrontScreenHeader({
    this.isDualProfile = false,
    this.onSwitchRole,
  });

  final bool isDualProfile;
  final VoidCallback? onSwitchRole;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: StorefrontColors.backgroundLight,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: StorefrontColors.backgroundLight,
            border: Border(
              bottom: BorderSide(
                color: StorefrontColors.primaryGold.withValues(alpha: 0.3),
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
                    'Votre vitrine',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: StorefrontColors.textPrimary,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onSwitchRole,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: StorefrontColors.navyDark.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.switch_account,
                      color: StorefrontColors.navyDark,
                      size: 20,
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
}

class _StorefrontStateMessage extends StatelessWidget {
  const _StorefrontStateMessage({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _StorefrontScreenHeader(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 64,
                  color: StorefrontColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: StorefrontColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

extension _StorefrontScreenUi on _StorefrontScreenState {
  Widget _buildStorefrontBody(
    BuildContext context,
    AsyncValue<Storefront?> storefrontAsync,
    String activeTab,
  ) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: StorefrontColors.backgroundLight,
        // iOS: light status area → dark clock/battery (statusBarIconBrightness is Android).
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: StorefrontColors.navyDark,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: StorefrontColors.backgroundLight,
        body: storefrontAsync.when(
          data: (storefront) {
            if (storefront == null) {
              return const _StorefrontStateMessage(
                icon: Icons.storefront_outlined,
                title: 'Commerce introuvable.',
              );
            }

            // Hydrate business hours from Firestore once when storefront has saved hours
            if (storefront.hours != null && !_hoursHydratedFromStorefront) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!_hoursHydratedFromStorefront && storefront.hours != null) {
                  ref
                      .read(businessHoursProvider.notifier)
                      .loadFromMap(storefront.hours);
                  _hoursHydratedFromStorefront = true;
                  if (mounted) _rebuildAfterHoursHydrate();
                }
              });
            }

            final precacheKey =
                '${storefront.bannerImageUrl}|${storefront.profileImageUrl}|${storefront.newsImageUrls.join(',')}';
            if (_precachedImageKey != precacheKey) {
              _precachedImageKey = precacheKey;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                precacheHttpImages(context, [
                  storefront.bannerImageUrl,
                  storefront.profileImageUrl,
                  ...storefront.newsImageUrls,
                ]);
              });
            }

            // Merchant profile exists - show storefront
            return Column(
              children: [
                _StorefrontScreenHeader(
                  isDualProfile: widget.isDualProfile,
                  onSwitchRole: () => widget.onNavigate?.call('switch-to-client'),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 80,
                    ),
                    child: Column(
                      children: [
                        // Offline warning banner — merchant can still edit when hors ligne
                        if (!storefront.isPublished)
                          GestureDetector(
                            onTap: () => _setMerchantPublished(storefront, true),
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3CD),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFFC107).withValues(alpha: 0.6),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.visibility_off_outlined,
                                    color: Color(0xFF856404),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Votre commerce est hors ligne — invisible des clients.',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: const Color(0xFF856404),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF856404),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Mettre en ligne',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Banner with profile picture
                        BannerSection(
                          bannerImageUrl: storefront.bannerImageUrl,
                          profileImageUrl: storefront.profileImageUrl,
                          onBannerEdit: _isUploadingBannerProfile
                              ? null
                              : () {
                                  _showImagePickerDialog(
                                    context,
                                    storefront: storefront,
                                    isBanner: true,
                                  );
                                },
                          onProfileEdit: _isUploadingBannerProfile
                              ? null
                              : () {
                                  _showImagePickerDialog(
                                    context,
                                    storefront: storefront,
                                    isBanner: false,
                                  );
                                },
                        ),
                        const SizedBox(
                            height: 56), // More space after profile picture
                        // Merchant info
                        MerchantInfoSection(
                          merchantName: storefront.merchantName,
                          description: storefront.description,
                          city: storefront.city,
                          loyaltyEnabled: storefront.loyaltyEnabled,
                          loyaltyClientSummary: storefront.loyaltyClientSummary,
                          isVerified: storefront.isVerified,
                          onEdit: () async {
                            await ref
                                .read(storefrontProfileEditProvider.notifier)
                                .initializeFrom(storefront);
                            if (!context.mounted) return;
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const StorefrontEditProfileScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        // Stats cards
                        StatsCards(
                          profileCompletionPercentage:
                              storefront.profileCompletionPercentage,
                          weeklyViews: storefront.weeklyViews,
                          weeklyViewsChange: storefront.weeklyViewsChange,
                        ),
                        const SizedBox(height: 24),
                        // Quick-action row (notifications hub, clients, store preview)
                        _buildQuickActions(context),
                        const SizedBox(height: 24),
                        // Navigation tabs
                        NavigationTabs(
                          activeTab: activeTab,
                          onTabChanged: (tab) {
                            ref.read(storefrontTabProvider.notifier).state =
                                tab;
                          },
                        ),
                        const SizedBox(height: 20),
                        if (activeTab == 'accueil') ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: StorefrontColors.primaryGold
                                      .withValues(alpha: 0.28),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Commerce en ligne',
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: StorefrontColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _isPublishingToggle
                                              ? 'Enregistrement sur Firebase…'
                                              : storefront.isPublished
                                                  ? 'Votre vitrine est visible par les clients'
                                                  : 'Hors ligne — invisible sur Yuztoo',
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            color:
                                                StorefrontColors.textSecondary,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_isPublishingToggle)
                                    const SizedBox(
                                      width: 52,
                                      height: 40,
                                      child: Center(
                                        child: SizedBox(
                                          width: 26,
                                          height: 26,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: StorefrontColors.primaryGold,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    Switch(
                                      value: storefront.isPublished,
                                      onChanged: (v) =>
                                          _setMerchantPublished(storefront, v),
                                      activeThumbColor: Colors.white,
                                      activeTrackColor:
                                          StorefrontColors.primaryGold,
                                      inactiveThumbColor: Colors.white,
                                      inactiveTrackColor: StorefrontColors
                                          .textTertiary
                                          .withValues(alpha: 0.4),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Content based on active tab
                        if (activeTab == 'horaires')
                          HoursSection(merchantId: storefront.id)
                        else if (activeTab == 'accueil')
                          const SizedBox.shrink()
                        else if (activeTab == 'actualite')
                          NewsSection(
                            content: storefront.newsContent,
                            imageUrls: storefront.newsImageUrls,
                            isUploading: _isUploadingNewsImage,
                            showMedia: true,
                            showDescription: false,
                            showUploadButton: true,
                            onUploadImage: () => _uploadNewsImage(storefront),
                            onDeleteImage: (url) =>
                                _deleteNewsImage(storefront, url),
                            onSettings: null,
                          ),
                        const SizedBox(
                            height: 100), // Space for main app bottom nav
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Column(
            children: [
              _StorefrontScreenHeader(),
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: StorefrontColors.primaryGold,
                  ),
                ),
              ),
            ],
          ),
          error: (error, stack) => const _StorefrontStateMessage(
          icon: Icons.error_outline_rounded,
            title: 'Impossible de charger la boutique.',
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _QuickActionButton(
            icon: Icons.notifications_none_rounded,
            label: 'Notifications',
            onTap: () => widget.onNavigate?.call('notifications-hub'),
          ),
          const SizedBox(width: 10),
          _QuickActionButton(
            icon: Icons.people_outline_rounded,
            label: 'Clients',
            onTap: () => widget.onNavigate?.call('clients'),
          ),
          const SizedBox(width: 10),
          _QuickActionButton(
            icon: Icons.visibility_outlined,
            label: 'Aperçu',
            onTap: () => widget.onNavigate?.call('store-preview'),
          ),
          const SizedBox(width: 10),
          _QuickActionButton(
            icon: Icons.local_offer_outlined,
            label: 'Promos',
            onTap: () => widget.onNavigate?.call('promotions'),
          ),
        ],
      ),
    );
  }

  void _showImagePickerDialog(
    BuildContext context, {
    required Storefront storefront,
    required bool isBanner,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              isBanner
                  ? 'Modifier la couverture'
                  : 'Modifier la photo de profil',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: StorefrontColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StorefrontImagePickerOption(
                  icon: Icons.photo_library,
                  label: 'Galerie',
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadBannerOrProfile(
                      storefront,
                      isBanner: isBanner,
                      fromCamera: false,
                    );
                  },
                ),
                _StorefrontImagePickerOption(
                  icon: Icons.camera_alt,
                  label: 'Caméra',
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadBannerOrProfile(
                      storefront,
                      isBanner: isBanner,
                      fromCamera: true,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: StorefrontColors.navyDark),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: StorefrontColors.navyDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}