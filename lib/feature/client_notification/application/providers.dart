import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/core/application/providers.dart';
import '../../auth/core/application/state/auth_state.dart';
import '../../followed_merchants/infrastructure/followed_merchants_repository_provider.dart';
import '../../loyalty/infrastructure/client_loyalty_repository_provider.dart';
import '../domain/entities/client_notification.dart';
import '../infrastructure/client_notification_repository_provider.dart';
import 'use_cases/notification_use_cases.dart';
import 'use_cases/notify_followers_of_promotion.dart';

export '../domain/entities/client_notification.dart';
export '../infrastructure/client_notification_repository_provider.dart';

/// One-shot target for [NotificationsScreen] when opened from FCM or shell.
///
/// [initialTab] is `'alertes'` or `'promos'` (matches the screen tab state).
class NotificationInboxDeepLink {
  const NotificationInboxDeepLink({
    required this.initialTab,
    this.notificationId,
  });

  final String initialTab;
  final String? notificationId;
}

/// Cleared by [NotificationsScreen] after it applies tab / scroll intent.
final notificationInboxDeepLinkProvider =
    StateProvider<NotificationInboxDeepLink?>((ref) => null);

/// Shared ownership verifier — reads the merchant document and checks owner_uid.
/// Fast path: if merchantId == callerUid (MVP model), skips the Firestore read.
Future<bool> _verifyMerchantOwnership(
    String merchantId, String callerUid) async {
  if (merchantId.isEmpty || callerUid.isEmpty) return false;
  if (merchantId == callerUid) return true; // MVP fast path
  try {
    final doc = await FirebaseFirestore.instance
        .collection('merchants')
        .doc(merchantId)
        .get();
    return (doc.data()?['owner_uid'] as String?) == callerUid;
  } catch (_) {
    return false;
  }
}

// ─── Use-case providers ───────────────────────────────────────────────────────

final notifyFollowersOfPromotionProvider =
    Provider<NotifyFollowersOfPromotion>((ref) {
  return NotifyFollowersOfPromotion(
    followedRepo: ref.watch(followedMerchantsRepositoryProvider),
    notificationRepo: ref.watch(clientNotificationRepositoryProvider),
    loyaltyRepo: ref.watch(clientLoyaltyRepositoryProvider),
    isOwner: _verifyMerchantOwnership,
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

final deleteNotificationProvider = Provider<DeleteNotification>((ref) {
  return DeleteNotification(ref.watch(clientNotificationRepositoryProvider));
});

final deleteAllNotificationsProvider = Provider<DeleteAllNotifications>((ref) {
  return DeleteAllNotifications(
      ref.watch(clientNotificationRepositoryProvider));
});

// ─── Real-time stream for the authenticated client ────────────────────────────

/// Muted merchant IDs for the current client — used to filter notifications.
final mutedMerchantIdsProvider = FutureProvider<Set<String>>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (authState is! Authenticated) return const <String>{};
  final repo = ref.watch(followedMerchantsRepositoryProvider);
  final result = await repo.getMutedMerchantIds(authState.user.id);
  return result.fold((_) => const <String>{}, (v) => v);
});

/// Live stream of the current client's notifications, newest first.
/// Filters out notifications from merchants the user has muted.
/// Returns empty when unauthenticated.
final clientNotificationsStreamProvider =
    StreamProvider<List<ClientNotification>>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState is! Authenticated) return const Stream.empty();
  final mutedIds =
      ref.watch(mutedMerchantIdsProvider).valueOrNull ?? const <String>{};
  final useCase = ref.watch(watchClientNotificationsProvider);
  return useCase(authState.user.id).map(
    (notifications) => notifications
        .where((n) => n.merchantId.isEmpty || !mutedIds.contains(n.merchantId))
        .toList(),
  );
});

/// Unread notification count — drives the badge dot on the bottom nav.
final unreadNotificationCountProvider = Provider<int>((ref) {
  final list =
      ref.watch(clientNotificationsStreamProvider).valueOrNull ?? [];
  return list.where((n) => !n.isRead).length;
});
