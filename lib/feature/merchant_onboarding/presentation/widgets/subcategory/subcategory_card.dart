import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/shared/widgets/overflow_scroll_text.dart';
import 'subcategory_colors.dart';
import '../../../domain/entities/merchant_subcategory.dart';

/// Maps a business id to a meaningful icon — presentation layer only.
///
/// Ids are prefixed by category (`bouche_*`, `btp_*`, …, see
/// [MerchantSubcategoryCatalog]); a handful of well-known businesses get a
/// dedicated icon, everything else falls back to its category icon.
IconData _iconForSubcategory(String id) {
  // Specific overrides where an obvious glyph exists.
  switch (id) {
    case 'bouche_cafe':
      return Icons.local_cafe_rounded;
    case 'bouche_resto_rapide':
      return Icons.fastfood_rounded;
    case 'bouche_boulangerie':
      return Icons.bakery_dining_rounded;
    case 'bouche_boucherie':
      return Icons.lunch_dining_rounded;
    case 'bouche_poissonnerie':
      return Icons.set_meal_rounded;
    case 'bouche_caviste':
      return Icons.wine_bar_rounded;
    case 'bouche_glacier':
      return Icons.icecream_rounded;
    case 'bouche_traiteur':
      return Icons.delivery_dining_rounded;
    case 'bouche_producteurs':
      return Icons.eco_rounded;
    case 'beaute_coiffeur':
    case 'beaute_barbier':
      return Icons.content_cut_rounded;
    case 'loisirs_fitness':
    case 'loisirs_club_sportif':
      return Icons.fitness_center_rounded;
    case 'loisirs_yoga':
      return Icons.self_improvement_rounded;
    case 'loisirs_hotel':
      return Icons.hotel_rounded;
    case 'servpart_garagiste':
      return Icons.directions_car_rounded;
    case 'servpart_photographe':
    case 'servpro_photo':
      return Icons.photo_camera_rounded;
    case 'sante_pharmacie':
      return Icons.local_pharmacy_rounded;
    case 'sante_veterinaire':
    case 'beaute_toilettage':
      return Icons.pets_rounded;
    case 'btp_electricite':
      return Icons.electrical_services_rounded;
    case 'btp_plomberie':
      return Icons.plumbing_rounded;
    case 'btp_peinture':
      return Icons.format_paint_rounded;
    case 'btp_paysagiste':
    case 'btp_espaces_verts':
      return Icons.grass_rounded;
    case 'servpro_it':
      return Icons.computer_rounded;
    case 'finjur_avocat':
    case 'finjur_notaire':
      return Icons.gavel_rounded;
    case 'livraison_coursier':
      return Icons.two_wheeler_rounded;
  }

  // Category-level fallback via id prefix.
  final prefix = id.contains('_') ? id.substring(0, id.indexOf('_')) : id;
  return switch (prefix) {
    'bouche' => Icons.restaurant_rounded,
    'commerce' => Icons.storefront_rounded,
    'beaute' => Icons.spa_rounded,
    'sante' => Icons.medical_services_rounded,
    'servpart' => Icons.home_repair_service_rounded,
    'loisirs' => Icons.attractions_rounded,
    'assoc' => Icons.groups_rounded,
    'btp' => Icons.construction_rounded,
    'servpro' => Icons.business_center_rounded,
    'grossiste' => Icons.warehouse_rounded,
    'immo' => Icons.apartment_rounded,
    'finjur' => Icons.account_balance_rounded,
    'livraison' => Icons.local_shipping_rounded,
    'indep' => Icons.badge_rounded,
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
                      child: OverflowScrollText(
                        text: subcategory.title,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: SubcategoryColors.textLight,
                          height: 1.25,
                        ),
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
