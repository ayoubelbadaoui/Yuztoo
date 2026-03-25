import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../merchant/domain/entities/merchant.dart';
import '../../merchant/infrastructure/merchant_repository_provider.dart';
import '../../promotions/domain/entities/promotion.dart';
import '../../promotions/infrastructure/promotion_repository_provider.dart';

/// When the user taps a business (Accueil or Découvrir), set this to the merchant id
/// before navigating to store profile. StoreProfileScreen reads it and loads that merchant.
final selectedStoreMerchantIdProvider = StateProvider<String?>((ref) => null);

/// Merchant data for the store profile screen. Loads from Firestore by [selectedStoreMerchantIdProvider].
final storeProfileMerchantProvider = FutureProvider<Merchant?>((ref) async {
  final merchantId = ref.watch(selectedStoreMerchantIdProvider);
  if (merchantId == null || merchantId.isEmpty) return null;
  final repo = ref.watch(merchantRepositoryProvider);
  final result = await repo.getMerchantById(merchantId);
  return result.fold((_) => null, (m) => m);
});

/// Promotions for the store profile screen (current selected merchant).
final storeProfilePromotionsProvider = FutureProvider<List<Promotion>>((ref) async {
  final merchantAsync = ref.watch(storeProfileMerchantProvider);
  final merchant = merchantAsync.valueOrNull;
  if (merchant == null) return [];
  final repo = ref.watch(promotionRepositoryProvider);
  final result = await repo.listByMerchantId(merchant.id);
  return result.fold((_) => [], (list) => list);
});
