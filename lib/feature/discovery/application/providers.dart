import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/core/application/providers.dart' as auth_providers;
import '../../merchant/domain/entities/merchant.dart';
import '../../merchant/infrastructure/merchant_repository_provider.dart';

/// Merchants list for Découvrir (Recommandations). Loads real data from Firestore.
final discoveryMerchantsProvider = FutureProvider<List<Merchant>>((ref) async {
  final userId = ref.watch(auth_providers.currentUserIdProvider);
  final repo = ref.watch(merchantRepositoryProvider);
  final result = await repo.listMerchants(limit: 50);
  final merchants = result.fold(
    (failure) => <Merchant>[],
    (list) => list,
  );

  // Show businesses from the same city as the connected user.
  if (userId == null) return merchants;
  final cityResult = await ref.read(auth_providers.getUserCityProvider).call(userId);
  final userCity = cityResult.fold((_) => null, (c) => c?.trim());
  if (userCity == null || userCity.isEmpty) return merchants;
  final normalized = userCity.toLowerCase();
  return merchants
      .where((m) => m.city.trim().toLowerCase() == normalized)
      .toList();
});
