import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/infrastructure/logger_service.dart';
import '../../../client_notification/domain/entities/client_notification.dart';
import '../../../client_notification/domain/promotion_segment_matching.dart';
import '../../../client_notification/domain/repositories/client_notification_repository.dart';
import '../../../followed_merchants/domain/repositories/followed_merchants_repository.dart';
import '../../../loyalty/domain/repositories/client_loyalty_repository.dart';
import '../../domain/entities/sent_notification.dart';
import '../../domain/repositories/i_sent_notification_repository.dart';

/// Sends a manual merchant notification to all (or targeted) followers.
///
/// Steps:
///   1. Resolve follower IDs, filtering by segment when audience is targeted.
///   2. Create `users/{clientId}/notifications/{id}` for each filtered follower
///      (Cloud Function `onNotificationCreated` sends the push).
///   3. Persist a `sent_notifications` record with the final count.
class SendMerchantNotification {
  const SendMerchantNotification({
    required FollowedMerchantsRepository followedRepo,
    required ClientNotificationRepository notificationRepo,
    required ISentNotificationRepository sentNotifRepo,
    required ClientLoyaltyRepository loyaltyRepo,
    required Future<bool> Function(String merchantId, String callerUid) isOwner,
  })  : _followedRepo = followedRepo,
        _notificationRepo = notificationRepo,
        _sentNotifRepo = sentNotifRepo,
        _loyaltyRepo = loyaltyRepo,
        _isOwner = isOwner;

  final FollowedMerchantsRepository _followedRepo;
  final ClientNotificationRepository _notificationRepo;
  final ISentNotificationRepository _sentNotifRepo;
  final ClientLoyaltyRepository _loyaltyRepo;
  /// Verifies that [callerUid] owns the merchant identified by [merchantId].
  final Future<bool> Function(String merchantId, String callerUid) _isOwner;

  Future<Result<int>> call({
    required String merchantId,
    required String merchantName,
    required String text,
    required String audience,
    List<String> segments = const [],
    required String callerUid,
  }) async {
    if (merchantId.isEmpty || text.trim().isEmpty) return const Right(0);

    // Ownership guard — prevents cross-merchant notification injection.
    if (callerUid.isEmpty || !(await _isOwner(merchantId, callerUid))) {
      LoggerService.logError(
        'SendMerchantNotification: ownership check failed — aborting',
        error: 'callerUid=$callerUid merchantId=$merchantId',
      );
      return const Left(UnexpectedFailure(
          message: 'Vous n\'êtes pas autorisé à envoyer des notifications pour ce commerce.'));
    }

    // 1. Get all follower IDs.
    final followersResult = await _followedRepo.getFollowerIds(merchantId);
    var targetIds = followersResult.fold((_) => <String>[], (ids) => ids);
    if (targetIds.isEmpty) return const Right(0);

    // Apply segment filter when audience is targeted and segments are specified.
    if (audience == 'Certains clients' && segments.isNotEmpty) {
      final clientSegments = await _loyaltyRepo.getClientSegments(merchantId);
      targetIds = targetIds.where((id) {
        final seg = clientSegments[id] ?? 'nouveau';
        return promotionSegmentMatchesTarget(seg, segments);
      }).toList();
    }
    if (targetIds.isEmpty) return const Right(0);

    // 2. Write one notification doc per targeted follower.
    int sent = 0;
    for (final clientId in targetIds) {
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

    // 3. Persist the send record + update quota counter.
    await _sentNotifRepo.create(SentNotification(
      id: '',
      merchantId: merchantId,
      text: text.trim(),
      audience: audience,
      segments: segments,
      sentCount: sent,
      sentAt: DateTime.now(),
    ));
    await _sentNotifRepo.incrementWeeklyNotifCount(merchantId);

    return Right(sent);
  }
}
