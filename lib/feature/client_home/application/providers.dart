import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/core/application/providers.dart' as auth_providers;
import '../../followed_merchants/infrastructure/followed_merchants_repository_provider.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../../merchant/infrastructure/merchant_repository_provider.dart';
import '../../promotions/domain/entities/promotion.dart';
import '../../promotions/infrastructure/promotion_repository_provider.dart';
import '../infrastructure/viewed_merchants_local_service.dart';

/// Followed merchant IDs for the current user. Invalidated when user follows/unfollows.
final followedMerchantIdsForCurrentUserProvider =
    FutureProvider<List<String>>((ref) async {
  final userId = ref.watch(auth_providers.currentUserIdProvider);
  if (userId == null) return [];
  final repo = ref.watch(followedMerchantsRepositoryProvider);
  final result = await repo.getFollowedIds(userId);
  return result.fold((_) => [], (list) => list);
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
final followersCountByMerchantIdsProvider =
    FutureProvider.family<Map<String, int>, List<String>>((ref, merchantIds) async {
  if (merchantIds.isEmpty) return const <String, int>{};
  final repo = ref.watch(followedMerchantsRepositoryProvider);
  final result = await repo.getFollowersCounts(merchantIds);
  return result.fold((_) => const <String, int>{}, (map) => map);
});

/// Single load for Accueil: **followed merchants only** (carnet) + their promotions.
/// City-based discovery belongs on Découvrir, not Accueil.
/// Avoids duplicate [getFollowedIds] calls and sequential provider chains.
typedef ClientHomeFeed = ({
  List<Merchant> merchants,
  List<Promotion> promotions,
});

final clientHomeFeedProvider = FutureProvider<ClientHomeFeed>((ref) async {
  final userId = ref.watch(auth_providers.currentUserIdProvider);
  final merchantRepo = ref.watch(merchantRepositoryProvider);
  final promoRepo = ref.watch(promotionRepositoryProvider);

  // Only followed merchants after sign-in — no guest preview list (real carnet data only).
  if (userId == null) {
    return (merchants: <Merchant>[], promotions: <Promotion>[]);
  }

  final ids = await ref.watch(followedMerchantIdsForCurrentUserProvider.future);
  if (ids.isEmpty) {
    return (merchants: <Merchant>[], promotions: <Promotion>[]);
  }

  final merchantsResult = await merchantRepo.getMerchantsByIds(ids);
  final merchants = merchantsResult.fold((_) => <Merchant>[], (list) => list);
  final heartLevels = await ref.watch(followedMerchantHeartLevelsForCurrentUserProvider.future);
  merchants.sort((a, b) {
    final ah = heartLevels[a.id] ?? 1;
    final bh = heartLevels[b.id] ?? 1;
    return bh.compareTo(ah);
  });

  if (merchants.isEmpty) {
    return (merchants: <Merchant>[], promotions: <Promotion>[]);
  }

  final merchantIds = merchants.map((m) => m.id).toList();
  final promoResults = await Future.wait(
    merchantIds.map((mid) => promoRepo.listByMerchantId(mid)),
  );
  final allPromos = <Promotion>[];
  for (final result in promoResults) {
    result.fold((_) => null, (list) => allPromos.addAll(list));
  }
  allPromos.sort((a, b) => b.dateTo.compareTo(a.dateTo));
  return (merchants: merchants, promotions: allPromos);
});

/// Derived — resolves from [clientHomeFeedProvider] (same underlying future).
final clientHomeMerchantsProvider = FutureProvider<List<Merchant>>((ref) async {
  final feed = await ref.watch(clientHomeFeedProvider.future);
  return feed.merchants;
});

/// Derived — resolves from [clientHomeFeedProvider] (same underlying future).
final clientHomePromotionsProvider = FutureProvider<List<Promotion>>((ref) async {
  final feed = await ref.watch(clientHomeFeedProvider.future);
  return feed.promotions;
});
