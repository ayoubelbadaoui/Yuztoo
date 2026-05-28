import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/infrastructure/firebase_providers.dart';
import '../domain/entities/profile_view_stats.dart';
import '../domain/repositories/profile_view_repository.dart';
import '../infrastructure/firestore_profile_view_repository.dart';

/// Live [ProfileViewRepository] backed by Firestore. Override in tests.
final profileViewRepositoryProvider = Provider<ProfileViewRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirestoreProfileViewRepository(firestore: firestore);
});

/// Best-effort recorder used by client storefront screens. Idempotent per
/// (viewer, UTC day) by repository contract — safe to call on every
/// `StoreProfileScreen` mount, even on rebuilds.
///
/// Returns a typed function rather than the repo directly so callers
/// don't have to construct the `nowUtc` argument; the provider closes
/// over `DateTime.now().toUtc()` at call time so each call gets a fresh
/// timestamp.
final recordProfileViewProvider = Provider<
    Future<void> Function({
      required String merchantId,
      required String viewerId,
    })>((ref) {
  final repo = ref.watch(profileViewRepositoryProvider);
  return ({required String merchantId, required String viewerId}) =>
      repo.recordView(
        merchantId: merchantId,
        viewerId: viewerId,
        nowUtc: DateTime.now().toUtc(),
      );
});

/// 7-day sliding window stats for the dashboard's "VUES / SEMAINE" card.
///
/// Auto-disposed so leaving the dashboard releases the cache; the read
/// is cheap (two `count()` aggregations) and we want fresh data when
/// the merchant returns to the screen.
final profileViewWeeklyStatsProvider = FutureProvider.autoDispose
    .family<ProfileViewStats, String>((ref, merchantId) async {
  if (merchantId.isEmpty) return ProfileViewStats.empty;
  final repo = ref.watch(profileViewRepositoryProvider);
  return repo.getWeeklyStats(
    merchantId: merchantId,
    nowUtc: DateTime.now().toUtc(),
  );
});
