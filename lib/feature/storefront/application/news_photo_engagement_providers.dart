import 'dart:async';

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

/// In-memory session cache for Actualité likes/views.
///
/// Lets the heart flip instantly and survive gallery open/close without waiting
/// on Firestore. Network results seed the cache; in-flight optimistic writes
/// win until confirmed or rolled back.
class NewsPhotoEngagementCache extends Notifier<int> {
  final Map<String, NewsPhotoEngagement> _entries = {};
  final Set<String> _pendingWrites = {};

  @override
  int build() => 0;

  static String entryKey({
    required String merchantId,
    required String imageUrl,
    String? viewerId,
  }) =>
      '$merchantId|${viewerId ?? ''}|$imageUrl';

  NewsPhotoEngagement? get({
    required String merchantId,
    required String imageUrl,
    String? viewerId,
  }) =>
      _entries[entryKey(
        merchantId: merchantId,
        imageUrl: imageUrl,
        viewerId: viewerId,
      )];

  /// Overlay cache entries on top of a server map for one gallery.
  Map<String, NewsPhotoEngagement> overlay({
    required String merchantId,
    required String? viewerId,
    required Map<String, NewsPhotoEngagement> server,
  }) {
    final out = Map<String, NewsPhotoEngagement>.from(server);
    final prefix = '$merchantId|${viewerId ?? ''}|';
    for (final e in _entries.entries) {
      if (!e.key.startsWith(prefix)) continue;
      final url = e.key.substring(prefix.length);
      if (url.isEmpty) continue;
      out[url] = e.value;
    }
    return out;
  }

  /// Seed from server without clobbering in-flight optimistic likes.
  void seedFromServer({
    required String merchantId,
    required String? viewerId,
    required Map<String, NewsPhotoEngagement> server,
  }) {
    var changed = false;
    for (final e in server.entries) {
      final k = entryKey(
        merchantId: merchantId,
        imageUrl: e.key,
        viewerId: viewerId,
      );
      if (_pendingWrites.contains(k)) continue;
      final prev = _entries[k];
      if (prev == e.value) continue;
      _entries[k] = e.value;
      changed = true;
    }
    if (changed) state++;
  }

  void put({
    required String merchantId,
    required String? viewerId,
    required NewsPhotoEngagement engagement,
    bool pending = false,
  }) {
    final k = entryKey(
      merchantId: merchantId,
      imageUrl: engagement.imageUrl,
      viewerId: viewerId,
    );
    _entries[k] = engagement;
    if (pending) {
      _pendingWrites.add(k);
    } else {
      _pendingWrites.remove(k);
    }
    state++;
  }

  void clearPending({
    required String merchantId,
    required String? viewerId,
    required String imageUrl,
  }) {
    _pendingWrites.remove(entryKey(
      merchantId: merchantId,
      imageUrl: imageUrl,
      viewerId: viewerId,
    ));
  }
}

final newsPhotoEngagementCacheProvider =
    NotifierProvider<NewsPhotoEngagementCache, int>(
  NewsPhotoEngagementCache.new,
);

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
  final server = await repo.getEngagementForUrls(
    merchantId: merchantId,
    imageUrls: urls,
    viewerId: viewerId,
  );

  // Keep listening so seed runs; cache notifier is not autoDispose.
  ref.watch(newsPhotoEngagementCacheProvider);
  ref.read(newsPhotoEngagementCacheProvider.notifier).seedFromServer(
        merchantId: merchantId,
        viewerId: viewerId,
        server: server,
      );

  return ref.read(newsPhotoEngagementCacheProvider.notifier).overlay(
        merchantId: merchantId,
        viewerId: viewerId,
        server: server,
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

/// Instant like: update session cache now, persist to Firestore in background.
///
/// Returns the new `likedByMe` immediately. On write failure the cache is
/// rolled back and [onRolledBack] is invoked so the UI can revert.
bool toggleNewsPhotoLikeOptimistic({
  required WidgetRef ref,
  required String merchantId,
  required String viewerId,
  required String imageUrl,
  NewsPhotoEngagement? current,
  void Function()? onRolledBack,
}) {
  final cache = ref.read(newsPhotoEngagementCacheProvider.notifier);
  final existing = current ??
      cache.get(
        merchantId: merchantId,
        imageUrl: imageUrl,
        viewerId: viewerId,
      ) ??
      NewsPhotoEngagement(imageUrl: imageUrl);

  final nextLiked = !existing.likedByMe;
  final optimistic = existing.copyWith(
    likedByMe: nextLiked,
    likesCount:
        (existing.likesCount + (nextLiked ? 1 : -1)).clamp(0, 1 << 30),
  );

  cache.put(
    merchantId: merchantId,
    viewerId: viewerId,
    engagement: optimistic,
    pending: true,
  );

  unawaited(() async {
    final saved = await ref.read(toggleNewsPhotoLikeProvider)(
      merchantId: merchantId,
      viewerId: viewerId,
      imageUrl: imageUrl,
    );
    if (saved == null) {
      cache.put(
        merchantId: merchantId,
        viewerId: viewerId,
        engagement: existing,
        pending: false,
      );
      onRolledBack?.call();
      return;
    }
    cache.put(
      merchantId: merchantId,
      viewerId: viewerId,
      engagement: optimistic.copyWith(likedByMe: saved),
      pending: false,
    );
  }());

  return nextLiked;
}
