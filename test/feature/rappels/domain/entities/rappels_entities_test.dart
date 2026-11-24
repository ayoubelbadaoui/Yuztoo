import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/rappels/domain/entities/active_notification.dart';
import 'package:flutter_yuztoo/feature/rappels/domain/entities/merchant_like_alert.dart';
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

    test('default openCount is 0', () {
      expect(base.openCount, 0);
    });

    test('copyWith openCount preserves other fields', () {
      final copy = base.copyWith(openCount: 12);
      expect(copy.openCount, 12);
      expect(copy.sentCount, 42);
      expect(copy.text, 'Promo du jour');
    });

    test('different openCount breaks equality', () {
      final copy = base.copyWith(openCount: 1);
      expect(copy, isNot(equals(base)));
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

    test('loyaltyRewardReady type stored correctly', () {
      const alert =
          RappelAlert(type: RappelAlertType.loyaltyRewardReady, count: 1);
      expect(alert.type, RappelAlertType.loyaltyRewardReady);
    });

    test('newLikes type stored correctly', () {
      const alert = RappelAlert(type: RappelAlertType.newLikes, count: 3);
      expect(alert.type, RappelAlertType.newLikes);
      expect(alert.count, 3);
    });

    test('RappelAlertType has exactly 3 values', () {
      expect(RappelAlertType.values.length, 3);
    });
  });

  // ── MerchantLikeAlert ─────────────────────────────────────────────────────

  group('MerchantLikeAlert', () {
    final t0 = DateTime(2025, 1, 1, 12);
    final t1 = DateTime(2025, 1, 2, 12);
    final t2 = DateTime(2025, 1, 3, 12);

    MerchantLikeAlert alert({
      required String id,
      required DateTime at,
      MerchantLikeSource source = MerchantLikeSource.promotion,
      String? name,
      String? title,
    }) =>
        MerchantLikeAlert(
          markerId: id,
          source: source,
          viewerUid: 'uid_abcdefgh',
          targetId: 'target_$id',
          createdAt: at,
          displayName: name,
          targetLabel: title,
        );

    test('displayLabel prefers displayName', () {
      expect(alert(id: '1', at: t0, name: 'Marie').displayLabel, 'Marie');
    });

    test('displayLabel falls back to truncated uid', () {
      expect(alert(id: '1', at: t0).displayLabel, '…abcdefgh');
    });

    test('actionLabel for promo with title', () {
      expect(
        alert(id: '1', at: t0, title: 'Soldes').actionLabel,
        'a aimé votre promo Soldes',
      );
    });

    test('actionLabel for promo without title', () {
      expect(alert(id: '1', at: t0).actionLabel, 'a aimé une promo');
    });

    test('actionLabel for news photo', () {
      expect(
        alert(
          id: '1',
          at: t0,
          source: MerchantLikeSource.newsPhoto,
        ).actionLabel,
        'a aimé une actualité',
      );
    });

    test('filterUnseen keeps all when seenAt is null, newest first', () {
      final filtered = filterUnseenMerchantLikeAlerts([
        alert(id: 'old', at: t0),
        alert(id: 'new', at: t2),
        alert(id: 'mid', at: t1),
      ]);
      expect(filtered.map((a) => a.markerId), ['new', 'mid', 'old']);
    });

    test('filterUnseen drops likes at or before watermark', () {
      final filtered = filterUnseenMerchantLikeAlerts(
        [
          alert(id: 'old', at: t0),
          alert(id: 'edge', at: t1),
          alert(id: 'new', at: t2),
        ],
        seenAt: t1,
      );
      expect(filtered.map((a) => a.markerId), ['new']);
    });

    test('filterUnseen merges promo and news and respects limit', () {
      final filtered = filterUnseenMerchantLikeAlerts(
        [
          alert(id: 'p', at: t1),
          alert(
            id: 'n',
            at: t2,
            source: MerchantLikeSource.newsPhoto,
          ),
          alert(id: 'old', at: t0),
        ],
        limit: 2,
      );
      expect(filtered.length, 2);
      expect(filtered[0].markerId, 'n');
      expect(filtered[0].source, MerchantLikeSource.newsPhoto);
      expect(filtered[1].markerId, 'p');
    });
  });
}
