import '../entities/promotion_engagement.dart';

/// Client likes on promotions (mirrors news-photo engagement).
abstract class PromotionEngagementRepository {
  Future<Map<String, PromotionEngagement>> getEngagementForPromotions({
    required String merchantId,
    required List<String> promotionIds,
    String? viewerId,
  });

  /// Returns the new `likedByMe` after a successful toggle, or `null` if the
  /// write failed (so UI can distinguish failure from "unliked").
  Future<bool?> toggleLike({
    required String merchantId,
    required String viewerId,
    required String promotionId,
  });
}
