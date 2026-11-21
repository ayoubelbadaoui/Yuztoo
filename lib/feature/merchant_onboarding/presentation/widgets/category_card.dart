import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/shared/widgets/overflow_scroll_text.dart';
import '../../../app_media/application/providers.dart';
import '../../../app_media/domain/app_media_slot.dart';
import 'merchant_onboarding_colors.dart';
import '../../domain/entities/merchant_category.dart';

/// Maps a category id to a meaningful icon — presentation layer only.
IconData iconForCategory(String id) {
  return switch (id) {
    // Particuliers (B2C)
    'bouche' => Icons.restaurant_rounded,
    'commerce' => Icons.storefront_rounded,
    'beaute' => Icons.spa_rounded,
    'sante' => Icons.medical_services_rounded,
    'services_particuliers' => Icons.home_repair_service_rounded,
    'loisirs' => Icons.attractions_rounded,
    'association' => Icons.groups_rounded,
    // Professionnels (B2B)
    'artisan_btp' => Icons.construction_rounded,
    'services_pro' => Icons.business_center_rounded,
    'grossiste' => Icons.warehouse_rounded,
    'immobilier' => Icons.apartment_rounded,
    'finance_juridique' => Icons.account_balance_rounded,
    'livraison' => Icons.local_shipping_rounded,
    'independants' => Icons.badge_rounded,
    _ => Icons.apps_rounded,
  };
}

/// Category card widget for merchant onboarding.
///
/// CMS images fill the **top banner placeholder** (100px). The Material icon
/// stays only as the default when no remote image is published for this slot.
class CategoryCard extends ConsumerWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
    required this.animationDelay,
  });

  final MerchantCategory category;
  final bool isSelected;
  final VoidCallback onTap;
  final int animationDelay;

  static const _bannerHeight = 100.0;
  static const _bannerRadius = BorderRadius.only(
    topLeft: Radius.circular(15),
    topRight: Radius.circular(15),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catColor = Color(
      int.parse(category.placeholderColorHex.replaceFirst('#', '0xFF')),
    );
    final icon = iconForCategory(category.id);
    final slotId = AppMediaSlotId.forCategoryId(category.id);
    final asyncUrl = slotId == null
        ? const AsyncValue<String?>.data(null)
        : ref.watch(resolvedAppMediaUrlProvider(slotId));
    final remoteUrl = asyncUrl.asData?.value;
    final hasRemoteImage = remoteUrl != null && remoteUrl.isNotEmpty;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + animationDelay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 24 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: MerchantOnboardingColors.bgDark2,
            border: Border.all(
              color: isSelected
                  ? MerchantOnboardingColors.primaryGold
                  : MerchantOnboardingColors.borderColor,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: MerchantOnboardingColors.primaryGold
                      .withValues(alpha: 0.22),
                  blurRadius: 14,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner placeholder — CMS image fills this zone, not the icon.
                  ClipRRect(
                    borderRadius: _bannerRadius,
                    child: SizedBox(
                      height: _bannerHeight,
                      width: double.infinity,
                      child: hasRemoteImage
                          ? Image.network(
                              remoteUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: _bannerHeight,
                              cacheWidth: (MediaQuery.sizeOf(context).width *
                                      MediaQuery.devicePixelRatioOf(context) *
                                      0.5)
                                  .round()
                                  .clamp(128, 800),
                              filterQuality: FilterQuality.medium,
                              errorBuilder: (_, __, ___) =>
                                  _IconBanner(
                                catColor: catColor,
                                isSelected: isSelected,
                                icon: icon,
                              ),
                            )
                          : _IconBanner(
                              catColor: catColor,
                              isSelected: isSelected,
                              icon: icon,
                            ),
                    ),
                  ),

                  // Text content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OverflowScrollText(
                            text: category.title,
                            maxLines: 2,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: MerchantOnboardingColors.textLight,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          OverflowScrollText(
                            text: category.description,
                            maxLines: 2,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: MerchantOnboardingColors.textGrey,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Selection check badge
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: MerchantOnboardingColors.primaryGold,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: MerchantOnboardingColors.primaryGold
                              .withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: MerchantOnboardingColors.bgDark1,
                      size: 16,
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

/// Default banner: tinted block + circular Material icon (no CMS image yet).
class _IconBanner extends StatelessWidget {
  const _IconBanner({
    required this.catColor,
    required this.isSelected,
    required this.icon,
  });

  final Color catColor;
  final bool isSelected;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: catColor.withValues(alpha: 0.12),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: catColor.withValues(alpha: isSelected ? 0.25 : 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 30,
            color: isSelected ? catColor : catColor.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
