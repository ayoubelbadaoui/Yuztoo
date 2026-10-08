import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant_subscription_plan.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/notification_quota_policy.dart';

/// Recent reset = 1 day ago (within the 7-day window).
DateTime get _recent => DateTime.now().subtract(const Duration(days: 1));

/// Expired reset = 8 days ago (window has expired).
DateTime get _expired => DateTime.now().subtract(const Duration(days: 8));

/// Quota rules as they will apply once enabled, for a free-plan merchant.
bool _canSend(int count, {DateTime? resetAt}) => canSendManualNotification(
      plan: MerchantSubscriptionPlan.gratuit,
      sentCount: count,
      resetAt: resetAt,
      quotaEnabled: true,
    );

String? _label(int count, {DateTime? resetAt}) => manualNotificationQuotaLabel(
      plan: MerchantSubscriptionPlan.gratuit,
      sentCount: count,
      resetAt: resetAt,
      quotaEnabled: true,
    );

Merchant _merchant(
  int weeklyCount, {
  DateTime? resetAt,
  MerchantSubscriptionPlan plan = MerchantSubscriptionPlan.gratuit,
}) =>
    Merchant(
      id: 'm1',
      name: 'Test',
      email: 'e@e.com',
      phone: '0600000000',
      city: 'Paris',
      ownerUid: 'uid1',
      weeklyNotifSentCount: weeklyCount,
      weeklyNotifResetAt: resetAt,
      subscriptionPlan: plan,
    );

void main() {
  group('Launch phase — quota disabled for everyone', () {
    test('flag is off', () {
      expect(kFreePlanWeeklyNotificationQuotaEnabled, isFalse);
    });

    test('free merchant over 5 sends this week can still send', () {
      final m = _merchant(12, resetAt: _recent);
      expect(m.hasWeeklyNotificationQuota, isFalse);
      expect(m.canSendNotification, isTrue);
      expect(m.weeklyQuotaLabel, isNull);
    });
  });

  group('Paid plans — never limited', () {
    for (final plan in [
      MerchantSubscriptionPlan.essentiel,
      MerchantSubscriptionPlan.premium,
    ]) {
      test('${plan.name}: unlimited even with the quota enabled', () {
        expect(
            weeklyNotificationQuotaApplies(plan, quotaEnabled: true), isFalse);
        expect(
          canSendManualNotification(
            plan: plan,
            sentCount: 50,
            resetAt: _recent,
            quotaEnabled: true,
          ),
          isTrue,
        );
        expect(
          manualNotificationQuotaLabel(
            plan: plan,
            sentCount: 50,
            resetAt: _recent,
            quotaEnabled: true,
          ),
          isNull,
        );
      });
    }
  });

  group('Free plan once enabled — canSend', () {
    test('Q_fresh — no window yet: can send regardless of count', () {
      expect(_canSend(0), isTrue);
      expect(_canSend(5), isTrue);
    });

    test('Q1 — 0/5 within window: can send', () {
      expect(_canSend(0, resetAt: _recent), isTrue);
    });

    test('Q2 — 4/5 within window: can send', () {
      expect(_canSend(4, resetAt: _recent), isTrue);
    });

    test('Q3 — 5/5 within window: CANNOT send (quota reached)', () {
      expect(_canSend(5, resetAt: _recent), isFalse);
    });

    test('Q4 — 6/5 within window: CANNOT send (over-count guard)', () {
      expect(_canSend(6, resetAt: _recent), isFalse);
    });

    test('Q_expire — window expired (8 days ago): can send even at 5', () {
      expect(_canSend(5, resetAt: _expired), isTrue);
    });

    test('Q_boundary — exactly 7 days since reset: window expired', () {
      final exactly7 = DateTime.now().subtract(const Duration(days: 7));
      expect(_canSend(5, resetAt: exactly7), isTrue);
    });
  });

  group('Free plan once enabled — label', () {
    test('Q6_fresh — no window: "0/5"', () {
      expect(_label(0), '0/5');
    });

    test('Q7 — count=4, within window: "4/5"', () {
      expect(_label(4, resetAt: _recent), '4/5');
    });

    test('Q8 — count=5, within window: "5/5"', () {
      expect(_label(5, resetAt: _recent), '5/5');
    });

    test('Q9 — count=7 (over), within window: clamped to "5/5"', () {
      expect(_label(7, resetAt: _recent), '5/5');
    });

    test('Q10 — negative count: clamped to "0/5"', () {
      expect(_label(-3, resetAt: _recent), '0/5');
    });

    test('Q_expire_label — expired window resets to "0/5"', () {
      expect(_label(5, resetAt: _expired), '0/5');
    });
  });
}
