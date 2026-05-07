import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/city_input.dart';
import '../../auth/core/application/providers.dart' as auth_providers;
import '../../merchant/domain/entities/merchant.dart';
import '../../merchant/infrastructure/merchant_repository_provider.dart';

/// B2C/B2B filter toggle for discovery screen.
/// 'b2c' = consumer merchants (default), 'b2b' = service providers.
final discoveryMerchantTypeFilterProvider = StateProvider<String>((ref) => 'b2c');

/// Merchants list for Découvrir (Recommandations). Loads real data from Firestore.
final discoveryMerchantsProvider = FutureProvider<List<Merchant>>((ref) async {
  final userId = ref.watch(auth_providers.currentUserIdProvider);
  final repo = ref.watch(merchantRepositoryProvider);
  final typeFilter = ref.watch(discoveryMerchantTypeFilterProvider);

  List<Merchant> merchants;

  if (userId == null) {
    final result = await repo.listMerchants(limit: 50);
    merchants = result.fold((failure) => <Merchant>[], (list) => list);
  } else {
    final cityResult = await ref.read(auth_providers.getUserCityProvider).call(userId);
    String? userCity = cityResult.fold((_) => null, (c) => c?.trim());

    // Fallback for dual-profile users who registered as a merchant first:
    // their users/{id}.city may be empty while merchants/{id}.city is set.
    // Without this, discovery falls back to a global unfiltered list instead
    // of showing local merchants in the same city as their shop.
    if (userCity == null || userCity.isEmpty) {
      final merchantResult = await repo.getMerchantById(userId);
      final merchantCity = merchantResult
          .fold((_) => null, (m) => m?.city.trim());
      if (merchantCity != null &&
          merchantCity.isNotEmpty &&
          !CityInput.isPlaceholder(merchantCity)) {
        userCity = merchantCity;
      }
    }

    if (userCity == null || userCity.isEmpty) {
      final result = await repo.listMerchants(limit: 50);
      merchants = result.fold((failure) => <Merchant>[], (list) => list);
    } else {
      final result = await repo.listMerchants(
        limit: 50,
        cityFilter: userCity,
        cityFetchCap: 600,
      );
      merchants = result.fold((failure) => <Merchant>[], (list) => list);
    }
  }

  // Final guard: never show inactive merchants in discovery regardless of
  // what the repository returned (e.g. during Firestore index build lag).
  merchants = merchants.where((m) => m.status == 'active').toList();

  // Filter by merchant type (only when filter is not 'all').
  if (typeFilter != 'all') {
    merchants = merchants
        .where((m) => m.merchantType == typeFilter)
        .toList();
  }

  return merchants;
});
