import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../discovery/application/providers.dart'
    show discoveryCityMerchantsProvider;
import '../../profile/application/user_safety_providers.dart'
    show blockedMerchantIdsProvider;
import '../../promotions/domain/entities/promotion.dart';
import '../../promotions/infrastructure/promotion_repository_provider.dart';

/// Active online promotions from merchants in the client's city/ies
/// (Découvrir catalogue), not limited to followed shops.
final clientCityPromotionsProvider =
    FutureProvider<List<Promotion>>((ref) async {
  final blockedIds =
      ref.watch(blockedMerchantIdsProvider).valueOrNull ?? const <String>{};
  final merchants = await ref.watch(discoveryCityMerchantsProvider.future);
  final merchantIds = merchants
      .where((m) => !blockedIds.contains(m.id))
      .map((m) => m.id)
      .where((id) => id.isNotEmpty)
      .toList();
  if (merchantIds.isEmpty) return const <Promotion>[];

  final promoRepo = ref.read(promotionRepositoryProvider);
  final results = await Future.wait(
    merchantIds.map(promoRepo.listByMerchantId),
  );

  final allPromos = <Promotion>[];
  for (final result in results) {
    result.fold((_) => null, allPromos.addAll);
  }

  final now = DateTime.now();
  final active = allPromos
      .where((p) => p.isOnline && p.dateTo.isAfter(now))
      .toList()
    ..sort((a, b) => b.dateTo.compareTo(a.dateTo));

  return active;
});
