import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/merchant_onboarding/domain/entities/merchant_audience.dart';
import 'package:flutter_yuztoo/feature/merchant_onboarding/presentation/widgets/merchant_category_catalog.dart';
import 'package:flutter_yuztoo/feature/merchant_onboarding/presentation/widgets/subcategory/merchant_subcategory_catalog.dart';

void main() {
  group('MerchantCategoryCatalog', () {
    test('both audiences expose a non-empty category grid', () {
      for (final audience in MerchantAudience.values) {
        expect(MerchantCategoryCatalog.forAudience(audience), isNotEmpty,
            reason: 'audience "$audience" must have categories');
      }
    });

    test('category ids are unique across both audiences', () {
      final all = [
        ...MerchantCategoryCatalog.particuliers,
        ...MerchantCategoryCatalog.professionnels,
      ];
      final ids = all.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'duplicate category id would corrupt the business lookup');
    });

    test('audience → merchant_type mapping matches persisted vocabulary', () {
      // merchant_type only accepts 'b2c'/'b2b' (see
      // MerchantOnboardingData.setMerchantType which drops other values).
      expect(MerchantAudience.particuliers.merchantTypeValue, 'b2c');
      expect(MerchantAudience.professionnels.merchantTypeValue, 'b2b');
    });
  });

  group('MerchantSubcategoryCatalog', () {
    test('every category except free-text "Autre" has a curated business list',
        () {
      final all = [
        ...MerchantCategoryCatalog.particuliers,
        ...MerchantCategoryCatalog.professionnels,
      ];
      for (final category in all) {
        final list = MerchantSubcategoryCatalog.forCategory(category.id);
        if (MerchantCategoryCatalog.isOtherCategoryId(category.id)) {
          // Free-text "Autre" — profile shows a text field; wizard auto-skips.
          expect(list, isEmpty);
          expect(
              MerchantSubcategoryCatalog.hasSubcategoriesFor(category.id),
              isFalse);
        } else {
          expect(list, isNotEmpty,
              reason:
                  'category "${category.id}" must have a curated business list');
        }
      }
    });

    test('business ids are globally unique and prefixed per category', () {
      final all = [
        ...MerchantCategoryCatalog.particuliers,
        ...MerchantCategoryCatalog.professionnels,
      ];
      final seen = <String>{};
      for (final category in all) {
        for (final business
            in MerchantSubcategoryCatalog.forCategory(category.id)) {
          expect(seen.add(business.id), isTrue,
              reason:
                  'business id "${business.id}" must be unique across all '
                  'categories (e.g. "Coach professionnel" exists in both '
                  'services pro and indépendants)');
        }
      }
    });

    test('known sheet entries resolve to the right category', () {
      final bouche = MerchantSubcategoryCatalog.forCategory('bouche');
      expect(bouche.any((s) => s.title == 'Restaurant & Brasserie'), isTrue);
      expect(bouche.any((s) => s.title == 'Boulangerie & Pâtisserie'), isTrue);

      final btp = MerchantSubcategoryCatalog.forCategory('artisan_btp');
      expect(btp.any((s) => s.title == 'Plomberie'), isTrue);
      expect(btp.last.title, 'Autre métier du bâtiment',
          reason: '« Autre… » entries are moved to the end of each list');
    });

    test('legacy category ids no longer resolve (clean break)', () {
      for (final legacy in ['restaurant', 'retail', 'beauty', 'fitness',
          'services', 'other']) {
        expect(MerchantSubcategoryCatalog.forCategory(legacy), isEmpty);
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
