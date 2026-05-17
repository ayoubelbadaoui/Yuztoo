import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/city_input.dart';
import '../../auth/core/application/providers.dart' as auth_providers;
import '../../client_home/application/providers.dart'
    show followedMerchantIdsForCurrentUserProvider;
import '../../merchant/domain/entities/merchant.dart';
import '../../merchant/infrastructure/merchant_repository_provider.dart';
import '../../profile/application/user_safety_providers.dart'
    show blockedMerchantIdsProvider;
import '../domain/discovery_recommended_partners.dart';

/// 'proche' = same-city merchants (default), 'recommandes' = partner businesses
/// of merchants the client follows.
final discoveryMerchantTypeFilterProvider =
    StateProvider<String>((ref) => 'proche');

List<Merchant> _activeOnly(List<Merchant> merchants) =>
    merchants.where((m) => m.status == 'active').toList();

/// City / global catalogue slice for Découvrir — expensive Firestore scan.
/// Cached separately so follow/unfollow only refreshes [discoveryMerchantsProvider].
final discoveryCityMerchantsProvider =
    FutureProvider<List<Merchant>>((ref) async {
  final userId = ref.watch(auth_providers.currentUserIdProvider);
  final repo = ref.watch(merchantRepositoryProvider);

  List<Merchant> merchants;

  if (userId == null) {
    final result = await repo.listMerchants(limit: 50);
    merchants = result.fold((failure) => <Merchant>[], (list) => list);
  } else {
    final connectedCities = await ref.watch(
      auth_providers.connectedCitiesProvider(userId).future,
    );
    final cities = <String>{
      ...connectedCities
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty && !CityInput.isPlaceholder(c)),
    };

    if (cities.isEmpty) {
      final merchantResult = await repo.getMerchantById(userId);
      final merchantCity =
          merchantResult.fold((_) => null, (m) => m?.city.trim());
      if (merchantCity != null &&
          merchantCity.isNotEmpty &&
          !CityInput.isPlaceholder(merchantCity)) {
        cities.add(merchantCity);
      }
    }

    if (cities.isEmpty) {
      final result = await repo.listMerchants(limit: 50);
      merchants = result.fold((failure) => <Merchant>[], (list) => list);
    } else {
      final result = await repo.listMerchants(
        limit: 50,
        cityFilters: cities.toList(),
        cityFetchCap: 200,
      );
      merchants = result.fold((failure) => <Merchant>[], (list) => list);
    }
  }

  return _activeOnly(merchants);
});

/// Merchants the current user follows (for Découvrir empty states / previews).
/// Includes inactive merchants so a followed vitrine still appears after follow.
final discoveryFollowedMerchantsProvider =
    FutureProvider<List<Merchant>>((ref) async {
  final userId = ref.watch(auth_providers.currentUserIdProvider);
  if (userId == null) return [];

  final followedIds =
      await ref.watch(followedMerchantIdsForCurrentUserProvider.future);
  final ids = followedIds.where((id) => id != userId).toList();
  if (ids.isEmpty) return [];

  final repo = ref.watch(merchantRepositoryProvider);
  final result = await repo.getMerchantsByIds(ids);
  return result.fold((_) => <Merchant>[], (list) => list);
});

/// Partner-based recommendations: merchants listed as accepted partners by
/// businesses the client follows (`merchants/{id}/partners`).
///
/// Shows the **recommended** business (e.g. Imigo), never merchants the client
/// already follows (e.g. Lkhobz). No city filter — partners may be in any city.
final discoveryRecommendedMerchantsProvider =
    FutureProvider<List<Merchant>>((ref) async {
  final userId = ref.watch(auth_providers.currentUserIdProvider);
  if (userId == null) return [];

  final followedIds =
      await ref.watch(followedMerchantIdsForCurrentUserProvider.future);
  if (followedIds.isEmpty) return [];

  final followedSet = followedIds.toSet();
  final blockedIds =
      ref.watch(blockedMerchantIdsProvider).valueOrNull ?? const <String>{};

  final repo = ref.watch(merchantRepositoryProvider);
  final firestore = FirebaseFirestore.instance;
  final partnerSnapshots = <String, DiscoveryPartnerSnapshot>{};

  await Future.wait(followedIds.map((merchantId) async {
    final snap = await firestore
        .collection('merchants')
        .doc(merchantId)
        .collection('partners')
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['is_pending'] == true) continue;
      final pid = partnerMerchantIdFromFirestore(data);
      if (pid == null) continue;
      if (!shouldIncludeInDiscoveryRecommendations(
        partnerMerchantId: pid,
        currentUserId: userId,
        followedMerchantIds: followedSet,
        blockedMerchantIds: blockedIds,
      )) {
        continue;
      }
      partnerSnapshots.putIfAbsent(
        pid,
        () => DiscoveryPartnerSnapshot(
          partnerMerchantId: pid,
          partnerName: (data['partner_name'] as String?)?.trim() ?? '',
          partnerLogoUrl: data['partner_logo_url'] as String?,
          partnerCity: data['partner_city'] as String?,
        ),
      );
    }
  }));

  if (partnerSnapshots.isEmpty) return [];

  final orderedIds = partnerSnapshots.keys.toList();
  final result = await repo.getMerchantsByIds(orderedIds);
  final loaded = result.fold((_) => <Merchant>[], (list) => list);
  final byId = {for (final m in loaded) m.id: m};

  final merchants = <Merchant>[];
  for (final id in orderedIds) {
    final full = byId[id];
    if (full != null) {
      merchants.add(full);
    } else {
      final snap = partnerSnapshots[id]!;
      if (snap.partnerName.isNotEmpty) {
        merchants.add(merchantFromPartnerSnapshot(snap));
      }
    }
  }
  return merchants;
});

/// Merchants list for Découvrir.
/// 'proche' tab → city merchants (with followed + own store injected).
/// 'recommandes' tab → partner businesses of followed merchants.
final discoveryMerchantsProvider = FutureProvider<List<Merchant>>((ref) async {
  final userId = ref.watch(auth_providers.currentUserIdProvider);
  final repo = ref.watch(merchantRepositoryProvider);
  final typeFilter = ref.watch(discoveryMerchantTypeFilterProvider);

  if (typeFilter == 'recommandes') {
    return ref.watch(discoveryRecommendedMerchantsProvider.future);
  }

  // 'proche' — city merchants + followed + own store
  var merchants = await ref.watch(discoveryCityMerchantsProvider.future);

  if (userId != null) {
    final followedIds =
        await ref.watch(followedMerchantIdsForCurrentUserProvider.future);

    final existingIds = merchants.map((m) => m.id).toSet();
    final missingFollowed = followedIds
        .where((id) => id != userId && !existingIds.contains(id))
        .toList();

    if (missingFollowed.isNotEmpty) {
      final extra = await repo.getMerchantsByIds(missingFollowed);
      // Keep followed vitrines visible even when status is not yet 'active'.
      final injected = extra.fold((_) => <Merchant>[], (list) => list);
      if (injected.isNotEmpty) {
        merchants = [...injected, ...merchants];
      }
    }

    if (followedIds.isNotEmpty) {
      final followedSet = followedIds.toSet();
      final followed =
          merchants.where((m) => followedSet.contains(m.id)).toList();
      final rest =
          merchants.where((m) => !followedSet.contains(m.id)).toList();
      merchants = [...followed, ...rest];
    }

    if (!merchants.any((m) => m.id == userId)) {
      final ownResult = await repo.getMerchantById(userId);
      final own = ownResult.fold((_) => null, (m) => m);
      if (own != null) {
        merchants = <Merchant>[own, ...merchants];
      }
    }
  }

  final seen = <String>{};
  return merchants.where((m) => seen.add(m.id)).toList();
});

void _invalidateDiscoveryCatalog(
  void Function(ProviderOrFamily provider) invalidate,
) {
  invalidate(discoveryCityMerchantsProvider);
  invalidate(discoveryRecommendedMerchantsProvider);
  invalidate(discoveryFollowedMerchantsProvider);
  invalidate(discoveryMerchantsProvider);
}

/// Refreshes Découvrir catalog providers (call after merchant city / vitrine save).
void invalidateDiscoveryCatalog(Ref ref) => _invalidateDiscoveryCatalog(ref.invalidate);

/// Same as [invalidateDiscoveryCatalog] for [WidgetRef] (Consumer widgets).
void invalidateDiscoveryCatalogWidget(WidgetRef ref) =>
    _invalidateDiscoveryCatalog(ref.invalidate);
