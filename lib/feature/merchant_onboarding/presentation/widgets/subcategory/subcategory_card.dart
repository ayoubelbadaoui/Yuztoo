import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'subcategory_colors.dart';
import '../../../domain/entities/merchant_subcategory.dart';

/// Maps subcategory id to a meaningful icon — presentation layer only.
IconData _iconForSubcategory(String id) {
  return switch (id) {
    'cafe' => Icons.local_cafe_rounded,
    'restaurant' => Icons.restaurant_rounded,
    'restauration' => Icons.fastfood_rounded,
    'boulangerie' => Icons.bakery_dining_rounded,
    'boucherie' => Icons.lunch_dining_rounded,
    'poissonnerie' => Icons.set_meal_rounded,
    'fromagerie' => Icons.emoji_food_beverage_rounded,
    'confiserie' => Icons.cake_rounded,
    'glacier' => Icons.icecream_rounded,
    'caviste' => Icons.wine_bar_rounded,
    'maraicher' => Icons.grass_rounded,
    'ferme' => Icons.eco_rounded,
    'artisans' => Icons.storefront_rounded,
    'boutique' => Icons.spa_rounded,
    'traiteur' => Icons.delivery_dining_rounded,
    _ => Icons.store_rounded,
  };
}

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
    final catColor = Color(
      int.parse(subcategory.placeholderColorHex.replaceFirst('#', '0xFF')),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + animationDelay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: SubcategoryColors.bgDark2,
            border: Border.all(
              color: isSelected
                  ? SubcategoryColors.primaryGold
                  : SubcategoryColors.borderColor,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: SubcategoryColors.primaryGold.withValues(alpha: 0.22),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  // Icon area
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(13),
                          topRight: Radius.circular(13),
                        ),
                        color: catColor.withValues(alpha: 0.1),
                      ),
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: catColor.withValues(
                                alpha: isSelected ? 0.22 : 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _iconForSubcategory(subcategory.id),
                            size: 22,
                            color: isSelected
                                ? catColor
                                : catColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Title
                  Container(
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: SubcategoryColors.borderColor
                              .withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        subcategory.title,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: SubcategoryColors.textLight,
                          height: 1.25,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),

              // Selection check badge
              if (isSelected)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: SubcategoryColors.primaryGold,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: SubcategoryColors.primaryGold
                              .withValues(alpha: 0.5),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: SubcategoryColors.bgDark1,
                      size: 13,
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
