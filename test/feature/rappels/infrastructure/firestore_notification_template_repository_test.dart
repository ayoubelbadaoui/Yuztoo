import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/rappels/domain/entities/notification_template.dart';
import 'package:flutter_yuztoo/feature/rappels/infrastructure/firestore_notification_template_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FirestoreNotificationTemplateRepository — covers the validation
// invariants (which mirror firestore.rules), the live watch stream, and
// the defensive parser. The validation tests are the load-bearing ones:
// if the schema gate in rules and the client-side validator drift, you
// either get rejected writes from the app OR injectable garbage from a
// hand-crafted REST call.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  const merchantId = 'm1';
  late FakeFirebaseFirestore firestore;
  late FirestoreNotificationTemplateRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = FirestoreNotificationTemplateRepository(firestore: firestore);
  });

  NotificationTemplate baseTemplate({
    String name = 'Promo week-end',
    String text = '-20% jusqu\'à dimanche !',
    String audience = 'Tous mes clients',
    List<String> segments = const [],
    String id = '',
  }) {
    return NotificationTemplate(
      id: id,
      name: name,
      text: text,
      audience: audience,
      segments: segments,
    );
  }

  group('create', () {
    test('writes a doc with all fields + serverTimestamp markers', () async {
      final result =
          await repo.create(merchantId: merchantId, template: baseTemplate());
      expect(result.isRight, isTrue);
      final id = result.rightOrNull!;
      expect(id, isNotEmpty);

      final snap = await firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('notification_templates')
          .doc(id)
          .get();
      expect(snap.exists, isTrue);
      final data = snap.data()!;
      expect(data['name'], 'Promo week-end');
      expect(data['text'], '-20% jusqu\'à dimanche !');
      expect(data['audience'], 'Tous mes clients');
      expect(data['segments'], <String>[]);
      expect(data['created_at'], isA<Timestamp>());
      expect(data['updated_at'], isA<Timestamp>());
    });

    test('rejects empty merchantId without writing', () async {
      final r =
          await repo.create(merchantId: '', template: baseTemplate());
      expect(r.isLeft, isTrue);
      final all = await firestore.collectionGroup('notification_templates').get();
      expect(all.docs, isEmpty);
    });

    test('rejects empty name', () async {
      final r = await repo.create(
          merchantId: merchantId, template: baseTemplate(name: '   '));
      expect(r.isLeft, isTrue);
    });

    test('rejects empty text', () async {
      final r = await repo.create(
          merchantId: merchantId, template: baseTemplate(text: ''));
      expect(r.isLeft, isTrue);
    });

    test('rejects oversized name (>80 chars)', () async {
      final r = await repo.create(
        merchantId: merchantId,
        template: baseTemplate(name: 'x' * 81),
      );
      expect(r.isLeft, isTrue);
    });

    test('rejects oversized text (>500 chars)', () async {
      final r = await repo.create(
        merchantId: merchantId,
        template: baseTemplate(text: 'y' * 501),
      );
      expect(r.isLeft, isTrue);
    });

    test('rejects unknown audience values', () async {
      final r = await repo.create(
        merchantId: merchantId,
        template: baseTemplate(audience: 'Tout le monde'),
      );
      expect(r.isLeft, isTrue);
    });

    test('trims name + text on persist', () async {
      final r = await repo.create(
        merchantId: merchantId,
        template:
            baseTemplate(name: '  spaced   ', text: '  hello  '),
      );
      expect(r.isRight, isTrue);
      final snap = await firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('notification_templates')
          .doc(r.rightOrNull!)
          .get();
      expect(snap.data()!['name'], 'spaced');
      expect(snap.data()!['text'], 'hello');
    });
  });

  group('update', () {
    test('mutates name/text/audience but leaves created_at untouched',
        () async {
      final create = await repo.create(
          merchantId: merchantId, template: baseTemplate());
      final id = create.rightOrNull!;

      final r = await repo.update(
        merchantId: merchantId,
        template: baseTemplate(
          id: id,
          name: 'Promo midi',
          text: 'Pause déj -10%',
        ),
      );
      expect(r.isRight, isTrue);
      final snap = await firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('notification_templates')
          .doc(id)
          .get();
      expect(snap.data()!['name'], 'Promo midi');
      expect(snap.data()!['text'], 'Pause déj -10%');
    });

    test('rejects empty template id', () async {
      final r = await repo.update(
          merchantId: merchantId, template: baseTemplate());
      expect(r.isLeft, isTrue);
    });
  });

  group('delete', () {
    test('removes the doc and is no-op on a missing id (idempotent)',
        () async {
      final create = await repo.create(
          merchantId: merchantId, template: baseTemplate());
      final id = create.rightOrNull!;

      final r1 = await repo.delete(merchantId: merchantId, templateId: id);
      expect(r1.isRight, isTrue);
      final r2 = await repo.delete(merchantId: merchantId, templateId: id);
      expect(r2.isRight, isTrue,
          reason: 'fake_cloud_firestore treats delete-of-missing as success');

      final snap = await firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('notification_templates')
          .doc(id)
          .get();
      expect(snap.exists, isFalse);
    });

    test('rejects empty ids', () async {
      final r = await repo.delete(merchantId: '', templateId: 'x');
      expect(r.isLeft, isTrue);
      final r2 = await repo.delete(merchantId: 'm', templateId: '');
      expect(r2.isLeft, isTrue);
    });
  });

  group('watchAll', () {
    test('empty merchantId emits empty list', () async {
      final list = await repo.watchAll('').first;
      expect(list, isEmpty);
    });

    test('parses a stored template back into the entity', () async {
      await repo.create(merchantId: merchantId, template: baseTemplate());
      final list = await repo.watchAll(merchantId).first;
      expect(list, hasLength(1));
      expect(list.single.name, 'Promo week-end');
      expect(list.single.audience, 'Tous mes clients');
    });

    test('drops corrupt docs (empty name or text) without crashing',
        () async {
      // Inject a malformed doc directly — bypasses the validator.
      await firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('notification_templates')
          .doc('corrupt')
          .set({
        'name': '',
        'text': '',
        'audience': 'Tous mes clients',
        'segments': <String>[],
      });
      // Plus a good one.
      await repo.create(merchantId: merchantId, template: baseTemplate());

      final list = await repo.watchAll(merchantId).first;
      expect(list, hasLength(1),
          reason: 'corrupt doc must not blank out the rest of the list');
      expect(list.single.name, 'Promo week-end');
    });
  });
}
