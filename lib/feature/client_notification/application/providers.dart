import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/core/application/providers.dart';
import '../../auth/core/application/state/auth_state.dart';
import '../../followed_merchants/infrastructure/followed_merchants_repository_provider.dart';
import '../domain/entities/client_notification.dart';
import '../infrastructure/client_notification_repository_provider.dart';
import 'use_cases/notification_use_cases.dart';
import 'use_cases/notify_followers_of_promotion.dart';

export '../domain/entities/client_notification.dart';
export '../infrastructure/client_notification_repository_provider.dart';

// ─── Use-case providers ───────────────────────────────────────────────────────

final notifyFollowersOfPromotionProvider =
    Provider<NotifyFollowersOfPromotion>((ref) {
  return NotifyFollowersOfPromotion(
    followedRepo: ref.watch(followedMerchantsRepositoryProvider),
    notificationRepo: ref.watch(clientNotificationRepositoryProvider),
  );
});

final watchClientNotificationsProvider =
    Provider<WatchClientNotifications>((ref) {
  return WatchClientNotifications(ref.watch(clientNotificationRepositoryProvider));
});

final markNotificationReadProvider = Provider<MarkNotificationRead>((ref) {
  return MarkNotificationRead(ref.watch(clientNotificationRepositoryProvider));
});

final markAllNotificationsReadProvider =
    Provider<MarkAllNotificationsRead>((ref) {
  return MarkAllNotificationsRead(
      ref.watch(clientNotificationRepositoryProvider));
});

// ─── Real-time stream for the authenticated client ────────────────────────────

/// Live stream of the current client's notifications, newest first.
/// Returns empty when unauthenticated.
final clientNotificationsStreamProvider =
    StreamProvider<List<ClientNotification>>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState is! Authenticated) return const Stream.empty();
  final useCase = ref.watch(watchClientNotificationsProvider);
  return useCase(authState.user.id);
});

/// Unread notification count — drives the badge dot on the bottom nav.
final unreadNotificationCountProvider = Provider<int>((ref) {
  final list =
      ref.watch(clientNotificationsStreamProvider).valueOrNull ?? [];
  return list.where((n) => !n.isRead).length;
});
