import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/result.dart';
import '../../../client_notification/domain/entities/client_notification.dart';
import '../../../client_notification/domain/repositories/client_notification_repository.dart';
import '../../../followed_merchants/domain/repositories/followed_merchants_repository.dart';
import '../../domain/entities/sent_notification.dart';
import '../../domain/repositories/i_sent_notification_repository.dart';

/// Sends a manual merchant notification to all (or targeted) followers.
///
/// Steps:
///   1. Resolve follower IDs.
///   2. Create `users/{clientId}/notifications/{id}` for each
///      (Cloud Function `onNotificationCreated` sends the push).
///   3. Persist a `sent_notifications` record with the final count.
class SendMerchantNotification {
  const SendMerchantNotification({
    required FollowedMerchantsRepository followedRepo,
    required ClientNotificationRepository notificationRepo,
    required ISentNotificationRepository sentNotifRepo,
  })  : _followedRepo = followedRepo,
        _notificationRepo = notificationRepo,
        _sentNotifRepo = sentNotifRepo;

  final FollowedMerchantsRepository _followedRepo;
  final ClientNotificationRepository _notificationRepo;
  final ISentNotificationRepository _sentNotifRepo;

  Future<Result<int>> call({
    required String merchantId,
    required String merchantName,
    required String text,
    required String audience,
    List<String> segments = const [],
  }) async {
    if (merchantId.isEmpty || text.trim().isEmpty) return const Right(0);

    // 1. Get all follower IDs.
    final followersResult = await _followedRepo.getFollowerIds(merchantId);
    final allIds = followersResult.fold((_) => <String>[], (ids) => ids);
    if (allIds.isEmpty) return const Right(0);

    // 2. Write one notification doc per follower.
    int sent = 0;
    for (final clientId in allIds) {
      final notif = ClientNotification(
        id: '',
        clientId: clientId,
        merchantId: merchantId,
        merchantName: merchantName,
        type: ClientNotificationType.auto,
        title: merchantName,
        body: text.trim(),
        isRead: false,
        createdAt: DateTime.now(),
      );
      final result = await _notificationRepo.create(notif);
      result.fold((_) {}, (_) => sent++);
    }

    // 3. Persist the send record.
    await _sentNotifRepo.create(SentNotification(
      id: '',
      merchantId: merchantId,
      text: text.trim(),
      audience: audience,
      segments: segments,
      sentCount: sent,
      sentAt: DateTime.now(),
    ));

    return Right(sent);
  }
}
