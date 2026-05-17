import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/followed_merchants/infrastructure/firestore_followed_merchants_repository.dart';
import 'package:flutter_yuztoo/feature/rappels/infrastructure/firestore_rappels_pending_client_repository.dart';

/// Regression: update() on missing doc used to fail silently in production.
void main() {
  const userId = 'user_phase_b';

  late FakeFirebaseFirestore firestore;
  late FirestoreFollowedMerchantsRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = FirestoreFollowedMerchantsRepository(
      firestore: firestore,
      pendingClientRepo: FirestoreRappelsPendingClientRepository(
        firestore: firestore,
      ),
    );
  });

  test('update on non-existent doc fails; merge-set succeeds (Phase B)', () async {
    final ref = firestore
        .collection('users')
        .doc(userId)
        .collection('followed_merchants')
        .doc('ghost');

    await expectLater(
      () => ref.update({'sort_index': 0}),
      throwsA(isA<FirebaseException>()),
    );

    final result = await repo.updateSortOrder(userId, {'ghost': 0});
    expect(result.isRight, isTrue);

    final snap = await ref.get();
    expect(snap.exists, isTrue);
    expect(snap.data()?['sort_index'], 0);
    expect(snap.data()?['merchant_id'], 'ghost');
  });

  test('batch reorder updates multiple docs atomically', () async {
    for (var i = 0; i < 3; i++) {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('followed_merchants')
          .doc('m$i')
          .set({'merchant_id': 'm$i', 'heart_level': 1, 'sort_index': i});
    }

    final result = await repo.updateSortOrder(userId, {
      'm0': 2,
      'm1': 0,
      'm2': 1,
    });
    expect(result.isRight, isTrue);

    final m1 = await firestore
        .collection('users')
        .doc(userId)
        .collection('followed_merchants')
        .doc('m1')
        .get();
    expect(m1.data()?['sort_index'], 0);
    expect(m1.data()?['heart_level'], 1);
  });
}
