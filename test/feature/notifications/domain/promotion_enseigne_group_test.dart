import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';
import 'package:flutter_yuztoo/feature/notifications/domain/promotion_enseigne_group.dart';
import 'package:flutter_yuztoo/feature/promotions/domain/entities/promotion.dart';

Merchant _merchant(
  String id, {
  String? displayName,
  String? name,
  String? organizationId,
  String? storeLabel,
  String? subcategoryTitle,
  List<String>? categories,
  String? categoryId,
}) =>
    Merchant(
      id: id,
      ownerUid: 'o-$id',
      name: name ?? id,
      email: '$id@test.com',
      phone: '+33600000000',
      city: 'Belfort',
      displayName: displayName,
      organizationId: organizationId,
      storeLabel: storeLabel,
      subcategoryTitle: subcategoryTitle,
      categories: categories,
      categoryId: categoryId,
    );

Promotion _promo(
  String id,
  String merchantId, {
  String title = 'Offre',
  DateTime? dateTo,
}) =>
    Promotion(
      id: id,
      merchantId: merchantId,
      title: title,
      subtitle: 'Subtitle $id',
      dateFrom: DateTime(2026, 1, 1),
      dateTo: dateTo ?? DateTime(2026, 12, 31),
      selectedClientType: ClientType.gratuit,
      isOnline: true,
    );

void main() {
  group('groupPromotionsByEnseigne', () {
    test('groups multiple promos from the same shop under one enseigne', () {
      final merchants = {
        'oviv': _merchant('oviv', displayName: 'OVIV'),
      };
      final groups = groupPromotionsByEnseigne(
        promotions: [
          _promo('1', 'oviv', title: 'A'),
          _promo('2', 'oviv', title: 'B'),
          _promo('3', 'oviv', title: 'C'),
          _promo('4', 'oviv', title: 'D'),
        ],
        merchantsById: merchants,
      );

      expect(groups, hasLength(1));
      expect(groups.single.title, 'OVIV');
      expect(groups.single.promotions.map((p) => p.id), ['1', '2', '3', '4']);
      expect(groups.single.subtitle, '4 promotions');
    });

    test('keeps two shops as two groups', () {
      final merchants = {
        'a': _merchant('a', displayName: 'Alpha'),
        'b': _merchant('b', displayName: 'Beta'),
      };
      final groups = groupPromotionsByEnseigne(
        promotions: [
          _promo('1', 'a', dateTo: DateTime(2026, 6, 1)),
          _promo('2', 'b', dateTo: DateTime(2026, 7, 1)),
        ],
        merchantsById: merchants,
      );

      expect(groups.map((g) => g.title), ['Beta', 'Alpha']);
    });

    test('merges org-linked stores into one enseigne', () {
      final merchants = {
        'm1': _merchant(
          'm1',
          displayName: 'Boulangerie Dupont',
          organizationId: 'org-dupont',
          storeLabel: 'Centre',
        ),
        'm2': _merchant(
          'm2',
          displayName: 'Boulangerie Dupont',
          organizationId: 'org-dupont',
          storeLabel: 'Gare',
        ),
      };
      final groups = groupPromotionsByEnseigne(
        promotions: [
          _promo('1', 'm1'),
          _promo('2', 'm2'),
        ],
        merchantsById: merchants,
      );

      expect(groups, hasLength(1));
      expect(groups.single.key, 'org:org-dupont');
      expect(groups.single.promotions, hasLength(2));
      expect(groups.single.merchantIds.toSet(), {'m1', 'm2'});
    });
  });

  group('filterPromotionEnseigneGroups', () {
    final merchants = {
      'bakery': _merchant(
        'bakery',
        displayName: 'Pain d Or',
        subcategoryTitle: 'Boulangerie',
        categoryId: 'bouche',
      ),
      'taxi': _merchant(
        'taxi',
        displayName: 'Taxi Express',
        categories: const ['Taxi'],
      ),
    };
    final groups = groupPromotionsByEnseigne(
      promotions: [
        _promo('1', 'bakery', title: '-20% baguette'),
        _promo('2', 'taxi', title: 'Course offerte'),
      ],
      merchantsById: merchants,
    );

    test('empty query returns all groups', () {
      expect(
        filterPromotionEnseigneGroups(
          groups: groups,
          merchantsById: merchants,
          query: '  ',
        ),
        groups,
      );
    });

    test('filters by métier keyword', () {
      final out = filterPromotionEnseigneGroups(
        groups: groups,
        merchantsById: merchants,
        query: 'boulangerie',
      );
      expect(out.map((g) => g.title), ['Pain d Or']);
    });

    test('filters by promo title only keeps matching promos', () {
      final out = filterPromotionEnseigneGroups(
        groups: groups,
        merchantsById: merchants,
        query: 'course',
      );
      expect(out, hasLength(1));
      expect(out.single.title, 'Taxi Express');
      expect(out.single.promotions.single.title, 'Course offerte');
    });
  });
}
