import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/infrastructure/firebase_providers.dart';
import '../../auth/core/application/providers.dart' as auth_providers;
import '../../auth/core/application/state/auth_state.dart';
import '../../merchant/application/providers.dart' as merchant_providers;
import '../domain/entities/promotion.dart';
import '../domain/entities/promotion_engagement.dart';
import '../domain/repositories/promotion_engagement_repository.dart';
import '../infrastructure/firestore_promotion_engagement_repository.dart';
import '../infrastructure/promotion_repository_provider.dart';
import 'use_cases/create_promotion.dart';
import 'use_cases/delete_promotion.dart';
import 'use_cases/list_promotions_by_merchant.dart';
import 'use_cases/record_promo_views.dart';
import 'use_cases/update_promotion.dart';

export '../../auth/core/application/providers.dart' show authStateProvider;
export '../../auth/core/application/state/auth_state.dart'
    show Authenticated, AuthState;

final createPromotionProvider = Provider<CreatePromotion>((ref) {
  final repo = ref.watch(promotionRepositoryProvider);
  return CreatePromotion(repo);
});

final listPromotionsByMerchantProvider =
    Provider<ListPromotionsByMerchant>((ref) {
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

final recordPromoViewsProvider = Provider<RecordPromoViews>((ref) {
  return RecordPromoViews(ref.watch(promotionRepositoryProvider));
});

/// List of promotions for the current merchant (from auth).
/// Throws on failure so the UI can show the error state (not a silent empty list).
final merchantPromotionsProvider = FutureProvider<List<Promotion>>((ref) async {
  final merchantId =
      await ref.watch(merchant_providers.activeMerchantIdProvider.future);
  if (merchantId == null || merchantId.isEmpty) return [];
  final useCase = ref.read(listPromotionsByMerchantProvider);
  final result = await useCase.call(merchantId);
  return result.fold(
    (failure) => throw failure,
    (list) => list,
  );
});

/// Sum of view_count across all active promotions for the current merchant.
/// Used in the CRM stats panel.
final merchantTotalPromoViewsProvider =
    FutureProvider.autoDispose.family<int, String>(
  (ref, merchantId) async {
    if (merchantId.isEmpty) return 0;
    final useCase = ref.read(listPromotionsByMerchantProvider);
    final result = await useCase.call(merchantId);
    return result.fold(
      (_) => 0,
      (list) => list.fold<int>(0, (sum, p) => sum + p.viewCount),
    );
  },
);

final promotionEngagementRepositoryProvider =
    Provider<PromotionEngagementRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirestorePromotionEngagementRepository(firestore: firestore);
});

/// `"merchantId|viewerId|id1,id2,…"` → engagement map keyed by promotion id.
final promotionEngagementMapProvider = FutureProvider.autoDispose
    .family<Map<String, PromotionEngagement>, String>((ref, key) async {
  final firstSep = key.indexOf('|');
  final secondSep = firstSep < 0 ? -1 : key.indexOf('|', firstSep + 1);
  if (secondSep < 0) return const {};
  final merchantId = key.substring(0, firstSep);
  final rawViewer = key.substring(firstSep + 1, secondSep);
  final viewerId = rawViewer.isEmpty ? null : rawViewer;
  final ids = key
      .substring(secondSep + 1)
      .split(',')
      .where((id) => id.isNotEmpty)
      .toList();
  if (merchantId.isEmpty || ids.isEmpty) return const {};
  final repo = ref.watch(promotionEngagementRepositoryProvider);
  return repo.getEngagementForPromotions(
    merchantId: merchantId,
    promotionIds: ids,
    viewerId: viewerId,
  );
});

String promotionEngagementKey({
  required String merchantId,
  required List<String> promotionIds,
  String? viewerId,
}) =>
    '$merchantId|${viewerId ?? ''}|${promotionIds.join(',')}';

final togglePromotionLikeProvider = Provider<
    Future<bool?> Function({
      required String merchantId,
      required String viewerId,
      required String promotionId,
    })>((ref) {
  final repo = ref.watch(promotionEngagementRepositoryProvider);
  return ({
    required String merchantId,
    required String viewerId,
    required String promotionId,
  }) =>
      repo.toggleLike(
        merchantId: merchantId,
        viewerId: viewerId,
        promotionId: promotionId,
      );
});

/// Current signed-in uid (null when guest) for engagement keys.
String? promotionViewerIdFromAuth(AuthState auth) {
  if (auth is! Authenticated) return null;
  return auth.user.id;
}
