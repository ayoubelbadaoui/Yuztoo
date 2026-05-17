import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/discovery/domain/discovery_recommended_partners.dart';

void main() {
  group('partnerMerchantIdFromFirestore', () {
    test('reads string partner_merchant_id', () {
      expect(
        partnerMerchantIdFromFirestore({'partner_merchant_id': 'imigo-id'}),
        'imigo-id',
      );
    });

    test('trims string ids', () {
      expect(
        partnerMerchantIdFromFirestore({'partner_merchant_id': '  imigo-id  '}),
        'imigo-id',
      );
    });

    test('returns null when missing or empty', () {
      expect(partnerMerchantIdFromFirestore({}), isNull);
      expect(
        partnerMerchantIdFromFirestore({'partner_merchant_id': ''}),
        isNull,
      );
    });
  });

  group('shouldIncludeInDiscoveryRecommendations', () {
    const userId = 'client-1';
    const followed = {'lkhobz-id'};
    const blocked = <String>{};

    test('includes partner not already followed', () {
      expect(
        shouldIncludeInDiscoveryRecommendations(
          partnerMerchantId: 'imigo-id',
          currentUserId: userId,
          followedMerchantIds: followed,
          blockedMerchantIds: blocked,
        ),
        isTrue,
      );
    });

    test('excludes merchants the client already follows', () {
      expect(
        shouldIncludeInDiscoveryRecommendations(
          partnerMerchantId: 'lkhobz-id',
          currentUserId: userId,
          followedMerchantIds: followed,
          blockedMerchantIds: blocked,
        ),
        isFalse,
      );
    });

    test('excludes self and blocked', () {
      expect(
        shouldIncludeInDiscoveryRecommendations(
          partnerMerchantId: 'client-1',
          currentUserId: userId,
          followedMerchantIds: followed,
          blockedMerchantIds: blocked,
        ),
        isFalse,
      );
      expect(
        shouldIncludeInDiscoveryRecommendations(
          partnerMerchantId: 'blocked-id',
          currentUserId: userId,
          followedMerchantIds: followed,
          blockedMerchantIds: {'blocked-id'},
        ),
        isFalse,
      );
    });
  });
}
