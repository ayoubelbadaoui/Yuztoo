import '../entities/news_photo_engagement.dart';

/// Per-photo likes / views for merchant Actualité images.
///
/// Writes are best-effort and must not throw into the UI. Views are
/// idempotent per (viewer, photo). Likes toggle per (viewer, photo).
abstract class NewsPhotoEngagementRepository {
  /// Stable short id derived from [imageUrl] (shared by client + rules).
  String photoIdForUrl(String imageUrl);

  /// Load engagement for [imageUrls]. Missing photos return zero counts.
  Future<Map<String, NewsPhotoEngagement>> getEngagementForUrls({
    required String merchantId,
    required List<String> imageUrls,
    String? viewerId,
  });

  /// Record one unique view of [imageUrl] by [viewerId].
  Future<void> recordView({
    required String merchantId,
    required String viewerId,
    required String imageUrl,
  });

  /// Toggle like for [imageUrl].
  /// Returns new `likedByMe` on success, or `null` if the write failed.
  Future<bool?> toggleLike({
    required String merchantId,
    required String viewerId,
    required String imageUrl,
  });
}
