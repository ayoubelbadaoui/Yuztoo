import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/loyalty/infrastructure/firestore_client_loyalty_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// claimWelcomeBon — Firestore-backed integration tests
//
// Covers:
//   • happy path: existing doc with first_visit_at → welcome_bon_claimed_at
//     gets stamped and progress.welcomeBonClaimed becomes true
//   • idempotency: a second call after the bon is already claimed returns
//     Right unchanged (NOT an error)
//   • no doc yet → Right: creates loyalty doc and claims on first connexion
//   • doc exists without first_visit_at → Right: stamps both timestamps
//
// Cooldown is unrelated to welcome-bon claim (claim does not write any of
// the additive counters), so we don't test it here.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  const merchantId = 'm1';
  const clientUid = 'c1';

  late FakeFirebaseFirestore firestore;
  late FirestoreClientLoyaltyRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = FirestoreClientLoyaltyRepository(firestore: firestore);
  });

  DocumentReference<Map<String, dynamic>> docRef() => firestore
      .collection('merchants')
      .doc(merchantId)
      .collection('loyalty_clients')
      .doc(clientUid);

  Future<void> seedFirstVisitDoc() async {
    await docRef().set({
      'validated_passages': 1,
      'pending_passages': 0,
      'cumulative_spend_euros': 0,
      'updated_at': FieldValue.serverTimestamp(),
      'first_visit_at': FieldValue.serverTimestamp(),
      'last_passage_at': FieldValue.serverTimestamp(),
    });
  }

  group('claimWelcomeBon', () {
    test('creates loyalty doc and claims when doc does not exist', () async {
      final result = await repo.claimWelcomeBon(
        merchantId: merchantId,
        clientUid: clientUid,
      );
      expect(result.isRight, isTrue);
      result.fold(
        (_) => fail('expected Right when no loyalty doc'),
        (progress) {
          expect(progress.welcomeBonClaimed, isTrue);
          expect(progress.hasFirstVisit, isTrue);
        },
      );

      final snap = await docRef().get();
      expect(snap.exists, isTrue);
      expect(snap.data()?['welcome_bon_claimed_at'], isNotNull);
      expect(snap.data()?['first_visit_at'], isNotNull);
    });

    test('claims when first_visit_at is missing on existing doc', () async {
      await docRef().set({
        'validated_passages': 0,
        'pending_passages': 0,
        'cumulative_spend_euros': 0,
        'updated_at': FieldValue.serverTimestamp(),
      });
      final result = await repo.claimWelcomeBon(
        merchantId: merchantId,
        clientUid: clientUid,
      );
      expect(result.isRight, isTrue);
      result.fold(
        (_) => fail('expected Right when claiming without first_visit_at'),
        (progress) {
          expect(progress.welcomeBonClaimed, isTrue);
          expect(progress.hasFirstVisit, isTrue);
        },
      );

      final snap = await docRef().get();
      expect(snap.data()?['welcome_bon_claimed_at'], isNotNull);
      expect(snap.data()?['first_visit_at'], isNotNull);
    });

    test('happy path: stamps welcome_bon_claimed_at and reports claimed',
        () async {
      await seedFirstVisitDoc();
      final result = await repo.claimWelcomeBon(
        merchantId: merchantId,
        clientUid: clientUid,
      );
      expect(result.isRight, isTrue);
      result.fold(
        (_) => fail('expected Right on happy path'),
        (progress) {
          expect(progress.welcomeBonClaimed, isTrue);
          expect(progress.hasFirstVisit, isTrue);
        },
      );

      final snap = await docRef().get();
      expect(snap.data()?['welcome_bon_claimed_at'], isNotNull);
    });

    test('idempotency: claim on an already-claimed doc returns Right', () async {
      // Seed a doc that is already in the "claimed" state. We can't test
      // claim-then-reclaim end-to-end through the fake because
      // fake_cloud_firestore v4 has a known bug where `tx.set(merge: true)`
      // wipes fields not in the merge map (see the cooldown test file).
      // Real Firestore preserves them, so the production idempotent branch
      // (`if (data['welcome_bon_claimed_at'] != null) return _fromMap(data)`)
      // works correctly there.
      final claimedAt = Timestamp.now();
      await docRef().set({
        'validated_passages': 1,
        'pending_passages': 0,
        'cumulative_spend_euros': 0,
        'updated_at': FieldValue.serverTimestamp(),
        'first_visit_at': FieldValue.serverTimestamp(),
        'last_passage_at': FieldValue.serverTimestamp(),
        'welcome_bon_claimed_at': claimedAt,
      });

      final result = await repo.claimWelcomeBon(
        merchantId: merchantId,
        clientUid: clientUid,
      );
      expect(result.isRight, isTrue,
          reason:
              'a claim against an already-claimed doc must short-circuit to '
              'Right, not surface an error to the user');
      result.fold(
        (_) => fail('expected Right on idempotent reclaim'),
        (progress) => expect(progress.welcomeBonClaimed, isTrue),
      );

      // The original timestamp must NOT be overwritten by the idempotent path.
      final stampAfter =
          (await docRef().get()).data()?['welcome_bon_claimed_at']
              as Timestamp;
      expect(stampAfter, equals(claimedAt));
    });

    test('rejects empty merchantId', () async {
      final result = await repo.claimWelcomeBon(
        merchantId: '',
        clientUid: clientUid,
      );
      expect(result.isLeft, isTrue);
    });

    test('rejects empty clientUid', () async {
      final result = await repo.claimWelcomeBon(
        merchantId: merchantId,
        clientUid: '',
      );
      expect(result.isLeft, isTrue);
    });
  });
}
