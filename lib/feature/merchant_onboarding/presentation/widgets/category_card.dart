import 'package:flutter/material.dart';
import 'merchant_onboarding_colors.dart';
import '../../../merchant_onboarding/domain/entities/merchant_category.dart';

/// Helper to convert hex string to Color
Color _hexToColor(String hex) {
  return Color(int.parse(hex.replaceFirst('#', '0xFF')));
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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + animationDelay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: MerchantOnboardingColors.bgDark2,
            border: Border.all(
              color: isSelected
                  ? MerchantOnboardingColors.primaryGold
                  : MerchantOnboardingColors.borderColor,
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: MerchantOnboardingColors.primaryGold.withOpacity(0.25),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Placeholder
              Container(
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  color: _hexToColor(category.placeholderColorHex).withOpacity(0.3),
                  border: Border(
                    bottom: BorderSide(
                      color: MerchantOnboardingColors.borderColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Stack(
                  children: [
                    // Placeholder icon
                    Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: MerchantOnboardingColors.textGrey.withOpacity(0.3),
                      ),
                    ),
                    // Selection indicator
                    if (isSelected)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: MerchantOnboardingColors.primaryGold,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: MerchantOnboardingColors.primaryGold.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: MerchantOnboardingColors.bgDark1,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        category.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: MerchantOnboardingColors.textLight,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Description
                      Expanded(
                        child: Text(
                          category.description,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: MerchantOnboardingColors.textGrey,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
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

