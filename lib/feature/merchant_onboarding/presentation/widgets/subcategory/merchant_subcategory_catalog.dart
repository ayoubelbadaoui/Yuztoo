import '../../../domain/entities/merchant_subcategory.dart';
import 'beauty_subcategories.dart';
import 'fitness_subcategories.dart';
import 'restaurant_subcategories.dart';
import 'retail_subcategories.dart';
import 'services_subcategories.dart';

/// Lookup of subcategory lists keyed by the top-level merchant category id.
///
/// Adding a new category? Drop its subcategories into this map. Categories
/// that don't have a curated list yet return an empty list — the
/// [SubcategorySelectionScreen] then auto-skips the subcategory step
/// rather than showing an empty grid. This matches the user feedback
/// "les sous catégorie doivent etre en fonction de la catégorie
/// précdemment choise": a merchant who picks "Beauté & Bien-être" no
/// longer sees restaurant subcategories.
class MerchantSubcategoryCatalog {
  MerchantSubcategoryCatalog._();

  /// Returns the curated subcategories for [categoryId], or an empty list
  /// when none are defined. The caller MUST handle the empty case (skip
  /// step / show fallback) rather than rendering a blank grid.
  static List<MerchantSubcategory> forCategory(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return const [];
    switch (categoryId) {
      case 'restaurant':
        return RestaurantSubcategories.all;
      case 'retail':
        return RetailSubcategories.all;
      case 'beauty':
        return BeautySubcategories.all;
      case 'fitness':
        return FitnessSubcategories.all;
      case 'services':
        return ServicesSubcategories.all;
      // "other" intentionally has no curated list — by definition the
      // merchant does not fit any of our buckets, so forcing them through
      // a refinement step would be friction without value. The wizard
      // auto-skips when this returns empty.
      default:
        return const [];
    }
  }

  /// True when the catalog has a non-empty list for [categoryId] — used by
  /// the wizard to decide whether the subcategory step should be rendered
  /// at all.
  static bool hasSubcategoriesFor(String? categoryId) =>
      forCategory(categoryId).isNotEmpty;
}
