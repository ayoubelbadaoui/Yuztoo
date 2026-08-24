import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/discovery/domain/discovery_association_filter.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';

Merchant _m({
  required String id,
  String status = 'active',
  String city = 'Belfort',
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
      city: city,
      status: status,
      categoryId: categoryId,
      subcategoryTitle: subcategoryTitle,
      categories: categories,
    );

void main() {
  group('isArtisteMerchant', () {
    test('matches subcategory Artiste', () {
      expect(
        isArtisteMerchant(_m(id: 'a', subcategoryTitle: 'Artiste local')),
        isTrue,
      );
    });

    test('rejects association category even with artist in name', () {
      expect(
        isArtisteMerchant(
          _m(
            id: 'a',
            categoryId: 'association',
            subcategoryTitle: 'Association culturelle',
          ),
        ),
        isFalse,
      );
    });

    test('rejects regular commerce', () {
      expect(
        isArtisteMerchant(
          _m(id: 'b', categoryId: 'bouche', subcategoryTitle: 'Boulangerie'),
        ),
        isFalse,
      );
    });
  });

  group('isAssociationMerchant', () {
    test('matches categoryId association', () {
      expect(
        isAssociationMerchant(_m(id: 'a', categoryId: 'association')),
        isTrue,
      );
    });

    test('matches association sportive label', () {
      expect(
        isAssociationMerchant(
          _m(id: 'd', categories: const ['Association sportive']),
        ),
        isTrue,
      );
    });

    test('rejects pure artiste profile', () {
      expect(
        isAssociationMerchant(_m(id: 'a', subcategoryTitle: 'Artiste peintre')),
        isFalse,
      );
    });

    test('rejects regular commerce', () {
      expect(
        isAssociationMerchant(
          _m(id: 'b', categoryId: 'bouche', subcategoryTitle: 'Boulangerie'),
        ),
        isFalse,
      );
    });
  });

  group('filterAssociationMerchants', () {
    test('keeps all active associations in city catalogue including followed',
        () {
      final out = filterAssociationMerchants([
        _m(id: 'a', categoryId: 'association'),
        _m(id: 'b', categoryId: 'association', status: 'inactive'),
        _m(id: 'c', categoryId: 'commerce'),
        _m(id: 'd', categories: const ['Association sportive']),
        _m(id: 'e', subcategoryTitle: 'Artiste local', city: 'Paris'),
      ]);
      expect(out.map((m) => m.id), ['a', 'd']);
    });
  });

  group('filterArtisteMerchants', () {
    test('keeps artistes from any city', () {
      final out = filterArtisteMerchants([
        _m(id: 'a', subcategoryTitle: 'Artiste local', city: 'Paris'),
        _m(id: 'b', subcategoryTitle: 'Artiste', city: 'Belfort'),
        _m(id: 'c', categoryId: 'association', city: 'Belfort'),
        _m(id: 'd', categoryId: 'bouche', city: 'Belfort'),
      ]);
      expect(out.map((m) => m.id), ['a', 'b']);
    });
  });
}
