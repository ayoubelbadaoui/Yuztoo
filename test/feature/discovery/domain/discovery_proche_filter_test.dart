import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/discovery/domain/discovery_proche_filter.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';

Merchant _m(
  String id, {
  String status = 'active',
  String city = 'Paris',
}) =>
    Merchant(
      id: id,
      ownerUid: 'o-$id',
      name: id,
      email: '$id@test.com',
      phone: '+33600000000',
      city: city,
      status: status,
    );

void main() {
  group('filterProcheDeMoiMerchants', () {
    test('keeps only active merchants', () {
      final out = filterProcheDeMoiMerchants(
        cityMerchants: [
          _m('a', status: 'active'),
          _m('b', status: 'inactive'),
          _m('c', status: 'draft'),
        ],
        followedMerchantIds: const {},
      );
      expect(out.map((m) => m.id), ['a']);
    });

    test('excludes followed merchants', () {
      final out = filterProcheDeMoiMerchants(
        cityMerchants: [_m('a'), _m('b'), _m('c')],
        followedMerchantIds: {'b'},
      );
      expect(out.map((m) => m.id), ['a', 'c']);
    });

    test('excludes own store even when active and not followed', () {
      final out = filterProcheDeMoiMerchants(
        cityMerchants: [_m('self'), _m('other')],
        followedMerchantIds: const {},
        currentUserId: 'self',
      );
      expect(out.map((m) => m.id), ['other']);
    });

    test('followed + offline never appears (double exclusion)', () {
      final out = filterProcheDeMoiMerchants(
        cityMerchants: [
          _m('offline-followed', status: 'inactive'),
          _m('online', status: 'active'),
        ],
        followedMerchantIds: {'offline-followed'},
      );
      expect(out.map((m) => m.id), ['online']);
    });

    test('dedupes by id', () {
      final out = filterProcheDeMoiMerchants(
        cityMerchants: [_m('a'), _m('a')],
        followedMerchantIds: const {},
      );
      expect(out.map((m) => m.id), ['a']);
    });

    test('empty city catalogue stays empty', () {
      final out = filterProcheDeMoiMerchants(
        cityMerchants: const [],
        followedMerchantIds: {'x'},
        currentUserId: 'me',
      );
      expect(out, isEmpty);
    });
  });
}
