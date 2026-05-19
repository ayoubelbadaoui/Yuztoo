import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/loyalty/infrastructure/firestore_client_loyalty_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cooldown tests for FirestoreClientLoyaltyRepository.applyPassageDeltas.
//
// The cooldown lives inside the Firestore transaction and uses the
// `last_passage_at` field as its anchor. Every counter increment is now a
// "new passage event" (the old pending_passages path is gone), so the
// cooldown applies uniformly to validated_passages and cumulative_spend_euros
// writes.
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
  });

  group('production default cooldown', () {
    test('defaults to no cooldown: two rapid passages both succeed', () async {
      final fs = FakeFirebaseFirestore();
      final defaultRepo = FirestoreClientLoyaltyRepository(
        firestore: fs,
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
      expect(second.isRight, isTrue,
          reason:
              'default passageCooldown is Duration.zero — per-passage policy '
              'can be reintroduced later without blocking immediate re-validation.');

      final snap = await fs
          .collection('merchants')
          .doc(merchantId)
          .collection('loyalty_clients')
          .doc(clientUid)
          .get();
      expect(snap.data()?['validated_passages'], 2);
    });
  });
}
