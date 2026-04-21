import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'merchant_onboarding_colors.dart';
import '../../domain/entities/merchant_category.dart';

/// Maps a category id to a meaningful icon — presentation layer only.
IconData _iconForCategory(String id) {
  return switch (id) {
    'restaurant' => Icons.restaurant_rounded,
    'retail' => Icons.store_rounded,
    'beauty' => Icons.spa_rounded,
    'fitness' => Icons.fitness_center_rounded,
    'services' => Icons.handyman_rounded,
    _ => Icons.apps_rounded,
  };
}

/// Category card widget for merchant onboarding
class CategoryCard extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final catColor = Color(
      int.parse(category.placeholderColorHex.replaceFirst('#', '0xFF')),
    );

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
                  // Icon banner
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      color: catColor.withValues(alpha: 0.12),
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: catColor.withValues(
                              alpha: isSelected ? 0.25 : 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _iconForCategory(category.id),
                          size: 30,
                          color: isSelected ? catColor : catColor.withValues(alpha: 0.7),
                        ),
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
                          Text(
                            category.title,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: MerchantOnboardingColors.textLight,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category.description,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: MerchantOnboardingColors.textGrey,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
