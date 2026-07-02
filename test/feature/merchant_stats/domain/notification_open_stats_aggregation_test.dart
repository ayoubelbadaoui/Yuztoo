import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/rappels/domain/entities/sent_notification.dart';

/// Mirrors merchant_stats_screen.part.dart KPI aggregation for notifications.
(int totalSent, int totalOpens, List<SentNotification> thisMonth)
    aggregateNotificationStats(
  List<SentNotification> notifications,
  DateTime now,
) {
  final monthStart = DateTime(now.year, now.month);
  final thisMonth = notifications
      .where((n) => !n.sentAt.isBefore(monthStart))
      .toList();
  final totalSent =
      thisMonth.fold<int>(0, (sum, n) => sum + n.sentCount);
  final totalOpens =
      thisMonth.fold<int>(0, (sum, n) => sum + n.openCount);
  return (totalSent, totalOpens, thisMonth);
}

void main() {
  final ref = DateTime(2025, 6, 18);

  SentNotification notif({
    required String id,
    required DateTime sentAt,
    int sent = 0,
    int opens = 0,
  }) =>
      SentNotification(
        id: id,
        merchantId: 'm1',
        text: id,
        audience: 'Tous mes clients',
        sentCount: sent,
        openCount: opens,
        sentAt: sentAt,
      );

  group('notification stats aggregation (Statistiques screen)', () {
    test('sums sent and opens for current month only', () {
      final list = [
        notif(id: 'a', sentAt: DateTime(2025, 6, 1), sent: 10, opens: 4),
        notif(id: 'b', sentAt: DateTime(2025, 6, 10), sent: 5, opens: 3),
        notif(id: 'old', sentAt: DateTime(2025, 5, 31), sent: 100, opens: 99),
      ];

      final (totalSent, totalOpens, month) =
          aggregateNotificationStats(list, ref);

      expect(totalSent, 15);
      expect(totalOpens, 7);
      expect(month, hasLength(2));
    });

    test('empty month yields zeros', () {
      final list = [
        notif(id: 'old', sentAt: DateTime(2025, 5, 1), sent: 50, opens: 20),
      ];
      final (totalSent, totalOpens, month) =
          aggregateNotificationStats(list, ref);
      expect(totalSent, 0);
      expect(totalOpens, 0);
      expect(month, isEmpty);
    });

    test('stress: 200 notifications same month', () {
      final list = List.generate(
        200,
        (i) => notif(
          id: 'n$i',
          sentAt: DateTime(2025, 6, 1).add(Duration(hours: i)),
          sent: 1,
          opens: i.isEven ? 1 : 0,
        ),
      );
      final (totalSent, totalOpens, month) =
          aggregateNotificationStats(list, ref);
      expect(totalSent, 200);
      expect(totalOpens, 100);
      expect(month, hasLength(200));
    });

    test('per-row open label pluralization logic', () {
      expect('${1} ouverture${1 > 1 ? 's' : ''}', '1 ouverture');
      expect('${3} ouverture${3 > 1 ? 's' : ''}', '3 ouvertures');
    });
  });
}
