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

/// Storefront screen - main UI for merchant storefront management
class StorefrontScreen extends ConsumerStatefulWidget {
  const StorefrontScreen({super.key});

  @override
  ConsumerState<StorefrontScreen> createState() => _StorefrontScreenState();
}

class _StorefrontScreenState extends ConsumerState<StorefrontScreen> {
  @override
  void initState() {
    super.initState();
    // Set status bar color to match page background
    // System navigation bar color is handled in main.dart to match bottom nav
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: StorefrontColors.backgroundLight,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: StorefrontColors.navyDark, // Match bottom nav
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  @override
  void dispose() {
    // Don't reset here - let main.dart handle it
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storefront = ref.watch(storefrontProvider);
    final activeTab = ref.watch(storefrontTabProvider);

    return Container(
      color: StorefrontColors.backgroundLight, // Match background to prevent white block
      child: Scaffold(
        backgroundColor: Colors.transparent, // Transparent so container color shows
        body: SafeArea(
          top: true, // Keep safe area for status bar
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Header title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Text(
                    'Votre vitrine en ligne',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      color: StorefrontColors.textPrimary.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Banner with profile picture
                BannerSection(
                  bannerImageUrl: storefront.bannerImageUrl,
                  profileImageUrl: storefront.profileImageUrl,
                ),
                const SizedBox(height: 56), // More space after profile picture
                // Merchant info
                MerchantInfoSection(
                  merchantName: storefront.merchantName,
                  businessActivity: storefront.businessActivity,
                  isVerified: storefront.isVerified,
                  onEdit: () {
                    // Handle edit
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
                const SizedBox(height: 40),
                // Navigation tabs
                NavigationTabs(
                  activeTab: activeTab,
                  onTabChanged: (tab) {
                    ref.read(storefrontTabProvider.notifier).state = tab;
                  },
                ),
                const SizedBox(height: 32),
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
      ),
    );
  }
}

