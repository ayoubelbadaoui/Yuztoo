import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/core/application/providers.dart' as auth_providers;
import '../../auth/core/application/state/auth_state.dart';
import '../domain/entities/promotion.dart';
import '../infrastructure/promotion_repository_provider.dart';
import 'use_cases/create_promotion.dart';
import 'use_cases/delete_promotion.dart';
import 'use_cases/list_promotions_by_merchant.dart';
import 'use_cases/update_promotion.dart';

export '../../auth/core/application/providers.dart' show authStateProvider;
export '../../auth/core/application/state/auth_state.dart' show Authenticated;

final createPromotionProvider = Provider<CreatePromotion>((ref) {
  final repo = ref.watch(promotionRepositoryProvider);
  return CreatePromotion(repo);
});

final listPromotionsByMerchantProvider = Provider<ListPromotionsByMerchant>((ref) {
  final repo = ref.watch(promotionRepositoryProvider);
  return ListPromotionsByMerchant(repo);
});

final updatePromotionProvider = Provider<UpdatePromotion>((ref) {
  final repo = ref.watch(promotionRepositoryProvider);
  return UpdatePromotion(repo);
});

final deletePromotionProvider = Provider<DeletePromotion>((ref) {
  final repo = ref.watch(promotionRepositoryProvider);
  return DeletePromotion(repo);
});

/// List of promotions for the current merchant (from auth).
final merchantPromotionsProvider = FutureProvider<List<Promotion>>((ref) async {
  final authState = ref.watch(auth_providers.authStateProvider);
  if (authState is! Authenticated) return [];
  final merchantId = authState.user.id; // MVP: merchantId == userId
  final useCase = ref.read(listPromotionsByMerchantProvider);
  final result = await useCase.call(merchantId);
  return result.fold((_) => [], (list) => list);
});
