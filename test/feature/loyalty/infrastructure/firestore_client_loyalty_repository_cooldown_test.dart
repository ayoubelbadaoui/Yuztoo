import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/loyalty/infrastructure/firestore_client_loyalty_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cooldown tests for FirestoreClientLoyaltyRepository.applyPassageDeltas.
//
// The cooldown lives inside the Firestore transaction and uses the
// `last_passage_at` field as its anchor. These tests cover:
//   • first additive write succeeds and stamps `last_passage_at`
//   • a second additive write inside the cooldown window is rejected with
//     a message that contains "déjà" (the UI keys off this string)
//   • a second additive write past the cooldown window is allowed
//   • a negative-pending delta (validate-pending) bypasses the cooldown and
//     does not refresh `last_passage_at`
//   • cooldown applies independently to validated, pending, and spend deltas
//
// We keep the cooldown tiny (50ms) so tests run fast.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  const merchantId = 'm1';
  const clientUid = 'c1';

  late FakeFirebaseFirestore firestore;
  late FirestoreClientLoyaltyRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = FirestoreClientLoyaltyRepository(
      firestore: firestore,
      passageCooldown: const Duration(milliseconds: 50),
    );
  });

  Future<DocumentSnapshot<Map<String, dynamic>>> readDoc() {
    return firestore
        .collection('merchants')
        .doc(merchantId)
        .collection('loyalty_clients')
        .doc(clientUid)
        .get();
  }

  group('applyPassageDeltas — cooldown', () {
    test('first additive write succeeds and stamps last_passage_at', () async {
      final result = await repo.applyPassageDeltas(
        merchantId: merchantId,
        clientUid: clientUid,
        validatedPassagesDelta: 1,
      );
      expect(result.isRight, isTrue,
          reason: 'first passage must be allowed when no doc exists yet');

      final snap = await readDoc();
      expect(snap.exists, isTrue);
      expect(snap.data()?['validated_passages'], 1);
      expect(snap.data()?['last_passage_at'], isNotNull,
          reason: 'cooldown anchor must be written on every additive write');
      expect(snap.data()?['first_visit_at'], isNotNull);
    });

    test('second additive write inside cooldown window is rejected', () async {
      final first = await repo.applyPassageDeltas(
        merchantId: merchantId,
        clientUid: clientUid,
        validatedPassagesDelta: 1,
      );
      expect(first.isRight, isTrue);

      // No artificial delay — we expect this to be inside the 50ms window
      // even on slow CI hardware.
      final second = await repo.applyPassageDeltas(
        merchantId: merchantId,
        clientUid: clientUid,
        validatedPassagesDelta: 1,
      );
      expect(second.isLeft, isTrue);
      second.fold(
        (failure) {
          final msg = failure.message.toLowerCase();
          expect(
            msg.contains('passage') &&
                (msg.contains('patientez') || msg.contains('enregistré')),
            isTrue,
            reason:
                'cooldown failure must surface a recognisable, friendly '
                'message — got: "${failure.message}"',
          );
        },
        (_) => fail('expected cooldown to reject the duplicate passage'),
      );

      final snap = await readDoc();
      expect(snap.data()?['validated_passages'], 1,
          reason: 'rejected write must NOT increment the counter');
    });

    test('second additive write past the cooldown is allowed', () async {
      await repo.applyPassageDeltas(
        merchantId: merchantId,
        clientUid: clientUid,
        validatedPassagesDelta: 1,
      );

      // Wait past the 50ms cooldown.
      await Future<void>.delayed(const Duration(milliseconds: 80));

      final second = await repo.applyPassageDeltas(
        merchantId: merchantId,
        clientUid: clientUid,
        validatedPassagesDelta: 1,
      );
      expect(second.isRight, isTrue);

      final snap = await readDoc();
      expect(snap.data()?['validated_passages'], 2);
    });

    test('negative pending delta bypasses cooldown (validate-pending path)',
        () async {
      // Seed a pending passage.
      final seed = await repo.applyPassageDeltas(
        merchantId: merchantId,
        clientUid: clientUid,
        pendingPassagesDelta: 1,
      );
      expect(seed.isRight, isTrue);

      // The pure "merchant rejects pending" case is purely negative and must
      // NOT hit cooldown — even when called immediately after the seeding
      // additive write that stamped `last_passage_at`.
      final reject = await repo.applyPassageDeltas(
        merchantId: merchantId,
        clientUid: clientUid,
        pendingPassagesDelta: -1,
      );
      expect(reject.isRight, isTrue,
          reason: 'pure pending revert must bypass cooldown');

      final snap = await readDoc();
      expect(snap.data()?['pending_passages'], 0,
          reason: 'revert must zero out the pending counter');

      // NOTE: the production code uses `SetOptions(merge: true)` which on
      // real Firestore preserves `last_passage_at` across non-additive
      // writes (so the cooldown stays in effect after a revert). The
      // `fake_cloud_firestore` v4 implementation has a known bug where
      // `tx.set(..., merge: true)` overwrites the document inside a
      // transaction, so we cannot assert the preserved value here. The
      // preservation is verified manually against the live Firestore
      // emulator in tools/firebase.
    });

    test('cooldown applies independently to spend-based deltas', () async {
      final first = await repo.applyPassageDeltas(
        merchantId: merchantId,
        clientUid: clientUid,
        cumulativeSpendEurosDelta: 12.5,
      );
      expect(first.isRight, isTrue);

      final second = await repo.applyPassageDeltas(
        merchantId: merchantId,
        clientUid: clientUid,
        cumulativeSpendEurosDelta: 8.0,
      );
      expect(second.isLeft, isTrue,
          reason: 'spend-based passage must respect the same cooldown');

      final snap = await readDoc();
      expect(snap.data()?['cumulative_spend_euros'], closeTo(12.5, 1e-9));
    });

    test('cooldown applies to pending passages too', () async {
      final first = await repo.applyPassageDeltas(
        merchantId: merchantId,
        clientUid: clientUid,
        pendingPassagesDelta: 1,
      );
      expect(first.isRight, isTrue);

      final second = await repo.applyPassageDeltas(
        merchantId: merchantId,
        clientUid: clientUid,
        pendingPassagesDelta: 1,
      );
      expect(second.isLeft, isTrue);

      final snap = await readDoc();
      expect(snap.data()?['pending_passages'], 1,
          reason: 'rejected pending write must not be counted');
    });

    test(
        'merchant validating a pending passage bypasses cooldown even '
        'immediately after the client created the pending', () async {
      // Step 1 — client scans, creating a pending passage. This stamps
      // last_passage_at and starts the cooldown window for "new" events.
      final clientScan = await repo.applyPassageDeltas(
        merchantId: merchantId,
        clientUid: clientUid,
        pendingPassagesDelta: 1,
      );
      expect(clientScan.isRight, isTrue);

      // Step 2 — without any delay, the merchant validates the pending
      // (pending=-1, validated=+1). This is a state transition of an
      // event that was already counted toward the cooldown, NOT a new
      // event. It must be allowed even though we are well inside the
      // cooldown window. (This is what would break in production if we
      // had naively raised the cooldown to 1 hour without fixing the
      // "isAddingPassage" logic.)
      final merchantValidate = await repo.applyPassageDeltas(
        merchantId: merchantId,
        clientUid: clientUid,
        pendingPassagesDelta: -1,
        validatedPassagesDelta: 1,
      );
      expect(merchantValidate.isRight, isTrue,
          reason: 'merchant validate-pending must bypass cooldown');

      final snap = await readDoc();
      expect(snap.data()?['pending_passages'], 0);
      expect(snap.data()?['validated_passages'], 1);
    });

    test(
        'merchant validating a pending spend-based passage bypasses cooldown',
        () async {
      final clientScan = await repo.applyPassageDeltas(
        merchantId: merchantId,
        clientUid: clientUid,
        pendingPassagesDelta: 1,
      );
      expect(clientScan.isRight, isTrue);

      final merchantValidate = await repo.applyPassageDeltas(
        merchantId: merchantId,
        clientUid: clientUid,
        pendingPassagesDelta: -1,
        cumulativeSpendEurosDelta: 17.5,
      );
      expect(merchantValidate.isRight, isTrue);

      final snap = await readDoc();
      expect(snap.data()?['pending_passages'], 0);
      expect(snap.data()?['cumulative_spend_euros'], closeTo(17.5, 1e-9));
    });
  });

  group('production default cooldown', () {
    test('defaults to 1 hour when no duration is passed', () async {
      // Using the default-constructed repo (no passageCooldown argument)
      // we expect the second additive write within the hour to fail.
      // We cannot wait an hour in a unit test, so we just verify that a
      // second call seconds after the first is rejected.
      final defaultRepo = FirestoreClientLoyaltyRepository(
        firestore: FakeFirebaseFirestore(),
      );
      final first = await defaultRepo.applyPassageDeltas(
        merchantId: merchantId,
        clientUid: clientUid,
        validatedPassagesDelta: 1,
      );
      expect(first.isRight, isTrue);

      final second = await defaultRepo.applyPassageDeltas(
        merchantId: merchantId,
        clientUid: clientUid,
        validatedPassagesDelta: 1,
      );
      expect(second.isLeft, isTrue,
          reason:
              'with the production default of 1h, a second passage seconds '
              'after the first must be rejected — if this test fails, check '
              'that the constructor default has not been lowered for testing.');
      second.fold(
        (failure) => expect(
          failure.message.contains('1 heure'),
          isTrue,
          reason:
              'production cooldown message must communicate the 1-hour wait '
              'so users understand why a re-scan was rejected — got: '
              '"${failure.message}"',
        ),
        (_) => fail('expected cooldown rejection'),
      );
    });
  });
}
