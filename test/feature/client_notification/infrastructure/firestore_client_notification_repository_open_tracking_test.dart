import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/client_notification/infrastructure/firestore_client_notification_repository.dart';

/// Heavy-duty coverage for inbox read → sent_notifications.open_count mirroring
/// promotion view_count tracking.
void main() {
  const clientId = 'client_1';
  const merchantId = 'merchant_1';
  const sentNotifId = 'sent_record_1';

  late FakeFirebaseFirestore firestore;
  late FirestoreClientNotificationRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = FirestoreClientNotificationRepository(firestore: firestore);
  });

  Future<void> seedSentNotification({int openCount = 0}) async {
    await firestore
        .collection('merchants')
        .doc(merchantId)
        .collection('sent_notifications')
        .doc(sentNotifId)
        .set({
      'merchant_id': merchantId,
      'text': 'Promo flash',
      'sent_count': 100,
      'open_count': openCount,
      'sent_at': Timestamp.now(),
    });
  }

  Future<void> seedInboxNotification({
    required String id,
    bool isRead = false,
    String? linkedSentId,
    String? linkedMerchantId,
  }) async {
    await firestore
        .collection('users')
        .doc(clientId)
        .collection('notifications')
        .doc(id)
        .set({
      'client_id': clientId,
      'merchant_id': linkedMerchantId ?? merchantId,
      'merchant_name': 'Shop',
      'type': 'auto',
      'title': 'Shop',
      'body': 'Hello',
      'is_read': isRead,
      if (linkedSentId != null) 'sent_notification_id': linkedSentId,
      'created_at': Timestamp.now(),
    });
  }

  Future<int> readOpenCount() async {
    final snap = await firestore
        .collection('merchants')
        .doc(merchantId)
        .collection('sent_notifications')
        .doc(sentNotifId)
        .get();
    return (snap.data()?['open_count'] as num?)?.toInt() ?? 0;
  }

  group('markAsRead → open_count', () {
    test('increments open_count when linked sent_notification exists', () async {
      await seedSentNotification();
      await seedInboxNotification(
        id: 'n1',
        linkedSentId: sentNotifId,
      );

      final result = await repo.markAsRead(clientId, 'n1');
      expect(result.isRight, isTrue);
      expect(await readOpenCount(), 1);

      final inbox = await firestore
          .collection('users')
          .doc(clientId)
          .collection('notifications')
          .doc('n1')
          .get();
      expect(inbox.data()?['is_read'], isTrue);
    });

    test('does NOT increment when notification was already read', () async {
      await seedSentNotification(openCount: 5);
      await seedInboxNotification(
        id: 'n1',
        isRead: true,
        linkedSentId: sentNotifId,
      );

      await repo.markAsRead(clientId, 'n1');
      expect(await readOpenCount(), 5);
    });

    test('does NOT increment when sent_notification_id is missing', () async {
      await seedSentNotification();
      await seedInboxNotification(id: 'n1');

      await repo.markAsRead(clientId, 'n1');
      expect(await readOpenCount(), 0);
    });

    test('does NOT increment when merchant_id is missing', () async {
      await seedSentNotification();
      await seedInboxNotification(
        id: 'n1',
        linkedSentId: sentNotifId,
        linkedMerchantId: '',
      );

      await repo.markAsRead(clientId, 'n1');
      expect(await readOpenCount(), 0);
    });

    test('double tap (mark read twice) counts only one open', () async {
      await seedSentNotification();
      await seedInboxNotification(
        id: 'n1',
        linkedSentId: sentNotifId,
      );

      await repo.markAsRead(clientId, 'n1');
      await repo.markAsRead(clientId, 'n1');
      expect(await readOpenCount(), 1);
    });

    test('missing inbox doc is a no-op success', () async {
      await seedSentNotification();
      final result = await repo.markAsRead(clientId, 'ghost');
      expect(result.isRight, isTrue);
      expect(await readOpenCount(), 0);
    });

    test('empty clientId or notificationId is a no-op success', () async {
      await seedSentNotification();
      expect((await repo.markAsRead('', 'n1')).isRight, isTrue);
      expect((await repo.markAsRead(clientId, '')).isRight, isTrue);
      expect(await readOpenCount(), 0);
    });
  });

  group('markAllAsRead → open_count batching', () {
    test('increments once per unread linked notification', () async {
      await seedSentNotification();
      await seedInboxNotification(id: 'a', linkedSentId: sentNotifId);
      await seedInboxNotification(id: 'b', linkedSentId: sentNotifId);
      await seedInboxNotification(id: 'c', linkedSentId: sentNotifId);

      final result = await repo.markAllAsRead(clientId);
      expect(result.isRight, isTrue);
      expect(await readOpenCount(), 3);
    });

    test('skips already-read notifications in batch', () async {
      await seedSentNotification(openCount: 2);
      await seedInboxNotification(
        id: 'read',
        isRead: true,
        linkedSentId: sentNotifId,
      );
      await seedInboxNotification(id: 'unread', linkedSentId: sentNotifId);

      await repo.markAllAsRead(clientId);
      expect(await readOpenCount(), 3);
    });

    test('mixed linked and unlinked only counts linked', () async {
      await seedSentNotification();
      await seedInboxNotification(id: 'linked', linkedSentId: sentNotifId);
      await seedInboxNotification(id: 'plain');

      await repo.markAllAsRead(clientId);
      expect(await readOpenCount(), 1);
    });

    test('empty unread set is a no-op success', () async {
      await seedSentNotification(openCount: 7);
      final result = await repo.markAllAsRead(clientId);
      expect(result.isRight, isTrue);
      expect(await readOpenCount(), 7);
    });
  });

  group('markAsRead stress — many clients / campaigns', () {
    test('50 sequential opens on same campaign increment correctly', () async {
      await seedSentNotification();
      for (var i = 0; i < 50; i++) {
        await seedInboxNotification(
          id: 'n$i',
          linkedSentId: sentNotifId,
        );
      }

      for (var i = 0; i < 50; i++) {
        await repo.markAsRead(clientId, 'n$i');
      }
      expect(await readOpenCount(), 50);
    });

    test('two campaigns tracked independently', () async {
      const sentB = 'sent_record_2';
      await seedSentNotification();
      await firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('sent_notifications')
          .doc(sentB)
          .set({
        'merchant_id': merchantId,
        'text': 'Other',
        'sent_count': 10,
        'open_count': 0,
        'sent_at': Timestamp.now(),
      });

      await seedInboxNotification(id: 'a', linkedSentId: sentNotifId);
      await seedInboxNotification(id: 'b', linkedSentId: sentB);
      await seedInboxNotification(id: 'c', linkedSentId: sentNotifId);

      await repo.markAsRead(clientId, 'a');
      await repo.markAsRead(clientId, 'b');
      await repo.markAsRead(clientId, 'c');

      expect(await readOpenCount(), 2);
      final snapB = await firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('sent_notifications')
          .doc(sentB)
          .get();
      expect(snapB.data()?['open_count'], 1);
    });
  });
}
