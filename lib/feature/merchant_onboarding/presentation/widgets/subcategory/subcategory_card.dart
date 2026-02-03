import 'package:flutter/material.dart';
import 'subcategory_colors.dart';
import '../../../domain/entities/merchant_subcategory.dart';

/// Subcategory card widget
class SubcategoryCard extends StatelessWidget {
  const SubcategoryCard({
    super.key,
    required this.subcategory,
    required this.isSelected,
    required this.onTap,
    required this.animationDelay,
  });

  final MerchantSubcategory subcategory;
  final bool isSelected;
  final VoidCallback onTap;
  final int animationDelay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + animationDelay),
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
            color: SubcategoryColors.bgDark2,
            border: Border.all(
              color: isSelected
                  ? SubcategoryColors.primaryGold
                  : SubcategoryColors.borderColor,
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: SubcategoryColors.primaryGold.withOpacity(0.25),
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
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    color: Color(int.parse(subcategory.placeholderColorHex.replaceFirst('#', '0xFF')))
                        .withOpacity(0.3),
                  ),
                  child: Stack(
                    children: [
                      // Placeholder icon
                      Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 32,
                          color: SubcategoryColors.textGrey.withOpacity(0.3),
                        ),
                      ),
                      // Selection indicator
                      if (isSelected)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: SubcategoryColors.primaryGold,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: SubcategoryColors.primaryGold
                                      .withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: SubcategoryColors.bgDark1,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Title
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: SubcategoryColors.borderColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    subcategory.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: SubcategoryColors.textLight,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

