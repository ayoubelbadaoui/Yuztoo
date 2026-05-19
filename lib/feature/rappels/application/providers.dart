import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../client_notification/infrastructure/client_notification_repository_provider.dart';
import '../../followed_merchants/infrastructure/followed_merchants_repository_provider.dart';
import '../../loyalty/application/client_loyalty_providers.dart'
    as loyalty_providers;
import '../../loyalty/infrastructure/client_loyalty_repository_provider.dart';
import '../../merchant/application/providers.dart' as merchant_providers;
import '../../merchant/domain/entities/loyalty_program_config.dart';
import '../../promotions/application/providers.dart' as promo_providers;
import '../domain/entities/active_notification.dart';
import '../domain/entities/pending_client_row.dart';
import '../domain/entities/rappel_alert.dart';
import '../domain/entities/sent_notification.dart';
import '../infrastructure/auto_notification_repository_provider.dart';
import '../infrastructure/rappels_pending_client_repository_provider.dart';
import '../infrastructure/sent_notification_repository_provider.dart';
import 'use_cases/acknowledge_new_client.dart';
import 'use_cases/create_auto_notification.dart';
import 'use_cases/delete_auto_notification.dart';
import 'use_cases/list_auto_notifications.dart';
import 'use_cases/list_sent_notifications.dart';
import 'use_cases/send_merchant_notification.dart';
import 'use_cases/update_auto_notification.dart';

// ─── Quick-send notifications ─────────────────────────────────────────────────

final sendMerchantNotificationProvider = Provider<SendMerchantNotification>((ref) {
  return SendMerchantNotification(
    followedRepo: ref.watch(followedMerchantsRepositoryProvider),
    notificationRepo: ref.watch(clientNotificationRepositoryProvider),
    sentNotifRepo: ref.watch(sentNotificationRepositoryProvider),
    loyaltyRepo: ref.watch(clientLoyaltyRepositoryProvider),
    isOwner: _verifyMerchantOwnership,
  );
});

/// Shared ownership verifier — reads the merchant document and checks owner_uid.
/// Fast path: if merchantId == callerUid (MVP model), skips the Firestore read.
Future<bool> _verifyMerchantOwnership(
    String merchantId, String callerUid) async {
  if (merchantId.isEmpty || callerUid.isEmpty) return false;
  if (merchantId == callerUid) return true;
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

final listSentNotificationsProvider = Provider<ListSentNotifications>((ref) {
  return ListSentNotifications(ref.watch(sentNotificationRepositoryProvider));
});

final sentNotificationsProvider =
    FutureProvider.autoDispose.family<List<SentNotification>, String>(
  (ref, merchantId) async {
    if (merchantId.isEmpty) return [];
    final result =
        await ref.read(listSentNotificationsProvider).call(merchantId);
    return result.fold((_) => [], (list) => list);
  },
);

// ─── Auto-notifications ────────────────────────────────────────────────────

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

// ─── Alertes ──────────────────────────────────────────────────────────────────

/// Computes live merchant alerts from promotions, loyalty pending, and
/// loyalty reward-ready clients. Returns at most one alert per [RappelAlertType].
final rappelsAlertsProvider =
    FutureProvider.autoDispose.family<List<RappelAlert>, String>(
  (ref, merchantId) async {
    if (merchantId.isEmpty) return [];

    final alerts = <RappelAlert>[];
    final now = DateTime.now();

    // ── 1. Promos expiring within 3 days ──────────────────────────────────
    final promosResult = await ref
        .read(promo_providers.listPromotionsByMerchantProvider)
        .call(merchantId);
    promosResult.fold(
      (_) {},
      (promos) {
        final expiringSoon = promos.where((p) {
          final diff = p.dateTo.difference(now).inDays;
          return diff >= 0 && diff <= 3;
        }).toList();
        if (expiringSoon.isNotEmpty) {
          alerts.add(RappelAlert(
            type: RappelAlertType.promoExpiring,
            count: expiringSoon.length,
            detail: expiringSoon.length == 1
                ? 'Expire dans ${expiringSoon.first.dateTo.difference(now).inDays} j'
                : null,
          ));
        }
      },
    );

    // ── 2. Clients eligible for their loyalty reward ───────────────────────
    final merchantAsync =
        await ref.read(merchant_providers.currentMerchantForOwnerProvider.future);
    final loyaltyConfig = merchantAsync?.loyaltyProgram ??
        LoyaltyProgramConfig.fallbackFromFlags(
          loyaltyEnabled: merchantAsync?.loyaltyEnabled ?? false,
        );
    if (loyaltyConfig.programEnabled) {
      final isSpendBased =
          loyaltyConfig.triggerType == LoyaltyTriggerType.purchaseTotal;
      final rewardReady = await ref.read(
        loyalty_providers.clientsWithRewardAvailableProvider(
          (
            merchantId: merchantId,
            visitsRequired: loyaltyConfig.visitsRequired,
            spendRequired: loyaltyConfig.cumulativeSpendRequiredEuros,
            isSpendBased: isSpendBased,
          ),
        ).future,
      );
      if (rewardReady.isNotEmpty) {
        alerts.add(RappelAlert(
          type: RappelAlertType.loyaltyRewardReady,
          count: rewardReady.length,
        ));
      }
    }

    return alerts;
  },
);
