import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';

// Factory: count + resetAt control the quota window.
// Pass resetAt=null to simulate a fresh merchant (never sent a notification).
// Pass resetAt=recent to be within the 7-day rolling window.
Merchant _m(
  int weeklyCount, {
  DateTime? resetAt,
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
    );

/// Recent reset = 1 day ago (within the 7-day window).
DateTime get _recent => DateTime.now().subtract(const Duration(days: 1));

/// Expired reset = 8 days ago (window has expired).
DateTime get _expired => DateTime.now().subtract(const Duration(days: 8));

void main() {
  group('Merchant weekly notification quota — canSendNotification', () {
    // ── No reset yet (fresh merchant) ────────────────────────────────────────

    test('Q_fresh — weeklyNotifResetAt null: always can send regardless of count', () {
      // Fresh merchant: no notifications sent yet in any window.
      expect(_m(0).canSendNotification, isTrue);
      expect(_m(5).canSendNotification, isTrue); // count irrelevant if no window
    });

    // ── Within 7-day window ───────────────────────────────────────────────────

    test('Q1 — 0/5 within window: can send', () {
      expect(_m(0, resetAt: _recent).canSendNotification, isTrue);
    });

    test('Q2 — 4/5 within window: can send', () {
      expect(_m(4, resetAt: _recent).canSendNotification, isTrue);
    });

    test('Q3 — 5/5 within window: CANNOT send (quota reached)', () {
      expect(_m(5, resetAt: _recent).canSendNotification, isFalse);
    });

    test('Q4 — 6/5 within window: CANNOT send (over-count guard)', () {
      // Should never happen in prod but must not allow > 5.
      expect(_m(6, resetAt: _recent).canSendNotification, isFalse);
    });

    // ── Expired window (>= 7 days) ────────────────────────────────────────────

    test('Q_expire — window expired (8 days ago): can send even at count=5', () {
      expect(_m(5, resetAt: _expired).canSendNotification, isTrue);
    });

    // ── Boundary: exactly 7 days ──────────────────────────────────────────────

    test('Q_boundary — exactly 7 days since reset: window treated as expired → can send', () {
      final exactly7 = DateTime.now().subtract(const Duration(days: 7));
      expect(_m(5, resetAt: exactly7).canSendNotification, isTrue);
    });
  });

  group('Merchant weekly notification quota — weeklyQuotaLabel', () {
    // ── No reset yet ──────────────────────────────────────────────────────────

    test('Q6_fresh — no reset: label is "0/5"', () {
      expect(_m(0).weeklyQuotaLabel, '0/5');
    });

    // ── Within window ─────────────────────────────────────────────────────────

    test('Q6 — count=0, within window: "0/5"', () {
      expect(_m(0, resetAt: _recent).weeklyQuotaLabel, '0/5');
    });

    test('Q7 — count=4, within window: "4/5"', () {
      expect(_m(4, resetAt: _recent).weeklyQuotaLabel, '4/5');
    });

    test('Q8 — count=5, within window: "5/5"', () {
      expect(_m(5, resetAt: _recent).weeklyQuotaLabel, '5/5');
    });

    test('Q9 — count=7 (over), within window: clamped to "5/5"', () {
      expect(_m(7, resetAt: _recent).weeklyQuotaLabel, '5/5');
    });

    test('Q10 — count negative, within window: clamped to "0/5"', () {
      expect(_m(-3, resetAt: _recent).weeklyQuotaLabel, '0/5');
    });

    // ── Expired window ────────────────────────────────────────────────────────

    test('Q_expire_label — window expired (8 days): label resets to "0/5"', () {
      // Even if count is 5, expired window shows 0/5 (as if reset occurred).
      expect(_m(5, resetAt: _expired).weeklyQuotaLabel, '0/5');
    });
  });

  group('Quota window: CF reset interaction', () {
    test('After CF resets count to 0 — label shows 0/5 within old window', () {
      // Scenario: merchant sent 5 notifications Thursday (resetAt=1 day ago).
      // CF runs Monday and zeros weekly_notif_sent_count to 0.
      // Dart reads count=0, resetAt=1 day ago → within window → "0/5".
      // canSendNotification → 0 < 5 → true. ✓
      final m = _m(0, resetAt: _recent);
      expect(m.weeklyQuotaLabel, '0/5');
      expect(m.canSendNotification, isTrue);
    });

    test('Next send after CF reset: incrementWeeklyNotifCount re-uses existing window', () {
      // CF zeroed the count. Next notification send:
      // daysSinceReset = 1 day (< 7) → no reset → just increments count to 1.
      // weeklyNotifResetAt stays as before.
      // Dart: count=1, resetAt=1 day → "1/5", canSend=true. ✓
      final m = _m(1, resetAt: _recent);
      expect(m.weeklyQuotaLabel, '1/5');
      expect(m.canSendNotification, isTrue);
    });
  });
}
