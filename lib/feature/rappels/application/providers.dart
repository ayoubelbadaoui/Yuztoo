import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/active_notification.dart';
import '../domain/entities/pending_client_row.dart';
import '../infrastructure/auto_notification_repository_provider.dart';
import '../infrastructure/rappels_pending_client_repository_provider.dart';
import 'use_cases/acknowledge_new_client.dart';
import 'use_cases/create_auto_notification.dart';
import 'use_cases/delete_auto_notification.dart';
import 'use_cases/list_auto_notifications.dart';
import 'use_cases/update_auto_notification.dart';

final createAutoNotificationProvider = Provider<CreateAutoNotification>((ref) {
  final repo = ref.watch(autoNotificationRepositoryProvider);
  return CreateAutoNotification(repo);
});

final listAutoNotificationsProvider = Provider<ListAutoNotifications>((ref) {
  final repo = ref.watch(autoNotificationRepositoryProvider);
  return ListAutoNotifications(repo);
});

final updateAutoNotificationProvider = Provider<UpdateAutoNotification>((ref) {
  final repo = ref.watch(autoNotificationRepositoryProvider);
  return UpdateAutoNotification(repo);
});

final deleteAutoNotificationProvider = Provider<DeleteAutoNotification>((ref) {
  final repo = ref.watch(autoNotificationRepositoryProvider);
  return DeleteAutoNotification(repo);
});

/// Auto-notifications for the current merchant (from storefront). Invalidate to refresh.
final autoNotificationsProvider =
    FutureProvider.family<List<ActiveNotification>, String>((ref, merchantId) async {
  final listUseCase = ref.read(listAutoNotificationsProvider);
  final result = await listUseCase.call(merchantId);
  return result.fold((_) => <ActiveNotification>[], (list) => list);
});

// ─── Pending clients (nouveaux clients) ───────────────────────────────────────

final acknowledgeNewClientProvider = Provider<AcknowledgeNewClient>((ref) {
  final repo = ref.watch(rappelsPendingClientRepoInterfaceProvider);
  return AcknowledgeNewClient(repo);
});

/// Live stream of unacknowledged new clients for [merchantId].
final pendingClientsForMerchantProvider =
    StreamProvider.autoDispose.family<List<PendingClientRow>, String>(
  (ref, merchantId) {
    if (merchantId.isEmpty) {
      return Stream<List<PendingClientRow>>.value(<PendingClientRow>[]);
    }
    final repo = ref.watch(rappelsPendingClientRepoInterfaceProvider);
    return repo.watchPendingClients(merchantId);
  },
);
