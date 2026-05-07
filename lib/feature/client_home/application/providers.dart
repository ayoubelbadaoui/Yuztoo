import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/core/application/providers.dart' as auth_providers;
import '../../followed_merchants/infrastructure/followed_merchants_repository_provider.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../../merchant/infrastructure/merchant_repository_provider.dart';
import '../../profile/application/user_safety_providers.dart'
    show blockedMerchantIdsProvider;
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
});

final clientHomeFeedProvider = FutureProvider<ClientHomeFeed>((ref) async {
  // Reactive dependencies: rebuilds when auth state OR the blocklist
  // changes. Watching `blockedMerchantIdsProvider` here ensures that
  // blocking a merchant from the storefront propagates instantly to the
  // carnet without needing a manual refresh.
  final userId = ref.watch(auth_providers.currentUserIdProvider);
  final blockedIds =
      ref.watch(blockedMerchantIdsProvider).valueOrNull ?? const <String>{};
  final merchantRepo = ref.read(merchantRepositoryProvider);
  final followedRepo = ref.read(followedMerchantsRepositoryProvider);
  final promoRepo = ref.read(promotionRepositoryProvider);

  // Only followed merchants after sign-in — no guest preview list.
  if (userId == null) {
    return (merchants: <Merchant>[], followedIds: <String>[], promotions: <Promotion>[], ownMerchantId: null);
  }

  // Kick off all three reads in parallel — no ref.watch after await.
  final ownFuture = merchantRepo.getMerchantById(userId);
  final idsFuture = followedRepo.getFollowedIds(userId);
  final heartLevelsFuture = followedRepo.getFollowedHeartLevels(userId);

  final ownResult = await ownFuture;
  final idsResult = await idsFuture;
  final heartLevelsResult = await heartLevelsFuture;

  final Merchant? ownMerchant = ownResult.fold((_) => null, (m) => m);
  // followedIds excludes own merchant AND any merchant the user blocked
  // (the blocklist hides them from the carnet, recommendations, and the
  // notification fan-out — see functions/src/index.ts:isMerchantBlocked).
  final followedIds = idsResult
      .fold((_) => <String>[], (v) => v)
      .where((id) => id != userId && !blockedIds.contains(id))
      .toList();
  final heartLevels = heartLevelsResult.fold((_) => <String, int>{}, (v) => v);

  if (followedIds.isEmpty && ownMerchant == null) {
    return (merchants: <Merchant>[], followedIds: <String>[], promotions: <Promotion>[], ownMerchantId: null);
  }

  final merchantsResult = await merchantRepo.getMerchantsByIds(followedIds);
  final merchants = merchantsResult.fold((_) => <Merchant>[], (list) => list);
  // Sort followed merchants by heart level descending.
  merchants.sort((a, b) {
    final ah = heartLevels[a.id] ?? 1;
    final bh = heartLevels[b.id] ?? 1;
    return bh.compareTo(ah);
  });

  // Prepend own merchant at the top.
  if (ownMerchant != null) {
    merchants.insert(0, ownMerchant);
  }

  if (merchants.isEmpty) {
    return (merchants: <Merchant>[], followedIds: followedIds, promotions: <Promotion>[], ownMerchantId: null);
  }

  final merchantIds = merchants.map((m) => m.id).toList();
  final promoResults = await Future.wait(
    merchantIds.map((mid) => promoRepo.listByMerchantId(mid)),
  );
  final allPromos = <Promotion>[];
  for (final result in promoResults) {
    result.fold((_) => null, (list) => allPromos.addAll(list));
  }
  // Only show promos that are live and not expired.
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
  );
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
