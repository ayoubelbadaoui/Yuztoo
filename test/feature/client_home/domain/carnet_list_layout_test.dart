import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/client_home/domain/carnet_list_layout.dart';
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
  group('splitCarnetMerchantsForLayout', () {
    test('pins own merchant separately; followed keep relative order', () {
      final split = splitCarnetMerchantsForLayout(
        merchants: [_m('own'), _m('a'), _m('b')],
        ownMerchantId: 'own',
      );
      expect(split.ownMerchant?.id, 'own');
      expect(split.followed.map((m) => m.id), ['a', 'b']);
    });

    test('no own id → all followed', () {
      final split = splitCarnetMerchantsForLayout(
        merchants: [_m('a'), _m('b')],
        ownMerchantId: null,
      );
      expect(split.ownMerchant, isNull);
      expect(split.followed.map((m) => m.id), ['a', 'b']);
    });

    test('own id missing from list → null own', () {
      final split = splitCarnetMerchantsForLayout(
        merchants: [_m('a')],
        ownMerchantId: 'missing',
      );
      expect(split.ownMerchant, isNull);
      expect(split.followed.map((m) => m.id), ['a']);
    });
  });

  group('applyCarnetReorder', () {
    test('keeps own merchant pinned at the end', () {
      final result = applyCarnetReorder(
        orderedIds: ['a', 'b', 'own'],
        ownMerchantId: 'own',
        oldIndex: 0,
        newIndex: 2,
      );
      expect(result, ['b', 'a', 'own']);
    });

    test('reorder without own merchant', () {
      final result = applyCarnetReorder(
        orderedIds: ['a', 'b', 'c'],
        ownMerchantId: null,
        oldIndex: 2,
        newIndex: 0,
      );
      expect(result, ['c', 'a', 'b']);
    });

    test('out-of-range oldIndex is a no-op', () {
      final result = applyCarnetReorder(
        orderedIds: ['a', 'own'],
        ownMerchantId: 'own',
        oldIndex: 5,
        newIndex: 0,
      );
      expect(result, ['a', 'own']);
    });
  });
}
