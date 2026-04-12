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
  const _StorefrontScreenHeader();

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
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: StorefrontColors.backgroundLight,
        systemNavigationBarIconBrightness: Brightness.dark,
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

            if (!storefront.isPublished) {
              return const _StorefrontStateMessage(
                icon: Icons.visibility_off_outlined,
                title: 'Commerce indisponible.',
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
                const _StorefrontScreenHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 80,
                    ),
                    child: Column(
                      children: [
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
                          StorefrontQrSection(merchantId: storefront.id)
                        else if (activeTab == 'actualite')
                          NewsSection(
                            content: storefront.newsContent,
                            imageUrls: storefront.newsImageUrls,
                            isUploading: _isUploadingNewsImage,
                            showMedia: true,
                            showUploadButton: true,
                            onUploadImage: () => _uploadNewsImage(storefront),
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
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          ),
          error: (error, stack) => const _StorefrontStateMessage(
            icon: Icons.error_outline,
            title: 'Impossible de charger la boutique.',
          ),
        ),
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

