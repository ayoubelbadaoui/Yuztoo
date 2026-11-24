import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/merchant/infrastructure/firestore_merchant_repository.dart';

Map<String, dynamic> _store(String owner, String name, DateTime createdAt) => {
      'owner_uid': owner,
      'name': name,
      'email': 'a@b.fr',
      'phone': '',
      'city': 'Belfort',
      'status': 'active',
      'created_at': Timestamp.fromDate(createdAt),
    };

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreMerchantRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreMerchantRepository(firestore: db);
  });

  test('returns every store of the owner, oldest first, by owner_uid',
      () async {
    await db
        .collection('merchants')
        .doc('store-b')
        .set(_store('u1', 'B', DateTime(2026, 3)));
    await db
        .collection('merchants')
        .doc('store-a')
        .set(_store('u1', 'A', DateTime(2026, 1)));
    await db
        .collection('merchants')
        .doc('other')
        .set(_store('u2', 'X', DateTime(2026, 2)));

    final result = await repo.getMerchantsByOwnerUid('u1');
    final ids =
        result.fold((_) => <String>[], (l) => [for (final m in l) m.id]);
    expect(ids, ['store-a', 'store-b']);

    final first = await repo.getMerchantByOwnerUid('u1');
    expect(first.fold((_) => null, (m) => m?.id), 'store-a');
  });

  test('store with a random id is found (doc id != uid)', () async {
    await db
        .collection('merchants')
        .doc('uuid-123')
        .set(_store('u1', 'A', DateTime(2026, 1)));
    final first = await repo.getMerchantByOwnerUid('u1');
    expect(first.fold((_) => null, (m) => m?.id), 'uuid-123');
  });

  test('soft-deleted stores are excluded', () async {
    await db.collection('merchants').doc('gone').set({
      ..._store('u1', 'Gone', DateTime(2026, 1)),
      'deleted_at': Timestamp.now(),
    });
    final result = await repo.getMerchantsByOwnerUid('u1');
    expect(result.fold((_) => -1, (l) => l.length), 0);
  });

  test('legacy store keyed by uid without owner_uid still resolves', () async {
    await db.collection('merchants').doc('u9').set({'name': 'Legacy'});
    final result = await repo.getMerchantsByOwnerUid('u9');
    expect(result.fold((_) => <String>[], (l) => [for (final m in l) m.id]),
        ['u9']);
  });
}
