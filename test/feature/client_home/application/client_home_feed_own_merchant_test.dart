import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/failure.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/feature/auth/core/application/providers.dart'
    as auth_providers;
import 'package:flutter_yuztoo/feature/client_home/application/providers.dart';
import 'package:flutter_yuztoo/feature/followed_merchants/domain/repositories/followed_merchants_repository.dart';
import 'package:flutter_yuztoo/feature/followed_merchants/infrastructure/followed_merchants_repository_provider.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/client_gratification_config.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/loyalty_program_config.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/merchant_failure.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/repositories/merchant_repository.dart';
import 'package:flutter_yuztoo/feature/merchant/infrastructure/merchant_repository_provider.dart';
import 'package:flutter_yuztoo/feature/promotions/domain/entities/promotion.dart';
import 'package:flutter_yuztoo/feature/promotions/domain/repositories/promotion_repository.dart';
import 'package:flutter_yuztoo/feature/promotions/infrastructure/promotion_repository_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Regression coverage for the merchant→client switch carnet bug.
//
// Symptom (user report): "A la première bascule d'un commerçant en mode
// client - le carnet Yuztoo ne se charge pas tant que le commercant n'est
// pas connecté à un commerce".
//
// Root cause: `_buildClientHomeFeed` resolved the user's own merchant doc
// via `getMerchantById(userId)`, which only matched legacy accounts where
// the doc id literally was the user id. Modern merchants have a UUID
// merchant id with `owner_uid == userId`, so the lookup returned null.
// Combined with an empty `followedIds` (a brand-new client view), the
// provider short-circuited to an empty feed — and the carnet appeared
// "broken" until the user followed at least one shop.
//
// Fix: prefer `getMerchantByOwnerUid(userId)` and fall back to the legacy
// `getMerchantById(userId)` only when the modern lookup yields nothing.
// ─────────────────────────────────────────────────────────────────────────────

class _Fake {
  static Merchant merchant({
    required String id,
    required String ownerUid,
    String name = 'Mon commerce',
  }) =>
      Merchant(
        id: id,
        ownerUid: ownerUid,
        name: name,
        email: 'a@b.c',
        phone: '+33',
        city: 'Paris',
      );
}

class _FakeMerchantRepository implements MerchantRepository {
  _FakeMerchantRepository({this.byOwnerUid, this.byDocId});

  Merchant? byOwnerUid;
  Merchant? byDocId;
  int byOwnerUidCalls = 0;
  int byDocIdCalls = 0;

  @override
  Future<Result<Merchant?>> getMerchantByOwnerUid(String ownerUid) async {
    byOwnerUidCalls++;
    final m = byOwnerUid;
    if (m != null && m.ownerUid == ownerUid) {
      return Right<MerchantFailure, Merchant?>(m);
    }
    return const Right<MerchantFailure, Merchant?>(null);
  }

  @override
  Future<Result<Merchant?>> getMerchantById(String merchantId) async {
    byDocIdCalls++;
    final m = byDocId;
    if (m != null && m.id == merchantId) {
      return Right<MerchantFailure, Merchant?>(m);
    }
    return const Right<MerchantFailure, Merchant?>(null);
  }

  @override
  Future<Result<List<Merchant>>> getMerchantsByIds(List<String> ids) async =>
      Right<MerchantFailure, List<Merchant>>(<Merchant>[]);

  @override
  Future<Result<bool>> merchantExists(String ownerUid) async =>
      const Right<MerchantFailure, bool>(false);

  @override
  Future<Result<Merchant>> createMerchantAndLinkUser({
    required Merchant merchant,
    required String userId,
  }) async =>
      const Left<MerchantFailure, Merchant>(
        MerchantUnexpectedFailure(message: 'unused'),
      );

  @override
  Future<Result<Unit>> linkExistingMerchantToUser({
    required String merchantId,
    required String userId,
  }) async =>
      const Right<MerchantFailure, Unit>(unit);

  @override
  Future<Result<List<Merchant>>> listMerchants({
    int limit = 20,
    String? cityFilter,
    List<String>? cityFilters,
    int cityFetchCap = 500,
  }) async =>
      const Right<MerchantFailure, List<Merchant>>(<Merchant>[]);

  @override
  Future<Result<Merchant>> updateMerchant({
    required String merchantId,
    String? displayName,
    String? description,
    List<String>? categories,
    String? logoUrl,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? websiteUrl,
    String? bannerUrl,
    List<String>? newsImageUrls,
    String? status,
    Map<String, dynamic>? hours,
    String? welcomeGiftDescription,
    bool? rappelsAutoClientValidation,
    bool? rappelsAutoPassageValidation,
    LoyaltyProgramConfig? loyaltyProgram,
    bool? messagingEnabled,
    bool? notificationsAutoEnabled,
    bool? galerieEnabled,
    bool? loyaltyEnabledStandalone,
    String? merchantType,
    bool clearCityField = false,
  }) async =>
      const Left<MerchantFailure, Merchant>(
        MerchantUnexpectedFailure(message: 'unused'),
      );

  @override
  Future<Result<void>> updateGratificationConfig({
    required String merchantId,
    required ClientGratificationConfig config,
  }) async =>
      const Right<MerchantFailure, void>(null);
}

class _FakeFollowedMerchantsRepository implements FollowedMerchantsRepository {
  _FakeFollowedMerchantsRepository({this.followedIds = const []});

  final List<String> followedIds;

  @override
  Stream<List<String>> watchFollowedIds(String userId) =>
      Stream<List<String>>.value(followedIds);

  @override
  Future<Result<List<String>>> getFollowedIds(String userId) async =>
      Right<AppFailure, List<String>>(followedIds);

  @override
  Future<Result<List<String>>> getFollowerIds(String merchantId) async =>
      const Right<AppFailure, List<String>>(<String>[]);

  @override
  Future<Result<Unit>> add(String userId, String merchantId) async =>
      const Right<AppFailure, Unit>(unit);

  @override
  Future<Result<Unit>> remove(String userId, String merchantId) async =>
      const Right<AppFailure, Unit>(unit);

  @override
  Future<Result<bool>> isFollowing(String userId, String merchantId) async =>
      const Right<AppFailure, bool>(false);

  @override
  Future<Result<Map<String, int>>> getFollowedHeartLevels(
          String userId) async =>
      const Right<AppFailure, Map<String, int>>(<String, int>{});

  @override
  Future<Result<Unit>> setHeartLevel(
          String userId, String merchantId, int heartLevel) async =>
      const Right<AppFailure, Unit>(unit);

  @override
  Future<Result<bool>> getMuteState(String userId, String merchantId) async =>
      const Right<AppFailure, bool>(false);

  @override
  Future<Result<Unit>> setMuteState(String userId, String merchantId,
          {required bool muted}) async =>
      const Right<AppFailure, Unit>(unit);

  @override
  Future<Result<Set<String>>> getMutedMerchantIds(String userId) async =>
      const Right<AppFailure, Set<String>>(<String>{});

  @override
  Future<Result<Map<String, int>>> getFollowedSortIndexes(
          String userId) async =>
      const Right<AppFailure, Map<String, int>>(<String, int>{});

  @override
  Future<Result<Unit>> updateSortOrder(
          String userId, Map<String, int> sortIndexes) async =>
      const Right<AppFailure, Unit>(unit);
}

class _FakePromotionRepository implements PromotionRepository {
  @override
  Future<Result<List<Promotion>>> listByMerchantId(String merchantId) async =>
      const Right<AppFailure, List<Promotion>>(<Promotion>[]);

  // ignore: unused_element
  @override
  noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Not used in these tests');
}

ProviderContainer _buildContainer({
  required _FakeMerchantRepository merchantRepo,
  required _FakeFollowedMerchantsRepository followedRepo,
  required String userId,
}) {
  return ProviderContainer(
    overrides: [
      auth_providers.currentUserIdProvider.overrideWith((ref) => userId),
      merchantRepositoryProvider.overrideWithValue(merchantRepo),
      followedMerchantsRepositoryProvider.overrideWithValue(followedRepo),
      promotionRepositoryProvider.overrideWithValue(_FakePromotionRepository()),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('clientHomeFeedProvider — own merchant resolution', () {
    test(
        'modern merchant with UUID doc id resolves via getMerchantByOwnerUid '
        '(no follows yet — the brand-new merchant→client switch case)',
        () async {
      const userId = 'user-1';
      const modernMerchantDocId = 'merchant-uuid-xyz';
      final merchantRepo = _FakeMerchantRepository(
        byOwnerUid: _Fake.merchant(
          id: modernMerchantDocId,
          ownerUid: userId,
        ),
        byDocId: null, // legacy doc-id lookup MUST NOT be the source of truth
      );
      final container = _buildContainer(
        merchantRepo: merchantRepo,
        followedRepo: _FakeFollowedMerchantsRepository(followedIds: const []),
        userId: userId,
      );
      addTearDown(container.dispose);

      final feed = await container.read(clientHomeFeedProvider.future);

      expect(
        feed.ownMerchantId,
        modernMerchantDocId,
        reason:
            'A modern merchant switching to client must see their own commerce '
            'tile immediately — not after they follow a third-party shop.',
      );
      expect(merchantRepo.byOwnerUidCalls, 1,
          reason: 'must consult owner_uid first');
      expect(feed.merchants, hasLength(1),
          reason: 'own merchant should still appear in the carnet '
              'when followedIds is empty');
      expect(feed.followedIds, isEmpty);
    });

    test(
        'legacy merchant where doc id == user id still resolves via the '
        'fallback to getMerchantById (defence-in-depth)',
        () async {
      const userId = 'legacy-user-2';
      final merchantRepo = _FakeMerchantRepository(
        byOwnerUid: null, // legacy doc has no owner_uid index
        byDocId: _Fake.merchant(id: userId, ownerUid: ''),
      );
      final container = _buildContainer(
        merchantRepo: merchantRepo,
        followedRepo: _FakeFollowedMerchantsRepository(followedIds: const []),
        userId: userId,
      );
      addTearDown(container.dispose);

      final feed = await container.read(clientHomeFeedProvider.future);

      expect(feed.ownMerchantId, userId);
      expect(merchantRepo.byOwnerUidCalls, 1);
      expect(merchantRepo.byDocIdCalls, greaterThanOrEqualTo(1),
          reason: 'fallback must be exercised when owner_uid lookup yields '
              'nothing');
    });

    test('pure client (no merchant doc) yields a null ownMerchantId', () async {
      const userId = 'pure-client';
      final merchantRepo = _FakeMerchantRepository();
      final container = _buildContainer(
        merchantRepo: merchantRepo,
        followedRepo: _FakeFollowedMerchantsRepository(followedIds: const []),
        userId: userId,
      );
      addTearDown(container.dispose);

      final feed = await container.read(clientHomeFeedProvider.future);

      expect(feed.ownMerchantId, isNull);
      expect(feed.merchants, isEmpty);
    });
  });
}
