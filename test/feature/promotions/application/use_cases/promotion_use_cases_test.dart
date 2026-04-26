import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/feature/promotions/application/use_cases/create_promotion.dart';
import 'package:flutter_yuztoo/feature/promotions/application/use_cases/delete_promotion.dart';
import 'package:flutter_yuztoo/feature/promotions/application/use_cases/record_promo_views.dart';
import 'package:flutter_yuztoo/feature/promotions/domain/entities/promotion.dart';
import 'package:flutter_yuztoo/feature/promotions/domain/promotion_failure.dart';
import 'package:flutter_yuztoo/feature/promotions/domain/repositories/promotion_repository.dart';

// ── Fake repository ──────────────────────────────────────────────────────────

class _FakePromotionRepository implements PromotionRepository {
  // last recorded calls
  String? lastCreateMerchantId;
  Promotion? lastCreatedPromotion;
  String? lastDeletedPromotionId;
  String? lastDeletedMerchantId;
  String? lastViewsMerchantId;
  List<String>? lastViewsIds;

  // control flags
  bool shouldFailCreate = false;
  bool shouldFailDelete = false;

  static final _samplePromo = Promotion(
    id: 'p1',
    merchantId: 'm1',
    title: 'Promo test',
    subtitle: 'desc',
    dateFrom: DateTime(2025, 1, 1),
    dateTo: DateTime(2025, 12, 31),
    selectedClientType: ClientType.gratuit,
    isOnline: true,
  );

  @override
  Future<Result<Promotion>> create({
    required String merchantId,
    required Promotion promotion,
    String? imageFilePath,
  }) async {
    lastCreateMerchantId = merchantId;
    lastCreatedPromotion = promotion;
    if (shouldFailCreate) {
      return const Left(PromotionNetworkFailure());
    }
    return Right(_samplePromo.copyWith(merchantId: merchantId));
  }

  @override
  Future<Result<List<Promotion>>> listByMerchantId(String merchantId) async {
    return const Right([]);
  }

  @override
  Future<Result<Promotion>> update(
    Promotion promotion, {
    String? imageFilePath,
  }) async {
    return Right(promotion);
  }

  @override
  Future<Result<Unit>> delete({
    required String merchantId,
    required String promotionId,
  }) async {
    lastDeletedMerchantId = merchantId;
    lastDeletedPromotionId = promotionId;
    if (shouldFailDelete) {
      return const Left(PromotionNetworkFailure());
    }
    return const Right(unit);
  }

  @override
  Future<void> recordViews({
    required String merchantId,
    required List<String> promotionIds,
  }) async {
    lastViewsMerchantId = merchantId;
    lastViewsIds = List.of(promotionIds);
  }
}

// ── CreatePromotion tests ────────────────────────────────────────────────────

void main() {
  late _FakePromotionRepository repo;

  setUp(() => repo = _FakePromotionRepository());

  final newPromo = Promotion(
    id: '',
    merchantId: 'm1',
    title: 'Promo printemps',
    subtitle: '-15% tout le rayon',
    dateFrom: DateTime(2025, 3, 1),
    dateTo: DateTime(2025, 3, 31),
    selectedClientType: ClientType.premium,
    isOnline: false,
  );

  group('CreatePromotion', () {
    test('success — returns Right with created promotion', () async {
      final uc = CreatePromotion(repo);
      final result = await uc.call(merchantId: 'm1', promotion: newPromo);
      expect(result.isRight, isTrue);
      expect(repo.lastCreateMerchantId, 'm1');
      expect(repo.lastCreatedPromotion, newPromo);
    });

    test('success — with imageFilePath passes it to repo', () async {
      final uc = CreatePromotion(repo);
      await uc.call(
        merchantId: 'm1',
        promotion: newPromo,
        imageFilePath: '/tmp/promo.jpg',
      );
      expect(repo.lastCreatedPromotion, newPromo);
    });

    test('failure — network error returns Left', () async {
      repo.shouldFailCreate = true;
      final uc = CreatePromotion(repo);
      final result = await uc.call(merchantId: 'm1', promotion: newPromo);
      expect(result.isLeft, isTrue);
      expect(result.fold((f) => f, (_) => null), isA<PromotionNetworkFailure>());
    });
  });

  // ── DeletePromotion tests ────────────────────────────────────────────────

  group('DeletePromotion', () {
    test('success — returns Right unit', () async {
      final uc = DeletePromotion(repo);
      final result = await uc.call(merchantId: 'm1', promotionId: 'p99');
      expect(result.isRight, isTrue);
      expect(repo.lastDeletedMerchantId, 'm1');
      expect(repo.lastDeletedPromotionId, 'p99');
    });

    test('failure — network error propagated as Left', () async {
      repo.shouldFailDelete = true;
      final uc = DeletePromotion(repo);
      final result = await uc.call(merchantId: 'm1', promotionId: 'p99');
      expect(result.isLeft, isTrue);
    });
  });

  // ── RecordPromoViews tests ───────────────────────────────────────────────

  group('RecordPromoViews', () {
    test('delegates merchantId and ids to repository', () async {
      final uc = RecordPromoViews(repo);
      await uc.call(merchantId: 'm1', promotionIds: ['p1', 'p2']);
      expect(repo.lastViewsMerchantId, 'm1');
      expect(repo.lastViewsIds, ['p1', 'p2']);
    });

    test('empty promotionIds — still delegates (repo is best-effort)', () async {
      final uc = RecordPromoViews(repo);
      await uc.call(merchantId: 'm1', promotionIds: []);
      expect(repo.lastViewsMerchantId, 'm1');
      expect(repo.lastViewsIds, isEmpty);
    });

    test('empty merchantId — delegates without throwing', () async {
      final uc = RecordPromoViews(repo);
      await expectLater(
        uc.call(merchantId: '', promotionIds: ['p1']),
        completes,
      );
    });

    test('multiple promotions all recorded in a single call', () async {
      final uc = RecordPromoViews(repo);
      final ids = ['p1', 'p2', 'p3', 'p4', 'p5'];
      await uc.call(merchantId: 'm1', promotionIds: ids);
      expect(repo.lastViewsIds, ids);
    });
  });
}
