import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/infrastructure/firebase_providers.dart';
import '../../auth/core/application/providers.dart' as auth_providers;
import '../domain/entities/yuztoo_news.dart';
import '../domain/repositories/i_yuztoo_news_repository.dart';
import '../infrastructure/firestore_yuztoo_news_repository.dart';
import '../infrastructure/yuztoo_news_seen_local_service.dart';

final yuztooNewsRepositoryProvider = Provider<IYuztooNewsRepository>((ref) {
  return FirestoreYuztooNewsRepository(ref.watch(firebaseFirestoreProvider));
});

/// Active entries visible to the signed-in user (live + own preview).
/// Kept alive so switching tabs does not re-open the stream.
final yuztooNewsFeedProvider = StreamProvider<List<YuztooNews>>((ref) {
  final viewerUid = ref.watch(auth_providers.currentUserIdProvider);
  return ref.watch(yuztooNewsRepositoryProvider).watchLatest(
        viewerUid: viewerUid,
      );
});

/// The actu to show right now, or null when nothing is due / visible.
final currentYuztooNewsProvider = Provider<YuztooNews?>((ref) {
  final entries = ref.watch(yuztooNewsFeedProvider).valueOrNull;
  if (entries == null || entries.isEmpty) return null;
  final viewerUid = ref.watch(auth_providers.currentUserIdProvider);
  return selectCurrentYuztooNews(
    entries,
    now: DateTime.now(),
    viewerUid: viewerUid,
  );
});

final yuztooNewsSeenServiceProvider = Provider<YuztooNewsSeenLocalService>(
  (ref) => YuztooNewsSeenLocalService(),
);

/// Id of the last actu the user opened — drives the "new" dot.
final yuztooNewsSeenIdProvider = FutureProvider<String?>((ref) {
  final userId = ref.watch(auth_providers.currentUserIdProvider) ?? '';
  return ref.watch(yuztooNewsSeenServiceProvider).readSeenId(userId);
});

/// Marks [newsId] read and refreshes [yuztooNewsSeenIdProvider].
final markYuztooNewsSeenProvider =
    Provider<Future<void> Function(String newsId)>((ref) {
  return (newsId) async {
    final userId = ref.read(auth_providers.currentUserIdProvider) ?? '';
    await ref.read(yuztooNewsSeenServiceProvider).markSeen(userId, newsId);
    ref.invalidate(yuztooNewsSeenIdProvider);
  };
});
