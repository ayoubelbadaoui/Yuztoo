import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/merchant_onboarding/presentation/widgets/subcategory/merchant_subcategory_catalog.dart';

void main() {
  group('MerchantSubcategoryCatalog', () {
    test('restaurant returns curated list', () {
      final list = MerchantSubcategoryCatalog.forCategory('restaurant');
      expect(list, isNotEmpty,
          reason: 'restaurant is the canonical example with a curated list');
      // Sanity-check a known entry from RestaurantSubcategories.
      expect(list.any((s) => s.id == 'cafe'), isTrue);
    });

    test('hasSubcategoriesFor matches forCategory emptiness', () {
      expect(MerchantSubcategoryCatalog.hasSubcategoriesFor('restaurant'),
          isTrue);
      expect(MerchantSubcategoryCatalog.hasSubcategoriesFor('beauty'), isFalse);
    });

    // The user-reported regression: a beauty / retail / fitness merchant
    // ended up seeing restaurant subcategories ("Boulangerie", "Café",
    // "Glacier", ...) because the screen returned `RestaurantSubcategories.all`
    // unconditionally. This test pins the fix.
    test('non-restaurant categories do NOT leak restaurant subcategories', () {
      for (final id in ['retail', 'beauty', 'fitness', 'services', 'other']) {
        final list = MerchantSubcategoryCatalog.forCategory(id);
        expect(list, isEmpty,
            reason:
                'category "$id" must NOT fall back to the restaurant list — '
                'a beauty salon should not be asked to pick between "café" '
                'and "boulangerie"');
      }
    });

    test('null / empty / unknown category returns empty list', () {
      expect(MerchantSubcategoryCatalog.forCategory(null), isEmpty);
      expect(MerchantSubcategoryCatalog.forCategory(''), isEmpty);
      expect(MerchantSubcategoryCatalog.forCategory('not-a-real-category'),
          isEmpty);
    });
  });
}
