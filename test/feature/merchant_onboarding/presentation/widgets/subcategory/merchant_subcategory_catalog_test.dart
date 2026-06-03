import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/merchant_onboarding/presentation/widgets/subcategory/merchant_subcategory_catalog.dart';
import 'package:flutter_yuztoo/feature/merchant_onboarding/presentation/widgets/subcategory/restaurant_subcategories.dart';

void main() {
  group('MerchantSubcategoryCatalog', () {
    test('restaurant returns curated list', () {
      final list = MerchantSubcategoryCatalog.forCategory('restaurant');
      expect(list, isNotEmpty,
          reason: 'restaurant is the canonical example with a curated list');
      // Sanity-check a known entry from RestaurantSubcategories.
      expect(list.any((s) => s.id == 'cafe'), isTrue);
    });

    // Non-restaurant categories now have their own curated lists. The
    // critical guarantee is that they NEVER fall back to the restaurant
    // list — a beauty salon must not be asked to pick "boulangerie".
    test('retail, beauty, fitness, services have curated, non-restaurant lists',
        () {
      final restaurantIds =
          RestaurantSubcategories.all.map((s) => s.id).toSet();
      for (final id in ['retail', 'beauty', 'fitness', 'services']) {
        final list = MerchantSubcategoryCatalog.forCategory(id);
        expect(list, isNotEmpty,
            reason: 'category "$id" must have a curated subcategory list');
        for (final sub in list) {
          expect(restaurantIds.contains(sub.id), isFalse,
              reason:
                  'category "$id" subcategory "${sub.id}" must NOT match a '
                  'restaurant subcategory id (no cross-category leak)');
        }
      }
    });

    test('"other" stays auto-skipped (no curated list by design)', () {
      // Merchants who pick "Autre" don't fit any bucket — forcing a
      // refinement step would be friction without value. The wizard
      // auto-skips when `forCategory` returns empty.
      expect(MerchantSubcategoryCatalog.forCategory('other'), isEmpty);
      expect(MerchantSubcategoryCatalog.hasSubcategoriesFor('other'), isFalse);
    });

    test('hasSubcategoriesFor matches forCategory emptiness', () {
      expect(MerchantSubcategoryCatalog.hasSubcategoriesFor('restaurant'),
          isTrue);
      expect(MerchantSubcategoryCatalog.hasSubcategoriesFor('beauty'), isTrue);
      expect(MerchantSubcategoryCatalog.hasSubcategoriesFor('other'), isFalse);
    });

    test('null / empty / unknown category returns empty list', () {
      expect(MerchantSubcategoryCatalog.forCategory(null), isEmpty);
      expect(MerchantSubcategoryCatalog.forCategory(''), isEmpty);
      expect(MerchantSubcategoryCatalog.forCategory('not-a-real-category'),
          isEmpty);
    });
  });
}
