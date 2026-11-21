import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/core/application/providers.dart' show currentUserIdProvider;
import '../domain/app_media_release.dart';
import '../domain/app_media_slot.dart';
import '../domain/repositories/app_media_repository.dart';
import '../infrastructure/firestore_app_media_repository.dart';

final appMediaRepositoryProvider = Provider<AppMediaRepository>((ref) {
  return FirestoreAppMediaRepository(FirebaseFirestore.instance);
});

/// One-shot resolve: release (1 read) then catalog only if allowed (0–1 read).
/// No realtime listeners — keeps Firebase usage low; restart / invalidate to refresh.
final resolvedAppMediaUrlsProvider =
    FutureProvider<Map<AppMediaSlotId, String>>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  // Signed-out: never hit Firestore/Storage — bundled assets only.
  if (uid == null) return const {};

  final repo = ref.watch(appMediaRepositoryProvider);
  final release = await repo.fetchRelease();
  if (!release.allowsUser(uid)) {
    return const {};
  }

  return repo.fetchCatalogUrls();
});

/// Convenience: URL for one slot, or null → use bundled fallback.
final resolvedAppMediaUrlProvider =
    Provider.family<AsyncValue<String?>, AppMediaSlotId>((ref, slotId) {
  final asyncMap = ref.watch(resolvedAppMediaUrlsProvider);
  return asyncMap.whenData((map) => map[slotId]);
});

// Re-export for UI that needs status (debug / future banners).
typedef AppMediaReleaseSnapshot = AppMediaRelease;
