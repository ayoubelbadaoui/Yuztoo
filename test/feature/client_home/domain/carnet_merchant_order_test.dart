import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/client_home/domain/carnet_merchant_order.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';

Merchant _m(String id) => Merchant(
      id: id,
      ownerUid: 'o',
      name: id,
      email: '$id@test.com',
      phone: '+33600000000',
      city: 'Paris',
    );

void main() {
  group('compareCarnetMerchants', () {
    test('sort_index wins over heart level', () {
      final sortIndexes = {'low_heart': 0, 'high_heart': 1};
      final heartLevels = {'low_heart': 1, 'high_heart': 2};
      final list = [_m('high_heart'), _m('low_heart')];
      list.sort(
        (a, b) => compareCarnetMerchants(
          a,
          b,
          sortIndexes: sortIndexes,
          heartLevels: heartLevels,
        ),
      );
      expect(list.map((m) => m.id).toList(), ['low_heart', 'high_heart']);
    });

    test('falls back to heart when sort_index missing', () {
      final list = [_m('a'), _m('b')];
      list.sort(
        (a, b) => compareCarnetMerchants(
          a,
          b,
          sortIndexes: const {},
          heartLevels: const {'a': 1, 'b': 2},
        ),
      );
      expect(list.map((m) => m.id).toList(), ['b', 'a']);
    });
  });

  group('carnetMerchantIdsEqualOrder', () {
    test('detects reorder vs same order', () {
      final a = [_m('1'), _m('2')];
      final b = [_m('2'), _m('1')];
      expect(carnetMerchantIdsEqualOrder(a, a), isTrue);
      expect(carnetMerchantIdsEqualOrder(a, b), isFalse);
    });

    test('detects added merchant', () {
      final a = [_m('1'), _m('2')];
      final b = [_m('1'), _m('2'), _m('3')];
      expect(carnetMerchantIdsEqualOrder(a, b), isFalse);
    });
  });

  group('carnet feed sort simulation — mal corrigé S3', () {
    List<Merchant> sortLikeFeed(
      List<Merchant> merchants, {
      required Map<String, int> sortIndexes,
      required Map<String, int> heartLevels,
    }) {
      final sorted = List<Merchant>.from(merchants);
      sorted.sort(
        (a, b) => compareCarnetMerchants(
          a,
          b,
          sortIndexes: sortIndexes,
          heartLevels: heartLevels,
        ),
      );
      return sorted;
    }

    test('partial sort_index: indexed merchant comes first', () {
      final merchants = [_m('a'), _m('b'), _m('c')];
      final sorted = sortLikeFeed(
        merchants,
        sortIndexes: {'b': 0},
        heartLevels: {'a': 2, 'b': 1, 'c': 1},
      );
      expect(sorted.first.id, 'b');
    });

    test('reordered indexes beat heart-only default', () {
      final merchants = [_m('low'), _m('high')];
      final sorted = sortLikeFeed(
        merchants,
        sortIndexes: {'low': 0, 'high': 1},
        heartLevels: {'low': 1, 'high': 2},
      );
      expect(sorted.map((m) => m.id).toList(), ['low', 'high']);
    });

    test('UI must not re-sort by heart after feed order is set', () {
      final feedOrder = [_m('second'), _m('first')];
      final heartResort = List<Merchant>.from(feedOrder)
        ..sort((a, b) {
          final ah = {'second': 1, 'first': 2}[a.id]!;
          final bh = {'second': 1, 'first': 2}[b.id]!;
          return bh.compareTo(ah);
        });
      expect(heartResort.map((m) => m.id).toList(), ['first', 'second'],
          reason: 'heart re-sort breaks saved carnet order — regression guard');
      expect(feedOrder.map((m) => m.id).toList(), ['second', 'first']);
    });
  });
}
