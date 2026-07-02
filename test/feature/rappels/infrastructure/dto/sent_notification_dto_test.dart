import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/rappels/infrastructure/dto/sent_notification_dto.dart';

void main() {
  group('SentNotificationDto.fromFirestore', () {
    test('maps open_count snake_case field', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('merchants')
          .doc('m1')
          .collection('sent_notifications')
          .doc('s1')
          .set({
        'merchant_id': 'm1',
        'text': 'Bonjour',
        'audience': 'Certains clients',
        'segments': ['vip'],
        'sent_count': 50,
        'open_count': 17,
        'sent_at': Timestamp.fromDate(DateTime(2025, 4, 22)),
      });

      final snap = await firestore
          .collection('merchants')
          .doc('m1')
          .collection('sent_notifications')
          .doc('s1')
          .get();

      final dto = SentNotificationDto.fromFirestore(snap);
      expect(dto.openCount, 17);
      expect(dto.sentCount, 50);
      expect(dto.toDomain().openCount, 17);
    });

    test('missing open_count defaults to 0', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('merchants')
          .doc('m1')
          .collection('sent_notifications')
          .doc('s1')
          .set({
        'merchant_id': 'm1',
        'text': 'x',
        'sent_count': 1,
        'sent_at': Timestamp.now(),
      });

      final snap = await firestore
          .collection('merchants')
          .doc('m1')
          .collection('sent_notifications')
          .doc('s1')
          .get();

      expect(SentNotificationDto.fromFirestore(snap).openCount, 0);
    });

    test('toFirestore includes open_count key', () {
      final dto = SentNotificationDto(
        id: 's1',
        merchantId: 'm1',
        text: 'Hi',
        audience: 'Tous mes clients',
        segments: [],
        sentCount: 3,
        openCount: 2,
        sentAt: DateTime(2025, 1, 1),
      );
      expect(dto.toFirestore().containsKey('open_count'), isTrue);
      expect(dto.toFirestore()['open_count'], 2);
    });
  });
}
