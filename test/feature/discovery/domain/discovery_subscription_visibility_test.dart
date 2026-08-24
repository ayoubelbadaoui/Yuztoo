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

  group('isMerchantVisibleInDiscovery', () {
    test('paid essentiel is always visible', () {
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

    test('paid premium is always visible', () {
      expect(
        isMerchantVisibleInDiscovery(
          merchant: _m(
            id: 'premium',
            plan: MerchantSubscriptionPlan.premium,
            createdAt: DateTime(2020, 1, 1),
          ),
          now: DateTime(2026, 8, 24),
        ),
        isTrue,
      );
    });

    test('gratuit within 3 months stays visible', () {
      expect(
        isMerchantVisibleInDiscovery(
          merchant: _m(id: 'new', createdAt: created),
          now: created.add(const Duration(days: 89)),
        ),
        isTrue,
      );
    });

    test('gratuit exactly at 90 days is still visible', () {
      expect(
        isMerchantVisibleInDiscovery(
          merchant: _m(id: 'edge', createdAt: created),
          now: created.add(const Duration(days: 90)),
        ),
        isTrue,
      );
    });

    test('gratuit after 3 months is hidden', () {
      expect(
        isMerchantVisibleInDiscovery(
          merchant: _m(id: 'old', createdAt: created),
          now: created.add(const Duration(days: 91)),
        ),
        isFalse,
      );
    });

    test('gratuit without created_at stays visible (legacy docs)', () {
      expect(
        isMerchantVisibleInDiscovery(
          merchant: _m(id: 'legacy'),
          now: DateTime(2026, 8, 24),
        ),
        isTrue,
      );
    });
  });

  group('filterDiscoverySubscriptionVisibility', () {
    test('keeps Belfort free merchants inside window and drops expired ones',
        () {
      final out = filterDiscoverySubscriptionVisibility(
        [
          _m(id: 'fresh', createdAt: DateTime(2026, 7, 1)),
          _m(
            id: 'expired',
            createdAt: DateTime(2025, 1, 1),
          ),
          _m(
            id: 'paid',
            plan: MerchantSubscriptionPlan.premium,
            createdAt: DateTime(2020, 1, 1),
          ),
        ],
        now: DateTime(2026, 8, 24),
      );
      expect(out.map((m) => m.id), ['fresh', 'paid']);
    });
  });
}
