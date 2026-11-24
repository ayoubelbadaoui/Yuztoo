import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/infrastructure/firebase_providers.dart';
import '../domain/entities/news_photo_engagement.dart';
import '../domain/repositories/news_photo_engagement_repository.dart';
import '../infrastructure/firestore_news_photo_engagement_repository.dart';

final newsPhotoEngagementRepositoryProvider =
    Provider<NewsPhotoEngagementRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirestoreNewsPhotoEngagementRepository(firestore: firestore);
});

/// Engagement map keyed by image URL for a merchant gallery.
///
/// [arg] is `"merchantId|viewerId|url1\nurl2\n..."` so Riverpod caches per
/// gallery fingerprint. Use [newsPhotoEngagementKey] to build it.
/// Only the first two `|` are separators; URLs are newline-separated.
final newsPhotoEngagementMapProvider = FutureProvider.autoDispose
    .family<Map<String, NewsPhotoEngagement>, String>((ref, key) async {
  final firstSep = key.indexOf('|');
  final secondSep = firstSep < 0 ? -1 : key.indexOf('|', firstSep + 1);
  if (secondSep < 0) return const {};
  final merchantId = key.substring(0, firstSep);
  final rawViewer = key.substring(firstSep + 1, secondSep);
  final viewerId = rawViewer.isEmpty ? null : rawViewer;
  final urls = key
      .substring(secondSep + 1)
      .split('\n')
      .where((u) => u.isNotEmpty)
      .toList();
  if (merchantId.isEmpty || urls.isEmpty) return const {};

  final repo = ref.watch(newsPhotoEngagementRepositoryProvider);
  return repo.getEngagementForUrls(
    merchantId: merchantId,
    imageUrls: urls,
    viewerId: viewerId,
  );
});

String newsPhotoEngagementKey({
  required String merchantId,
  required List<String> imageUrls,
  String? viewerId,
}) {
  return '$merchantId|${viewerId ?? ''}|${imageUrls.join('\n')}';
}

final recordNewsPhotoViewProvider = Provider<
    Future<void> Function({
      required String merchantId,
      required String viewerId,
      required String imageUrl,
    })>((ref) {
  final repo = ref.watch(newsPhotoEngagementRepositoryProvider);
  return ({
    required String merchantId,
    required String viewerId,
    required String imageUrl,
  }) =>
      repo.recordView(
        merchantId: merchantId,
        viewerId: viewerId,
        imageUrl: imageUrl,
      );
});

final toggleNewsPhotoLikeProvider = Provider<
    Future<bool?> Function({
      required String merchantId,
      required String viewerId,
      required String imageUrl,
    })>((ref) {
  final repo = ref.watch(newsPhotoEngagementRepositoryProvider);
  return ({
    required String merchantId,
    required String viewerId,
    required String imageUrl,
  }) =>
      repo.toggleLike(
        merchantId: merchantId,
        viewerId: viewerId,
        imageUrl: imageUrl,
      );
});
