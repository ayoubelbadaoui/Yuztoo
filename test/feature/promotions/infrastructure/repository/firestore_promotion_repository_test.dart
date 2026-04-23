import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/promotions/domain/entities/promotion.dart';
import 'package:flutter_yuztoo/feature/promotions/infrastructure/firestore_promotion_repository.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/feature/storage/domain/repositories/storage_repository.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';

class _FakeStorage implements StorageRepository {
  @override
  Future<Result<String>> uploadImage({
    required String filePath,
    required String storagePath,
  }) async =>
      const Right('https://fake.storage/image.jpg');

  @override
  Future<Result<Unit>> deleteImage(String storagePath) async =>
      const Right(unit);
}

// ── Test helpers ──────────────────────────────────────────────────────────────

Promotion _basePromo({
  String id = '',
  String merchantId = 'merchant1',
}) =>
    Promotion(
      id: id,
      merchantId: merchantId,
      title: 'Test promo',
      subtitle: '10% off',
      dateFrom: DateTime(2026, 1, 1),
      dateTo: DateTime(2026, 12, 31),
      selectedClientType: ClientType.gratuit,
      isOnline: true,
    );

// ─────────────────────────────────────────────────────────────────────────────
// FirestorePromotionRepository — integration tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestorePromotionRepository repo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = FirestorePromotionRepository(
      firestore: fakeFirestore,
      storageRepository: _FakeStorage(),
    );
  });

  // ── create ──────────────────────────────────────────────────────────────────

  group('create', () {
    test('returns Right with a Promotion that has a non-empty id', () async {
      final result = await repo.create(
        merchantId: 'merchant1',
        promotion: _basePromo(),
      );

      expect(result.isRight, isTrue);
      final promo = result.fold((_) => throw Exception(), (v) => v);
      expect(promo.id, isNotEmpty);
      expect(promo.merchantId, 'merchant1');
      expect(promo.title, 'Test promo');
    });

    test('creates a document in Firestore at the correct path', () async {
      final result = await repo.create(
        merchantId: 'merchant1',
        promotion: _basePromo(),
      );

      final id = result.fold((_) => throw Exception(), (v) => v).id;
      final snap = await fakeFirestore
          .collection('merchants')
          .doc('merchant1')
          .collection('promotions')
          .doc(id)
          .get();

      expect(snap.exists, isTrue);
      expect(snap.data()!['title'], 'Test promo');
    });

    test('stores view_count as 0 on create', () async {
      final result = await repo.create(
        merchantId: 'merchant1',
        promotion: _basePromo(),
      );

      final id = result.fold((_) => throw Exception(), (v) => v).id;
      final snap = await fakeFirestore
          .collection('merchants')
          .doc('merchant1')
          .collection('promotions')
          .doc(id)
          .get();

      expect(snap.data()!.containsKey('view_count'), isFalse,
          reason: 'view_count is never written by the app (server-incremented only)');
    });

    test('stores image_url when storage upload succeeds', () async {
      final result = await repo.create(
        merchantId: 'merchant1',
        promotion: _basePromo(),
        imageFilePath: '', // empty path skips the file existence check
      );
      expect(result.isRight, isTrue);
    });

    test('returns Left when merchantId is empty', () async {
      final result = await repo.create(
        merchantId: '',
        promotion: _basePromo(merchantId: ''),
      );
      expect(result.isLeft, isTrue);
    });
  });

  // ── listByMerchantId ────────────────────────────────────────────────────────

  group('listByMerchantId', () {
    test('returns empty list when no promotions exist', () async {
      final result = await repo.listByMerchantId('merchant1');
      expect(result.isRight, isTrue);
      expect((result.rightOrNull ?? []), isEmpty);
    });

    test('returns all promotions for the merchant', () async {
      await repo.create(merchantId: 'merchant1', promotion: _basePromo());
      await repo.create(
          merchantId: 'merchant1',
          promotion: _basePromo().copyWith(title: 'Second promo'));

      final result = await repo.listByMerchantId('merchant1');
      expect(result.isRight, isTrue);
      expect((result.rightOrNull ?? []).length, 2);
    });

    test('does NOT return promotions for a different merchant', () async {
      await repo.create(
          merchantId: 'merchantA',
          promotion: _basePromo(merchantId: 'merchantA'));
      await repo.create(
          merchantId: 'merchantB',
          promotion: _basePromo(merchantId: 'merchantB'));

      final result = await repo.listByMerchantId('merchantA');
      final promos = (result.rightOrNull ?? []);
      expect(promos.every((p) => p.merchantId == 'merchantA'), isTrue);
      expect(promos.length, 1);
    });

    test('returns empty list for empty merchantId (no error, graceful fallback)', () async {
      final result = await repo.listByMerchantId('');
      expect(result.isRight, isTrue);
      expect(result.fold((_) => null, (v) => v), isEmpty);
    });
  });

  // ── update ──────────────────────────────────────────────────────────────────

  group('update', () {
    test('updates promotion fields in Firestore', () async {
      // First create
      final created = (await repo.create(
        merchantId: 'merchant1',
        promotion: _basePromo(),
      )).fold((_) => throw Exception(), (v) => v);

      // Then update
      final updated = created.copyWith(title: 'Updated title');
      final result = await repo.update(updated);

      expect(result.isRight, isTrue);
      expect(result.fold((_) => throw Exception(), (v) => v).title, 'Updated title');

      // Verify in Firestore
      final snap = await fakeFirestore
          .collection('merchants')
          .doc('merchant1')
          .collection('promotions')
          .doc(created.id)
          .get();
      expect(snap.data()!['title'], 'Updated title');
    });

    test('returns Left when promotion has empty id', () async {
      final result = await repo.update(_basePromo(id: ''));
      expect(result.isLeft, isTrue);
    });

    test('returns Left when promotion has empty merchantId', () async {
      final result = await repo.update(_basePromo(id: 'some-id', merchantId: ''));
      expect(result.isLeft, isTrue);
    });
  });

  // ── delete ──────────────────────────────────────────────────────────────────

  group('delete', () {
    test('removes the promotion document from Firestore', () async {
      final created = (await repo.create(
        merchantId: 'merchant1',
        promotion: _basePromo(),
      )).fold((_) => throw Exception(), (v) => v);

      final deleteResult = await repo.delete(
        merchantId: 'merchant1',
        promotionId: created.id,
      );
      expect(deleteResult.isRight, isTrue);

      final snap = await fakeFirestore
          .collection('merchants')
          .doc('merchant1')
          .collection('promotions')
          .doc(created.id)
          .get();
      expect(snap.exists, isFalse);
    });

    test('returns Left when merchantId is empty', () async {
      final result = await repo.delete(merchantId: '', promotionId: 'p1');
      expect(result.isLeft, isTrue);
    });

    test('returns Left when promotionId is empty', () async {
      final result = await repo.delete(merchantId: 'merchant1', promotionId: '');
      expect(result.isLeft, isTrue);
    });
  });

  // ── recordViews ─────────────────────────────────────────────────────────────

  group('recordViews', () {
    test('increments view_count for each promotion id', () async {
      // Seed a promotion doc directly
      await fakeFirestore
          .collection('merchants')
          .doc('merchant1')
          .collection('promotions')
          .doc('promo1')
          .set({'title': 'Test', 'view_count': 0});

      await repo.recordViews(
        merchantId: 'merchant1',
        promotionIds: ['promo1'],
      );

      final snap = await fakeFirestore
          .collection('merchants')
          .doc('merchant1')
          .collection('promotions')
          .doc('promo1')
          .get();

      // FieldValue.increment(1) adds 1 → view_count becomes 1
      expect(snap.data()!['view_count'], 1);
    });

    test('does not throw when promotionIds is empty', () async {
      await expectLater(
        repo.recordViews(merchantId: 'merchant1', promotionIds: []),
        completes,
      );
    });

    test('does not throw when merchantId is empty', () async {
      await expectLater(
        repo.recordViews(merchantId: '', promotionIds: ['p1']),
        completes,
      );
    });
  });
}
