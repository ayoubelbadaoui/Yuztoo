import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/rappels/domain/entities/sent_notification.dart';
import 'package:flutter_yuztoo/feature/rappels/infrastructure/firestore_sent_notification_repository.dart';

void main() {
  const merchantId = 'm1';
  late FakeFirebaseFirestore firestore;
  late FirestoreSentNotificationRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = FirestoreSentNotificationRepository(firestore: firestore);
  });

  SentNotification sample({int sentCount = 5, int openCount = 0}) =>
      SentNotification(
        id: '',
        merchantId: merchantId,
        text: 'Flash sale',
        audience: 'Tous mes clients',
        segments: const ['vip'],
        sentCount: sentCount,
        openCount: openCount,
        sentAt: DateTime(2025, 6, 15, 10),
      );

  group('create + list', () {
    test('persists and reads back sent_count and open_count', () async {
      final created = await repo.create(sample(sentCount: 42, openCount: 3));
      expect(created.isRight, isTrue);
      final id = created.fold((_) => '', (n) => n.id);
      expect(id, isNotEmpty);

      // Seed open_count directly (create DTO defaults open_count to 0 in toFirestore)
      await firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('sent_notifications')
          .doc(id)
          .set({'open_count': 3}, SetOptions(merge: true));

      final listed = await repo.list(merchantId, limit: 10);
      expect(listed.isRight, isTrue);
      final items = listed.fold((_) => <SentNotification>[], (l) => l);
      expect(items, hasLength(1));
      expect(items.first.sentCount, 42);
      expect(items.first.openCount, 3);
      expect(items.first.text, 'Flash sale');
      expect(items.first.segments, ['vip']);
    });

    test('empty merchantId returns empty list', () async {
      final result = await repo.list('');
      expect(result.isRight, isTrue);
      expect(result.fold((_) => <SentNotification>[], (l) => l), isEmpty);
    });
  });

  group('updateSentCount', () {
    test('merges sent_count without wiping open_count', () async {
      final created = await repo.create(sample(sentCount: 0));
      final id = created.fold((_) => '', (n) => n.id);

      await firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('sent_notifications')
          .doc(id)
          .set({'open_count': 12}, SetOptions(merge: true));

      await repo.updateSentCount(merchantId, id, 99);

      final snap = await firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('sent_notifications')
          .doc(id)
          .get();
      expect(snap.data()?['sent_count'], 99);
      expect(snap.data()?['open_count'], 12);
    });
  });

  group('recordOpen', () {
    test('increments open_count via FieldValue.increment', () async {
      final created = await repo.create(sample());
      final id = created.fold((_) => '', (n) => n.id);

      await repo.recordOpen(merchantId, id);
      await repo.recordOpen(merchantId, id);

      final snap = await firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('sent_notifications')
          .doc(id)
          .get();
      expect(snap.data()?['open_count'], 2);
    });

    test('empty ids is a no-op', () async {
      await expectLater(repo.recordOpen('', 'x'), completes);
      await expectLater(repo.recordOpen(merchantId, ''), completes);
    });
  });

  group('list ordering stress', () {
    test('returns newest sent_at first up to limit', () async {
      for (var i = 0; i < 25; i++) {
        await firestore
            .collection('merchants')
            .doc(merchantId)
            .collection('sent_notifications')
            .doc('doc_$i')
            .set({
          'merchant_id': merchantId,
          'text': 'Msg $i',
          'sent_count': i,
          'open_count': i * 2,
          'sent_at': Timestamp.fromDate(DateTime(2025, 1, i + 1)),
        });
      }

      final result = await repo.list(merchantId, limit: 20);
      final items = result.fold((_) => <SentNotification>[], (l) => l);
      expect(items, hasLength(20));
      expect(items.first.sentAt.day, 25);
      expect(items.last.sentAt.day, 6);
    });
  });
}
