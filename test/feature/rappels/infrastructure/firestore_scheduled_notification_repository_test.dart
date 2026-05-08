import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/rappels/domain/entities/scheduled_notification.dart';
import 'package:flutter_yuztoo/feature/rappels/infrastructure/firestore_scheduled_notification_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FirestoreScheduledNotificationRepository — verifies the schedule /
// cancel contract that the merchant-facing UI sits on top of, and the
// guards that mirror firestore.rules (5-min floor, audience allowlist,
// length cap). The cancel-after-sent test pins the race-window
// behaviour: once the CF flips status to 'sent', the cancel button is
// inert and surfaces a clear error rather than overwriting state.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  const merchantId = 'm1';
  const ownerUid = 'owner1';
  late FakeFirebaseFirestore firestore;
  late FirestoreScheduledNotificationRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = FirestoreScheduledNotificationRepository(firestore: firestore);
  });

  group('schedule', () {
    test('persists the doc with status pending and round-trips on watch',
        () async {
      final at = DateTime.now().add(const Duration(hours: 2));
      final r = await repo.schedule(
        merchantId: merchantId,
        createdByUid: ownerUid,
        text: 'Promo demain',
        audience: 'Tous mes clients',
        segments: const [],
        scheduledAt: at,
      );
      expect(r.isRight, isTrue);

      final list = await repo.watchAll(merchantId).first;
      expect(list, hasLength(1));
      expect(list.single.status, ScheduledNotificationStatus.pending);
      expect(list.single.text, 'Promo demain');
    });

    test('rejects empty text', () async {
      final at = DateTime.now().add(const Duration(hours: 1));
      final r = await repo.schedule(
        merchantId: merchantId,
        createdByUid: ownerUid,
        text: '   ',
        audience: 'Tous mes clients',
        segments: const [],
        scheduledAt: at,
      );
      expect(r.isLeft, isTrue);
    });

    test('rejects text > 500 chars', () async {
      final at = DateTime.now().add(const Duration(hours: 1));
      final r = await repo.schedule(
        merchantId: merchantId,
        createdByUid: ownerUid,
        text: 'x' * 501,
        audience: 'Tous mes clients',
        segments: const [],
        scheduledAt: at,
      );
      expect(r.isLeft, isTrue);
    });

    test('rejects unknown audience', () async {
      final at = DateTime.now().add(const Duration(hours: 1));
      final r = await repo.schedule(
        merchantId: merchantId,
        createdByUid: ownerUid,
        text: 'hi',
        audience: 'Tout le monde',
        segments: const [],
        scheduledAt: at,
      );
      expect(r.isLeft, isTrue);
    });

    test('rejects scheduling within 5 minutes (immediate-send floor)',
        () async {
      final r = await repo.schedule(
        merchantId: merchantId,
        createdByUid: ownerUid,
        text: 'hi',
        audience: 'Tous mes clients',
        segments: const [],
        scheduledAt: DateTime.now().add(const Duration(minutes: 2)),
      );
      expect(r.isLeft, isTrue);
    });

    test('rejects empty merchantId or createdByUid', () async {
      final at = DateTime.now().add(const Duration(hours: 1));
      final r1 = await repo.schedule(
        merchantId: '',
        createdByUid: ownerUid,
        text: 'hi',
        audience: 'Tous mes clients',
        segments: const [],
        scheduledAt: at,
      );
      expect(r1.isLeft, isTrue);
      final r2 = await repo.schedule(
        merchantId: merchantId,
        createdByUid: '',
        text: 'hi',
        audience: 'Tous mes clients',
        segments: const [],
        scheduledAt: at,
      );
      expect(r2.isLeft, isTrue);
    });
  });

  group('cancel', () {
    test('flips pending → cancelled', () async {
      final at = DateTime.now().add(const Duration(hours: 2));
      final create = await repo.schedule(
        merchantId: merchantId,
        createdByUid: ownerUid,
        text: 't',
        audience: 'Tous mes clients',
        segments: const [],
        scheduledAt: at,
      );
      final id = create.rightOrNull!;
      final r = await repo.cancel(merchantId: merchantId, scheduledId: id);
      expect(r.isRight, isTrue);

      final snap = await firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('scheduled_notifications')
          .doc(id)
          .get();
      expect(snap.data()!['status'], 'cancelled');
    });

    test('refuses to overwrite a sent doc (race with the CF)', () async {
      // Direct write to simulate the CF having flipped the doc to sent.
      final ref = await firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('scheduled_notifications')
          .add({
        'text': 'already gone',
        'audience': 'Tous mes clients',
        'segments': <String>[],
        'scheduled_at': Timestamp.now(),
        'status': 'sent',
        'created_by_uid': ownerUid,
        'sent_at': Timestamp.now(),
        'sent_count': 42,
      });

      final r = await repo.cancel(
          merchantId: merchantId, scheduledId: ref.id);
      expect(r.isLeft, isTrue,
          reason:
              'Cancel after sent must surface an error so the UI can '
              'tell the merchant the push already went out.');
      // Doc was NOT mutated — the audit trail stays correct.
      final snap = await ref.get();
      expect(snap.data()!['status'], 'sent');
      expect(snap.data()!['sent_count'], 42);
    });

    test('idempotent on already-cancelled doc', () async {
      final at = DateTime.now().add(const Duration(hours: 2));
      final create = await repo.schedule(
        merchantId: merchantId,
        createdByUid: ownerUid,
        text: 't',
        audience: 'Tous mes clients',
        segments: const [],
        scheduledAt: at,
      );
      final id = create.rightOrNull!;
      await repo.cancel(merchantId: merchantId, scheduledId: id);
      final r2 = await repo.cancel(merchantId: merchantId, scheduledId: id);
      expect(r2.isRight, isTrue);
    });

    test('idempotent on missing doc', () async {
      final r = await repo.cancel(
          merchantId: merchantId, scheduledId: 'nonexistent');
      expect(r.isRight, isTrue);
    });

    test('rejects empty ids', () async {
      final r1 = await repo.cancel(merchantId: '', scheduledId: 'x');
      expect(r1.isLeft, isTrue);
      final r2 = await repo.cancel(merchantId: merchantId, scheduledId: '');
      expect(r2.isLeft, isTrue);
    });
  });

  group('watchAll', () {
    test('orders by scheduled_at ascending so the next-up sits on top',
        () async {
      final later = DateTime.now().add(const Duration(days: 2));
      final sooner = DateTime.now().add(const Duration(hours: 6));
      await repo.schedule(
        merchantId: merchantId,
        createdByUid: ownerUid,
        text: 'later',
        audience: 'Tous mes clients',
        segments: const [],
        scheduledAt: later,
      );
      await repo.schedule(
        merchantId: merchantId,
        createdByUid: ownerUid,
        text: 'sooner',
        audience: 'Tous mes clients',
        segments: const [],
        scheduledAt: sooner,
      );

      final list = await repo.watchAll(merchantId).first;
      expect(list, hasLength(2));
      expect(list.first.text, 'sooner');
      expect(list.last.text, 'later');
    });

    test('drops a doc with unknown status (forward-compat)', () async {
      // A future "paused" status would be invisible to the v1 UI.
      await firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('scheduled_notifications')
          .doc('weird')
          .set({
        'text': 'hi',
        'audience': 'Tous mes clients',
        'segments': <String>[],
        'scheduled_at': Timestamp.now(),
        'status': 'paused',
        'created_by_uid': ownerUid,
      });
      final list = await repo.watchAll(merchantId).first;
      expect(list, isEmpty);
    });
  });
}
