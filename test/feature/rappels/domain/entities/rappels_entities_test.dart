import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/rappels/domain/entities/active_notification.dart';
import 'package:flutter_yuztoo/feature/rappels/domain/entities/pending_client_row.dart';
import 'package:flutter_yuztoo/feature/rappels/domain/entities/rappel_alert.dart';
import 'package:flutter_yuztoo/feature/rappels/domain/entities/sent_notification.dart';

void main() {
  // ── ActiveNotification ────────────────────────────────────────────────────

  group('ActiveNotification', () {
    const base = ActiveNotification(
      id: 'n1',
      merchantId: 'm1',
      text: 'Bonjour !',
    );

    test('default values are correct', () {
      expect(base.trigger, 'Date anniversaire client');
      expect(base.audience, 'Tous mes clients');
      expect(base.targetSegments, isEmpty);
      expect(base.isEnabled, isTrue);
      expect(base.createdAt, isNull);
      expect(base.sentCount, 0);
      expect(base.lastSentAt, isNull);
    });

    test('copyWith overrides only specified fields', () {
      final now = DateTime(2025, 6, 1);
      final copy = base.copyWith(
        text: 'Nouveau message',
        isEnabled: false,
        sentCount: 5,
        lastSentAt: now,
      );
      expect(copy.id, 'n1');
      expect(copy.merchantId, 'm1');
      expect(copy.text, 'Nouveau message');
      expect(copy.isEnabled, isFalse);
      expect(copy.sentCount, 5);
      expect(copy.lastSentAt, now);
      // untouched fields:
      expect(copy.trigger, base.trigger);
      expect(copy.audience, base.audience);
    });

    test('copyWith with targetSegments stores the list', () {
      final copy =
          base.copyWith(targetSegments: ['vip', 'habitue']);
      expect(copy.targetSegments, ['vip', 'habitue']);
    });

    test('sentCount increments reflected in copyWith', () {
      final sent = base.copyWith(sentCount: base.sentCount + 1);
      expect(sent.sentCount, 1);
    });
  });

  // ── SentNotification ─────────────────────────────────────────────────────

  group('SentNotification', () {
    final now = DateTime(2025, 4, 22, 10, 0);
    final base = SentNotification(
      id: 's1',
      merchantId: 'm1',
      text: 'Promo du jour',
      audience: 'Tous mes clients',
      sentCount: 42,
      sentAt: now,
    );

    test('default segments is empty', () {
      expect(base.segments, isEmpty);
    });

    test('copyWith preserves untouched fields', () {
      final copy = base.copyWith(sentCount: 100);
      expect(copy.id, 's1');
      expect(copy.merchantId, 'm1');
      expect(copy.text, 'Promo du jour');
      expect(copy.audience, 'Tous mes clients');
      expect(copy.segments, isEmpty);
      expect(copy.sentAt, now);
      expect(copy.sentCount, 100);
    });

    test('copyWith with segments stores list', () {
      final copy = base.copyWith(segments: ['vip']);
      expect(copy.segments, ['vip']);
    });

    test('equality based on all props', () {
      final copy = base.copyWith();
      expect(copy, equals(base));
    });

    test('different sentCount breaks equality', () {
      final copy = base.copyWith(sentCount: 1);
      expect(copy, isNot(equals(base)));
    });
  });

  // ── PendingClientRow ──────────────────────────────────────────────────────

  group('PendingClientRow', () {
    test('displayLabel returns displayName when set', () {
      const row =
          PendingClientRow(clientUid: 'uid123', displayName: 'Marie');
      expect(row.displayLabel, 'Marie');
    });

    test('displayLabel returns last 8 chars of uid when name is null', () {
      const row = PendingClientRow(clientUid: 'abcd1234efgh');
      expect(row.displayLabel, '…1234efgh');
    });

    test('displayLabel returns last 8 chars when name is empty', () {
      const row =
          PendingClientRow(clientUid: 'abcd1234efgh', displayName: '');
      expect(row.displayLabel, '…1234efgh');
    });

    test('short uid gets the ellipsis prefix', () {
      const row = PendingClientRow(clientUid: 'abc');
      expect(row.displayLabel, '…abc');
    });

    test('equality by clientUid + displayName + followedAt', () {
      final a = PendingClientRow(
        clientUid: 'u1',
        displayName: 'Alice',
        followedAt: DateTime(2025, 1, 1),
      );
      final b = PendingClientRow(
        clientUid: 'u1',
        displayName: 'Alice',
        followedAt: DateTime(2025, 1, 1),
      );
      expect(a, equals(b));
    });
  });

  // ── RappelAlert ───────────────────────────────────────────────────────────

  group('RappelAlert', () {
    test('promoExpiring type stored correctly', () {
      const alert = RappelAlert(
        type: RappelAlertType.promoExpiring,
        count: 2,
        detail: 'Expire dans 1 j',
      );
      expect(alert.type, RappelAlertType.promoExpiring);
      expect(alert.count, 2);
      expect(alert.detail, 'Expire dans 1 j');
    });

    test('loyaltyPendingValidation with no detail', () {
      const alert = RappelAlert(
        type: RappelAlertType.loyaltyPendingValidation,
        count: 5,
      );
      expect(alert.type, RappelAlertType.loyaltyPendingValidation);
      expect(alert.count, 5);
      expect(alert.detail, isNull);
    });

    test('loyaltyRewardReady type stored correctly', () {
      const alert =
          RappelAlert(type: RappelAlertType.loyaltyRewardReady, count: 1);
      expect(alert.type, RappelAlertType.loyaltyRewardReady);
    });

    test('RappelAlertType has exactly 3 values', () {
      expect(RappelAlertType.values.length, 3);
    });
  });
}
