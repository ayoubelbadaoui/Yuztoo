import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/discovery/domain/discovery_subscription_visibility.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant_subscription_plan.dart';

Merchant _m({
  required String id,
  MerchantSubscriptionPlan plan = MerchantSubscriptionPlan.gratuit,
  DateTime? createdAt,
}) =>
    Merchant(
      id: id,
      ownerUid: 'owner-$id',
      name: id,
      email: '$id@test.com',
      phone: '+33600000000',
      city: 'Belfort',
      status: 'active',
      createdAt: createdAt,
      subscriptionPlan: plan,
    );

void main() {
  final created = DateTime(2026, 1, 1, 12);

  group('isMerchantVisibleInDiscovery (P3 — active = visible)', () {
    test('paid plans stay visible', () {
      expect(
        isMerchantVisibleInDiscovery(
          merchant: _m(
            id: 'paid',
            plan: MerchantSubscriptionPlan.essentiel,
            createdAt: DateTime(2020, 1, 1),
          ),
          now: DateTime(2026, 8, 24),
        ),
        isTrue,
      );
    });

    test('gratuit older than 90 days stays visible in Découvrir', () {
      expect(
        isMerchantVisibleInDiscovery(
          merchant: _m(id: 'old', createdAt: created),
          now: created.add(const Duration(days: 200)),
        ),
        isTrue,
      );
    });

    test('filter keeps every merchant (subscription no longer gates)', () {
      final out = filterDiscoverySubscriptionVisibility(
        [
          _m(id: 'a', createdAt: created),
          _m(
            id: 'b',
            plan: MerchantSubscriptionPlan.premium,
            createdAt: created,
          ),
          _m(id: 'c', createdAt: created.subtract(const Duration(days: 400))),
        ],
        now: DateTime(2026, 11, 24),
      );
      expect(out.map((m) => m.id), ['a', 'b', 'c']);
    });
  });

  group('isLegacyFreeDiscoveryTrialExpired', () {
    test('true after 90 days for gratuit', () {
      expect(
        isLegacyFreeDiscoveryTrialExpired(
          merchant: _m(id: 'old', createdAt: created),
          now: created.add(const Duration(days: 91)),
        ),
        isTrue,
      );
    });

    test('false for paid even if old', () {
      expect(
        isLegacyFreeDiscoveryTrialExpired(
          merchant: _m(
            id: 'paid',
            plan: MerchantSubscriptionPlan.essentiel,
            createdAt: created,
          ),
          now: created.add(const Duration(days: 400)),
        ),
        isFalse,
      );
    });
  });
}
