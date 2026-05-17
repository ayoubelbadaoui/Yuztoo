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
  group('HARD: carnet order stability', () {
    test('100 random reorder permutations stay stable after re-sort', () {
      final ids = List.generate(20, (i) => 'm$i');
      final merchants = ids.map(_m).toList();
      final sortIndexes = {for (var i = 0; i < ids.length; i++) ids[i]: i};
      const heartLevels = <String, int>{};

      for (var trial = 0; trial < 100; trial++) {
        final shuffled = List<Merchant>.from(merchants)..shuffle();
        shuffled.sort(
          (a, b) => compareCarnetMerchants(
            a,
            b,
            sortIndexes: sortIndexes,
            heartLevels: heartLevels,
          ),
        );
        expect(
          shuffled.map((e) => e.id).toList(),
          ids,
          reason: 'trial $trial',
        );
      }
    });

    test('heart bump does NOT reorder when sort_index present (mal corrigé)', () {
      final sortIndexes = {'a': 0, 'b': 1, 'c': 2};
      var heartLevels = {'a': 1, 'b': 1, 'c': 1};
      final list = [_m('a'), _m('b'), _m('c')];
      list.sort(
        (a, b) => compareCarnetMerchants(
          a,
          b,
          sortIndexes: sortIndexes,
          heartLevels: heartLevels,
        ),
      );
      expect(list.map((e) => e.id).toList(), ['a', 'b', 'c']);

      // Simulate heart on 'c' — order must NOT change
      heartLevels = {'a': 1, 'b': 1, 'c': 3};
      final list2 = [_m('c'), _m('a'), _m('b')]; // deliberately shuffled
      list2.sort(
        (a, b) => compareCarnetMerchants(
          a,
          b,
          sortIndexes: sortIndexes,
          heartLevels: heartLevels,
        ),
      );
      expect(list2.map((e) => e.id).toList(), ['a', 'b', 'c']);
    });

    test('carnetMerchantIdsEqualOrder detects single swap', () {
      final a = List.generate(50, (i) => _m('m$i'));
      final b = List<Merchant>.from(a);
      b[25] = a[26];
      b[26] = a[25];
      expect(carnetMerchantIdsEqualOrder(a, b), isFalse);
    });

    test('duplicate sort_index values: comparator is deterministic', () {
      final sortIndexes = {'a': 0, 'b': 0, 'c': 1};
      final list = [_m('c'), _m('b'), _m('a')];
      list.sort(
        (x, y) => compareCarnetMerchants(
          x,
          y,
          sortIndexes: sortIndexes,
          heartLevels: const {},
        ),
      );
      // Both a and b have index 0 — order between them is stable (compareTo 0)
      expect(list.first.id, isIn(['a', 'b']));
      expect(list.last.id, 'c');
    });

    test('empty merchant list does not throw', () {
      expect(
        carnetMerchantIdsEqualOrder([], []),
        isTrue,
      );
    });
  });
}
