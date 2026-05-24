import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/infrastructure/logger_service.dart';
import '../../auth/core/application/providers.dart' as auth_providers;
import '../../followed_merchants/domain/repositories/followed_merchants_repository.dart';
import '../../followed_merchants/infrastructure/followed_merchants_repository_provider.dart';
import '../../merchant/domain/repositories/merchant_repository.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../../merchant/infrastructure/merchant_repository_provider.dart';
import '../../profile/application/user_safety_providers.dart'
    show blockedMerchantIdsProvider;
import '../../promotions/domain/entities/promotion.dart';
import '../../promotions/domain/repositories/promotion_repository.dart';
import '../../promotions/infrastructure/promotion_repository_provider.dart';
import '../domain/carnet_merchant_order.dart';
import '../infrastructure/viewed_merchants_local_service.dart';

/// Live followed merchant IDs for the current user.
final followedMerchantIdsForCurrentUserProvider =
    StreamProvider<List<String>>((ref) {
  final userId = ref.watch(auth_providers.currentUserIdProvider);
  if (userId == null) {
    return Stream<List<String>>.value(const <String>[]);
  }
  return ref.watch(followedMerchantsRepositoryProvider).watchFollowedIds(userId);
});

/// Followed merchants with heart level (1 or 2), persisted in Firestore.
final followedMerchantHeartLevelsForCurrentUserProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final userId = ref.watch(auth_providers.currentUserIdProvider);
  if (userId == null) return const <String, int>{};
  final repo = ref.watch(followedMerchantsRepositoryProvider);
  final result = await repo.getFollowedHeartLevels(userId);
  return result.fold((_) => const <String, int>{}, (map) => map);
});

/// Merchants already opened/viewed by the current user (local persistence).
final viewedMerchantsLocalServiceProvider = Provider<ViewedMerchantsLocalService>((ref) {
  return ViewedMerchantsLocalService();
});

final viewedMerchantIdsForCurrentUserProvider = FutureProvider<Set<String>>((ref) async {
  final userId = ref.watch(auth_providers.currentUserIdProvider);
  if (userId == null || userId.isEmpty) return <String>{};
  final service = ref.watch(viewedMerchantsLocalServiceProvider);
  return service.readViewedIds(userId);
});

/// Followers count per merchant id (all users), used for "Suivi par X personnes".
///
/// Reads [Merchant.publicFollowersCount] from each `merchants/{id}` document
/// (field `public_followers_count`), maintained by Cloud Functions on follow
/// create/delete. Avoids client-side collection-group aggregate queries that
/// security rules deny for non-owners.
final followersCountByMerchantIdsProvider =
    FutureProvider.family<Map<String, int>, List<String>>((ref, merchantIds) async {
  if (merchantIds.isEmpty) return const <String, int>{};
  final distinct = merchantIds.toSet().toList();
  final merchantRepo = ref.watch(merchantRepositoryProvider);
  final result = await merchantRepo.getMerchantsByIds(distinct);
  return result.fold(
    (_) => {for (final id in distinct) id: 0},
    (merchants) {
      final byId = {for (final m in merchants) m.id: m.publicFollowersCount};
      return {for (final id in distinct) id: byId[id] ?? 0};
    },
  );
});

/// Single load for Accueil: **followed merchants only** (carnet) + their promotions.
/// City-based discovery belongs on Découvrir, not Accueil.
///
/// IMPORTANT: all async dependencies use [ref.read] (not [ref.watch]) after the
/// first `await` to avoid an infinite-rebuild loop: if we watched the inner
/// provider AND awaited its future, the outer provider would restart every time
/// the inner one settled — causing perpetual loading.
typedef ClientHomeFeed = ({
  List<Merchant> merchants,
  /// IDs of merchants the user is actively following (excludes own merchant).
  List<String> followedIds,
  List<Promotion> promotions,
  /// Merchant ID owned by the current user (shown as "Mon commerce"), or null.
  String? ownMerchantId,
  /// Saved carnet sort indexes (merchantId → position). Empty = not yet reordered.
  Map<String, int> sortIndexes,
});

const _kEmptyClientHomeFeed = (
  merchants: <Merchant>[],
  followedIds: <String>[],
  promotions: <Promotion>[],
  ownMerchantId: null,
  sortIndexes: <String, int>{},
);

/// Builds carnet feed snapshot for a followed-id list (used by stream provider).
Future<ClientHomeFeed> _buildClientHomeFeed({
  required String userId,
  required Set<String> blockedIds,
  required List<String> rawFollowedIds,
  required MerchantRepository merchantRepo,
  required FollowedMerchantsRepository followedRepo,
  required PromotionRepository promoRepo,
}) async {
  final ownFuture = merchantRepo.getMerchantById(userId);
  final heartLevelsFuture = followedRepo.getFollowedHeartLevels(userId);
  final sortIndexesFuture = followedRepo.getFollowedSortIndexes(userId);

  final ownResult = await ownFuture;
  final heartLevelsResult = await heartLevelsFuture;
  final sortIndexesResult = await sortIndexesFuture;

  final Merchant? ownMerchant = ownResult.fold((_) => null, (m) => m);
  final followedIds = rawFollowedIds
      .where((id) => id != userId && !blockedIds.contains(id))
      .toList();
  final heartLevels = heartLevelsResult.fold((_) => <String, int>{}, (v) => v);
  final sortIndexes = sortIndexesResult.fold((_) => <String, int>{}, (v) => v);

  if (followedIds.isEmpty && ownMerchant == null) {
    return (
      merchants: <Merchant>[],
      followedIds: <String>[],
      promotions: <Promotion>[],
      ownMerchantId: null,
      sortIndexes: sortIndexes,
    );
  }

  final merchantsResult = await merchantRepo.getMerchantsByIds(followedIds);
  final merchants = merchantsResult.fold((failure) {
    LoggerService.logError(
      'Client home feed: getMerchantsByIds failed',
      context: {'failure': failure.toString(), 'requested': followedIds.length},
    );
    return <Merchant>[];
  }, (list) => list);

  if (followedIds.isNotEmpty && merchants.isEmpty) {
    LoggerService.logError(
      'Client home feed: followed IDs returned zero merchant docs',
      context: {'followedIds': followedIds},
    );
  }
  merchants.sort(
    (a, b) => compareCarnetMerchants(
      a,
      b,
      sortIndexes: sortIndexes,
      heartLevels: heartLevels,
    ),
  );

  if (ownMerchant != null) {
    merchants.insert(0, ownMerchant);
  }

  if (merchants.isEmpty) {
    return (
      merchants: <Merchant>[],
      followedIds: followedIds,
      promotions: <Promotion>[],
      ownMerchantId: null,
      sortIndexes: sortIndexes,
    );
  }

  final merchantIds = merchants.map((m) => m.id).toList();
  final promoResults = await Future.wait(
    merchantIds.map((mid) => promoRepo.listByMerchantId(mid)),
  );
  final allPromos = <Promotion>[];
  for (final result in promoResults) {
    result.fold((_) => null, (list) => allPromos.addAll(list));
  }
  final now = DateTime.now();
  final filteredPromos = allPromos
      .where((p) => p.isOnline && p.dateTo.isAfter(now))
      .toList();
  filteredPromos.sort((a, b) => b.dateTo.compareTo(a.dateTo));

  return (
    merchants: merchants,
    followedIds: followedIds,
    promotions: filteredPromos,
    ownMerchantId: ownMerchant?.id,
    sortIndexes: sortIndexes,
  );
}

/// Live carnet + promotions for Accueil (followed ids stream + merchant refresh).
final clientHomeFeedProvider = StreamProvider<ClientHomeFeed>((ref) {
  final userId = ref.watch(auth_providers.currentUserIdProvider);
  final blockedIds =
      ref.watch(blockedMerchantIdsProvider).valueOrNull ?? const <String>{};

  if (userId == null) {
    return Stream<ClientHomeFeed>.value(_kEmptyClientHomeFeed);
  }

  final followedRepo = ref.read(followedMerchantsRepositoryProvider);
  final merchantRepo = ref.read(merchantRepositoryProvider);
  final promoRepo = ref.read(promotionRepositoryProvider);

  return followedRepo.watchFollowedIds(userId).asyncMap((rawIds) async {
    try {
      final feed = await _buildClientHomeFeed(
        userId: userId,
        blockedIds: blockedIds,
        rawFollowedIds: rawIds,
        merchantRepo: merchantRepo,
        followedRepo: followedRepo,
        promoRepo: promoRepo,
      );
      LoggerService.logInfo(
        'Client home feed loaded',
        context: {
          'userId': userId,
          'rawFollowed': rawIds.length,
          'followedAfterFilter': feed.followedIds.length,
          'blocked': blockedIds.length,
          'hasOwnMerchant': feed.ownMerchantId != null,
        },
      );
      return feed;
    } catch (e, st) {
      LoggerService.logError(
        'Client home feed stream error',
        error: e,
        stackTrace: st,
      );
      return _kEmptyClientHomeFeed;
    }
  });
});

/// Derived — resolves from [clientHomeFeedProvider] stream.
final clientHomeMerchantsProvider = Provider<AsyncValue<List<Merchant>>>((ref) {
  return ref.watch(clientHomeFeedProvider).whenData((f) => f.merchants);
});

/// Derived — resolves from [clientHomeFeedProvider] stream.
final clientHomePromotionsProvider = Provider<AsyncValue<List<Promotion>>>((ref) {
  return ref.watch(clientHomeFeedProvider).whenData((f) => f.promotions);
});
