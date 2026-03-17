import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../application/providers.dart';
import 'widgets/storefront_colors.dart';
import 'widgets/banner_section.dart';
import 'widgets/merchant_info_section.dart';
import 'widgets/stats_cards.dart';
import 'widgets/navigation_tabs.dart';
import 'widgets/news_section.dart';
import 'widgets/hours_section.dart';
import 'storefront_edit_profile_screen.dart';
import '../application/profile_edit_state.dart';

/// Storefront screen - main UI for merchant storefront management
class StorefrontScreen extends ConsumerStatefulWidget {
  const StorefrontScreen({super.key});

  @override
  ConsumerState<StorefrontScreen> createState() => _StorefrontScreenState();
}

class _StorefrontScreenState extends ConsumerState<StorefrontScreen> {
  bool _hoursHydratedFromStorefront = false;

  @override
  void dispose() {
    super.dispose();
  }

  void _showImagePickerDialog(BuildContext context, {required bool isBanner}) {
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
              isBanner ? 'Modifier la couverture' : 'Modifier la photo de profil',
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
                    // TODO: Implement image picker from gallery
                    _handleImagePick(context, isBanner: isBanner, fromCamera: false);
                  },
                ),
                _buildImagePickerOption(
                  context,
                  icon: Icons.camera_alt,
                  label: 'Caméra',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement image picker from camera
                    _handleImagePick(context, isBanner: isBanner, fromCamera: true);
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

  void _handleImagePick(BuildContext context, {required bool isBanner, required bool fromCamera}) {
    // TODO: Implement actual image picking using image_picker package
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isBanner
              ? 'Modification de la couverture (${fromCamera ? 'Caméra' : 'Galerie'})'
              : 'Modification de la photo de profil (${fromCamera ? 'Caméra' : 'Galerie'})',
        ),
        backgroundColor: StorefrontColors.primaryGold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final storefrontAsync = ref.watch(storefrontProvider);
    final activeTab = ref.watch(storefrontTabProvider);

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
              // No merchant profile yet - show empty state
              return Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.store_outlined,
                            size: 64,
                            color: StorefrontColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun profil commerçant',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: StorefrontColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Créez votre profil pour commencer',
                            style: TextStyle(
                              fontSize: 14,
                              color: StorefrontColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            // Hydrate business hours from Firestore once when storefront has saved hours
            if (storefront.hours != null && !_hoursHydratedFromStorefront) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!_hoursHydratedFromStorefront && storefront.hours != null) {
                  ref.read(businessHoursProvider.notifier).loadFromMap(storefront.hours);
                  _hoursHydratedFromStorefront = true;
                  if (mounted) setState(() {});
                }
              });
            }

            // Merchant profile exists - show storefront
            return Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // Banner with profile picture
                        BannerSection(
                          bannerImageUrl: storefront.bannerImageUrl,
                          profileImageUrl: storefront.profileImageUrl,
                          onBannerEdit: () {
                            _showImagePickerDialog(context, isBanner: true);
                          },
                          onProfileEdit: () {
                            _showImagePickerDialog(context, isBanner: false);
                          },
                        ),
                        const SizedBox(height: 56), // More space after profile picture
                        // Merchant info
                        MerchantInfoSection(
                          merchantName: storefront.merchantName,
                          businessActivity: storefront.businessActivity,
                          isVerified: storefront.isVerified,
                              onEdit: () async {
                                await ref
                                    .read(storefrontProfileEditProvider.notifier)
                                    .initializeFrom(storefront);
                                if (!context.mounted) return;
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const StorefrontEditProfileScreen(),
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
                            ref.read(storefrontTabProvider.notifier).state = tab;
                          },
                        ),
                        const SizedBox(height: 20),
                        // Content based on active tab
                        if (activeTab == 'horaires')
                          const HoursSection()
                        else if (activeTab == 'accueil' || activeTab == 'actualite')
                          NewsSection(
                            content: storefront.newsContent,
                            onSettings: () {
                              // Handle settings
                            },
                          )
                        else
                          NewsSection(
                            content: storefront.newsContent,
                            onSettings: () {
                              // Handle settings
                            },
                          ),
                        const SizedBox(height: 100), // Space for main app bottom nav
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
          error: (error, stack) => Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: StorefrontColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur de chargement',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: StorefrontColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: StorefrontColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
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
}

