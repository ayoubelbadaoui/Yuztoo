import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/discovery/domain/discovery_merchant_search.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';

Merchant _m({
  required String id,
  String name = 'Shop',
  String? displayName,
  String? categoryId,
  String? subcategoryTitle,
  List<String>? categories,
}) =>
    Merchant(
      id: id,
      ownerUid: 'owner-$id',
      name: name,
      email: '$id@test.com',
      phone: '+33600000000',
      city: 'Belfort',
      status: 'active',
      categoryId: categoryId,
      subcategoryTitle: subcategoryTitle,
      categories: categories,
    );

void main() {
  group('filterDiscoverySearchMerchants', () {
    test('« Café » matches subcategory title Café & Bar', () {
      final out = filterDiscoverySearchMerchants(
        merchants: [
          _m(
            id: 'cafe',
            name: 'Le Comptoir',
            subcategoryTitle: 'Café & Bar',
          ),
          _m(id: 'boul', name: 'Du Pain', subcategoryTitle: 'Boulangerie & Pâtisserie'),
        ],
        query: 'Café',
      );
      expect(out.map((m) => m.id), ['cafe']);
    });

    test('« cafe » matches catalogue id bouche_cafe without subcategory title',
        () {
      final out = filterDiscoverySearchMerchants(
        merchants: [
          _m(id: 'cafe', name: 'Central', categoryId: 'bouche_cafe'),
          _m(id: 'resto', name: 'Brass', categoryId: 'bouche_restaurant'),
        ],
        query: 'cafe',
      );
      expect(out.map((m) => m.id), ['cafe']);
    });

    test('« boulangerie » matches by type not by unrelated name', () {
      final out = filterDiscoverySearchMerchants(
        merchants: [
          _m(id: 'a', name: 'La Boulangerie Martin', subcategoryTitle: 'Boulangerie & Pâtisserie'),
          _m(id: 'b', name: 'El Patia', subcategoryTitle: 'Formation & Professeur particulier'),
        ],
        query: 'boulangerie',
      );
      expect(out.map((m) => m.id), ['a']);
    });

    test('query shorter than 2 normalized chars returns empty', () {
      expect(
        filterDiscoverySearchMerchants(
          merchants: [_m(id: 'x', subcategoryTitle: 'Café & Bar')],
          query: 'c',
        ),
        isEmpty,
      );
    });

    test('« ca » matches commerce names only, not Commerce category noise', () {
      final out = filterDiscoverySearchMerchants(
        merchants: [
          _m(id: 'cadence', name: 'CADENCE'),
          _m(
            id: 'shop',
            name: 'K-NIN STORE',
            categoryId: 'commerce',
            subcategoryTitle: 'Commerce',
          ),
          _m(
            id: 'patia',
            name: 'El Patia',
            subcategoryTitle: 'Formation & Professeur particulier',
          ),
        ],
        query: 'ca',
      );
      expect(out.map((m) => m.id), ['cadence']);
    });

    test('« caf » can match café category by token prefix', () {
      final out = filterDiscoverySearchMerchants(
        merchants: [
          _m(id: 'cafe', name: 'Le Coin', subcategoryTitle: 'Café & Bar'),
          _m(id: 'shop', name: 'K-NIN STORE', categoryId: 'commerce'),
        ],
        query: 'caf',
      );
      expect(out.map((m) => m.id), ['cafe']);
    });
  });
}
