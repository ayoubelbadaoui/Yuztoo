import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/followed_merchants/infrastructure/firestore_followed_merchants_repository.dart';
import 'package:flutter_yuztoo/feature/rappels/infrastructure/firestore_rappels_pending_client_repository.dart';

/// Carnet reorder persistence (sort_index) — mal corrigé S3 infrastructure layer.
void main() {
  const userId = 'user_carnet';
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

  Future<void> seedFollowed(String merchantId, {int? sortIndex}) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('followed_merchants')
        .doc(merchantId)
        .set({
      'merchant_id': merchantId,
      'heart_level': 1,
      if (sortIndex != null) 'sort_index': sortIndex,
    });
  }

  group('getFollowedSortIndexes', () {
    test('returns only int sort_index fields', () async {
      await seedFollowed('m_a', sortIndex: 0);
      await seedFollowed('m_b', sortIndex: 1);
      await firestore
          .collection('users')
          .doc(userId)
          .collection('followed_merchants')
          .doc('m_bad')
          .set({'sort_index': 'not-int', 'merchant_id': 'm_bad'});

      final result = await repo.getFollowedSortIndexes(userId);
      expect(result.isRight, isTrue);
      final map = result.fold((_) => <String, int>{}, (m) => m);
      expect(map, {'m_a': 0, 'm_b': 1});
      expect(map.containsKey('m_bad'), isFalse);
    });

    test('empty userId → empty map', () async {
      final result = await repo.getFollowedSortIndexes('');
      expect(result.fold((_) => null, (m) => m), isEmpty);
    });
  });

  group('updateSortOrder', () {
    test('writes sort_index on each followed merchant doc', () async {
      await seedFollowed('m_first');
      await seedFollowed('m_second');

      final result = await repo.updateSortOrder(userId, {
        'm_first': 1,
        'm_second': 0,
      });
      expect(result.isRight, isTrue);

      final first = await firestore
          .collection('users')
          .doc(userId)
          .collection('followed_merchants')
          .doc('m_first')
          .get();
      final second = await firestore
          .collection('users')
          .doc(userId)
          .collection('followed_merchants')
          .doc('m_second')
          .get();

      expect(first.data()?['sort_index'], 1);
      expect(second.data()?['sort_index'], 0);
    });

    test('empty sortIndexes is no-op success', () async {
      final result = await repo.updateSortOrder(userId, {});
      expect(result.isRight, isTrue);
    });

    test('merge-set creates sort_index when followed doc was missing', () async {
      final result = await repo.updateSortOrder(userId, {'m_new': 0});
      expect(result.isRight, isTrue);

      final doc = await firestore
          .collection('users')
          .doc(userId)
          .collection('followed_merchants')
          .doc('m_new')
          .get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['sort_index'], 0);
      expect(doc.data()?['merchant_id'], 'm_new');
    });

    test('merge-set preserves existing heart_level on doc', () async {
      await seedFollowed('m_keep', sortIndex: 2);
      await firestore
          .collection('users')
          .doc(userId)
          .collection('followed_merchants')
          .doc('m_keep')
          .update({'heart_level': 2});

      final result = await repo.updateSortOrder(userId, {'m_keep': 0});
      expect(result.isRight, isTrue);

      final doc = await firestore
          .collection('users')
          .doc(userId)
          .collection('followed_merchants')
          .doc('m_keep')
          .get();
      expect(doc.data()?['sort_index'], 0);
      expect(doc.data()?['heart_level'], 2);
    });
  });
}
