import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/client_notification/infrastructure/firestore_client_notification_repository.dart';

void main() {
  const clientId = 'client_1';
  late FakeFirebaseFirestore firestore;
  late FirestoreClientNotificationRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = FirestoreClientNotificationRepository(firestore: firestore);
  });

  Future<void> seedNotification(String id) async {
    await firestore
        .collection('users')
        .doc(clientId)
        .collection('notifications')
        .doc(id)
        .set({
      'merchant_id': 'm1',
      'merchant_name': 'Shop',
      'type': 'promotion',
      'title': 'Test',
      'body': 'Hello',
      'is_read': false,
      'created_at': Timestamp.now(),
    });
  }

  group('deleteNotification', () {
    test('removes doc from Firestore', () async {
      await seedNotification('n1');
      final result = await repo.deleteNotification(clientId, 'n1');
      expect(result.isRight, isTrue);

      final snap = await firestore
          .collection('users')
          .doc(clientId)
          .collection('notifications')
          .doc('n1')
          .get();
      expect(snap.exists, isFalse);
    });

    test('empty ids is no-op success', () async {
      final result = await repo.deleteNotification('', 'n1');
      expect(result.isRight, isTrue);
    });
  });

  group('deleteAllNotifications', () {
    test('batch-deletes up to watch limit', () async {
      await seedNotification('a');
      await seedNotification('b');

      final result = await repo.deleteAllNotifications(clientId);
      expect(result.isRight, isTrue);

      final snap = await firestore
          .collection('users')
          .doc(clientId)
          .collection('notifications')
          .get();
      expect(snap.docs, isEmpty);
    });
  });
}
