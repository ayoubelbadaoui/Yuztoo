import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/presentation/precache_network_images.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../application/providers.dart';
import 'widgets/storefront_colors.dart';
import 'widgets/banner_section.dart';
import 'widgets/merchant_info_section.dart';
import 'widgets/stats_cards.dart';
import 'widgets/navigation_tabs.dart';
import 'widgets/news_section.dart';
import 'widgets/hours_section.dart';
import 'widgets/storefront_qr_section.dart';
import 'storefront_edit_profile_screen.dart';
import '../application/profile_edit_state.dart';
import '../domain/entities/storefront.dart';
import '../../merchant/application/providers.dart' as merchant_providers;
import '../../storage/application/providers.dart' as storage_providers;

/// Storefront screen - main UI for merchant storefront management
class StorefrontScreen extends ConsumerStatefulWidget {
  const StorefrontScreen({super.key});

  @override
  ConsumerState<StorefrontScreen> createState() => _StorefrontScreenState();
}

class _StorefrontScreenState extends ConsumerState<StorefrontScreen> {
  bool _hoursHydratedFromStorefront = false;
  bool _isUploadingNewsImage = false;
  bool _isUploadingBannerProfile = false;
  bool _isPublishingToggle = false;
  String? _precachedImageKey;
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _uploadNewsImage(Storefront storefront) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1400,
      imageQuality: 86,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploadingNewsImage = true);
    final merchantId = _merchantIdForStorefront(storefront);

    final uploadResult =
        await ref.read(storage_providers.uploadNewsImageProvider).call(
              filePath: picked.path,
              merchantId: merchantId,
            );

    final imageUrl = uploadResult.fold((_) => null, (url) => url);
    if (imageUrl == null) {
      if (!mounted) return;
      setState(() => _isUploadingNewsImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec du téléversement de l\'image')),
      );
      return;
    }

    final updatedUrls = [...storefront.newsImageUrls, imageUrl];
    final result =
        await ref.read(merchant_providers.updateStorefrontProvider).call(
              merchantId: merchantId,
              newsImageUrls: updatedUrls,
            );

    result.fold(
      (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la sauvegarde du contenu')),
        );
      },
      (_) {
        ref.invalidate(storefrontProvider);
      },
    );

    if (mounted) {
      setState(() => _isUploadingNewsImage = false);
    }
  }

  String _merchantIdForStorefront(Storefront storefront) => storefront.id;

  Future<void> _setMerchantPublished(
      Storefront storefront, bool published) async {
    if (storefront.isPublished == published) return;
    final merchantId = _merchantIdForStorefront(storefront);
    if (mounted) setState(() => _isPublishingToggle = true);
    final result =
        await ref.read(merchant_providers.updateStorefrontProvider).call(
              merchantId: merchantId,
              status: published ? 'active' : 'inactive',
            );
    if (mounted) setState(() => _isPublishingToggle = false);

    result.fold(
      (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Impossible de changer la visibilité du commerce')),
        );
      },
      (_) {
        ref.invalidate(storefrontProvider);
      },
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
                _buildImagePickerOption(
                  context,
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
                _buildImagePickerOption(
                  context,
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

  Widget _buildImagePickerOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
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

  Future<void> _pickAndUploadBannerOrProfile(
    Storefront storefront, {
    required bool isBanner,
    required bool fromCamera,
  }) async {
    final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: isBanner ? 1200 : 800,
      maxHeight: isBanner ? 600 : 800,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploadingBannerProfile = true);
    final merchantId = _merchantIdForStorefront(storefront);
    try {
      final result =
          await ref.read(merchant_providers.updateStorefrontProvider).call(
                merchantId: merchantId,
                bannerFilePath: isBanner ? picked.path : null,
                logoFilePath: isBanner ? null : picked.path,
              );

      if (!mounted) return;

      result.fold(
        (failure) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
        },
        (_) {
          ref.invalidate(storefrontProvider);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isBanner
                    ? 'Couverture mise à jour'
                    : 'Photo de profil mise à jour',
              ),
              backgroundColor: StorefrontColors.primaryGold,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingBannerProfile = false);
      }
    }
  }

  Widget _buildAccueilQrSection(Storefront storefront) {
    return StorefrontQrSection(merchantId: storefront.id);
  }

  // ── header (same structure/spacing as other tab pages, cream colors) ────

  Widget _buildHeader() {
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

  Widget _buildStateMessage({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Column(
      children: [
        _buildHeader(),
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
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: StorefrontColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final storefrontAsync = ref.watch(storefrontProvider);
    final activeTab = ref.watch(storefrontTabProvider);

    // When the vitrine refetches (invalidate / autoDispose / resume), clear
    // local UI state so hours and image precache align with fresh Firestore data.
    ref.listen(storefrontProvider, (previous, next) {
      if (next is AsyncLoading) {
        if (mounted) {
          setState(() {
            _hoursHydratedFromStorefront = false;
            _precachedImageKey = null;
          });
        }
      }
    });

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
              return _buildStateMessage(
                icon: Icons.storefront_outlined,
                title: 'Commerce introuvable.',
              );
            }

            if (!storefront.isPublished) {
              return _buildStateMessage(
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
                  if (mounted) setState(() {});
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
                _buildHeader(),
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
                          _buildAccueilQrSection(storefront)
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
          loading: () => Column(
            children: [
              _buildHeader(),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          ),
          error: (error, stack) => _buildStateMessage(
            icon: Icons.error_outline,
            title: 'Impossible de charger la boutique.',
          ),
        ),
      ),
    );
  }
}
