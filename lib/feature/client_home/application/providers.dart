import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/core/application/providers.dart' as auth_providers;
import '../../followed_merchants/infrastructure/followed_merchants_repository_provider.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../../merchant/infrastructure/merchant_repository_provider.dart';
import '../../promotions/domain/entities/promotion.dart';
import '../../promotions/infrastructure/promotion_repository_provider.dart';

/// Followed merchant IDs for the current user. Invalidated when user follows/unfollows.
final followedMerchantIdsForCurrentUserProvider =
    FutureProvider<List<String>>((ref) async {
  final userId = ref.watch(auth_providers.currentUserIdProvider);
  if (userId == null) return [];
  final repo = ref.watch(followedMerchantsRepositoryProvider);
  final result = await repo.getFollowedIds(userId);
  return result.fold((_) => [], (list) => list);
});

/// List of merchants for client Accueil: followed merchants when logged in,
/// otherwise fallback to listMerchants (discovery-style) for empty state.
final clientHomeMerchantsProvider = FutureProvider<List<Merchant>>((ref) async {
  final userId = ref.watch(auth_providers.currentUserIdProvider);
  final followRepo = ref.watch(followedMerchantsRepositoryProvider);
  final merchantRepo = ref.watch(merchantRepositoryProvider);

  if (userId != null) {
    final idsResult = await followRepo.getFollowedIds(userId);
    final ids = idsResult.fold((_) => <String>[], (list) => list);
    if (ids.isNotEmpty) {
      final result = await merchantRepo.getMerchantsByIds(ids);
      return result.fold((_) => <Merchant>[], (list) => list);
    }
    // Logged in but no followed: return empty so Accueil shows "Suivez des commerces"
    return [];
  }

  // Not logged in: show all merchants (discovery-style)
  final result = await merchantRepo.listMerchants(limit: 20);
  return result.fold((_) => <Merchant>[], (list) => list);
});

/// Promotions from all followed merchants (for Accueil). When no followed, from first of list.
final clientHomePromotionsProvider = FutureProvider<List<Promotion>>((ref) async {
  final merchantsAsync = ref.watch(clientHomeMerchantsProvider);
  final merchants = merchantsAsync.valueOrNull ?? [];
  final promoRepo = ref.watch(promotionRepositoryProvider);

  if (merchants.isEmpty) return <Promotion>[];

  final userId = ref.watch(auth_providers.currentUserIdProvider);
  final followRepo = ref.watch(followedMerchantsRepositoryProvider);

  List<String> merchantIds;
  if (userId != null) {
    final idsResult = await followRepo.getFollowedIds(userId);
    merchantIds = idsResult.fold((_) => <String>[], (list) => list);
    if (merchantIds.isEmpty) merchantIds = merchants.map((m) => m.id).toList();
  } else {
    merchantIds = merchants.map((m) => m.id).toList();
  }

  final allPromos = <Promotion>[];
  for (final mid in merchantIds) {
    final result = await promoRepo.listByMerchantId(mid);
    result.fold((_) => null, (list) => allPromos.addAll(list));
  }
  // Sort by dateTo descending (newest first)
  allPromos.sort((a, b) => b.dateTo.compareTo(a.dateTo));
  return allPromos;
});
