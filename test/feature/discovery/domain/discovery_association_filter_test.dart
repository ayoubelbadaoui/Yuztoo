import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/discovery/domain/discovery_association_filter.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';

Merchant _m({
  required String id,
  String status = 'active',
  String? categoryId,
  String? subcategoryTitle,
  List<String>? categories,
}) =>
    Merchant(
      id: id,
      ownerUid: 'o-$id',
      name: id,
      email: '$id@test.com',
      phone: '+33600000000',
      city: 'Paris',
      status: status,
      categoryId: categoryId,
      subcategoryTitle: subcategoryTitle,
      categories: categories,
    );

void main() {
  group('isAssociationOrArtisteMerchant', () {
    test('matches categoryId association', () {
      expect(
        isAssociationOrArtisteMerchant(_m(id: 'a', categoryId: 'association')),
        isTrue,
      );
    });

    test('matches subcategory Artiste', () {
      expect(
        isAssociationOrArtisteMerchant(
          _m(id: 'a', subcategoryTitle: 'Artiste local'),
        ),
        isTrue,
      );
    });

    test('rejects regular commerce', () {
      expect(
        isAssociationOrArtisteMerchant(
          _m(
            id: 'b',
            categoryId: 'bouche',
            subcategoryTitle: 'Boulangerie',
          ),
        ),
        isFalse,
      );
    });
  });

  group('filterAssociationArtisteMerchants', () {
    test('keeps only active association/artiste', () {
      final out = filterAssociationArtisteMerchants([
        _m(id: 'a', categoryId: 'association'),
        _m(id: 'b', categoryId: 'association', status: 'inactive'),
        _m(id: 'c', categoryId: 'commerce'),
        _m(id: 'd', categories: const ['Association sportive']),
      ]);
      expect(out.map((m) => m.id), ['a', 'd']);
    });
  });
}
