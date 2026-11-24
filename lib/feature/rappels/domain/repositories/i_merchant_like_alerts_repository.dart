import '../../../../core/domain/core/result.dart';
import '../entities/merchant_like_alert.dart';

/// Unseen likes for Vos clients › Aperçu (promo + actualité).
///
/// Firestore:
/// - `merchants/{merchantId}/promotion_likes/*`
/// - `merchants/{merchantId}/news_photo_likes/*`
/// - watermark: `merchants/{merchantId}.likes_alerts_seen_at`
abstract class IMerchantLikeAlertsRepository {
  /// Live list of unseen likes (newest first, capped).
  Stream<List<MerchantLikeAlert>> watchUnseenLikeAlerts(String merchantId);

  /// Advance the watermark so current likes stop appearing as alerts.
  Future<Result<Unit>> markAllSeen(String merchantId);
}
