import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/infrastructure/logger_service.dart';
import '../../../followed_merchants/domain/repositories/followed_merchants_repository.dart';
import '../../../loyalty/domain/repositories/client_loyalty_repository.dart';
import '../../../promotions/domain/entities/promotion.dart';
import '../../domain/entities/client_notification.dart';
import '../../domain/repositories/client_notification_repository.dart';

/// Creates an in-app [ClientNotification] for every eligible follower of
/// [merchantId] and queues a push for each.
///
/// **Segment filtering (premium promotions only):**
/// When [Promotion.selectedClientType] is [ClientType.premium] and
/// [Promotion.targetSegments] is non-empty, only followers whose CRM segment
/// (from `loyalty_clients`) matches one of the target values receive the
/// notification.
///
/// The promo UI exposes: `'vip'`, `'soutien'`, `'habitue'`.
/// The loyalty engine produces: `'vip'`, `'habitue'`, `'nouveau'`, `'inactif'`.
/// `'soutien'` is intentionally mapped to both `'vip'` and `'habitue'`
/// (active regulars with ≥ 3 passages).
///
/// On any segment-lookup failure, the use case falls back to notifying ALL
/// followers rather than silently dropping promotions.
class NotifyFollowersOfPromotion {
  const NotifyFollowersOfPromotion({
    required FollowedMerchantsRepository followedRepo,
    required ClientNotificationRepository notificationRepo,
    required ClientLoyaltyRepository loyaltyRepo,
    required Future<bool> Function(String merchantId, String callerUid) isOwner,
  })  : _followedRepo = followedRepo,
        _notificationRepo = notificationRepo,
        _loyaltyRepo = loyaltyRepo,
        _isOwner = isOwner;

  final FollowedMerchantsRepository _followedRepo;
  final ClientNotificationRepository _notificationRepo;
  final ClientLoyaltyRepository _loyaltyRepo;
  /// Verifies that [callerUid] owns the merchant identified by [merchantId].
  final Future<bool> Function(String merchantId, String callerUid) _isOwner;

  /// Returns true if [clientSegment] satisfies any key in [targetSegments].
  ///
  /// `'soutien'` is a UI-level alias for active regulars (vip or habitue).
  static bool _segmentMatches(String clientSegment, List<String> targetSegments) {
    for (final target in targetSegments) {
      if (target == clientSegment) return true;
      if (target == 'soutien' &&
          (clientSegment == 'vip' || clientSegment == 'habitue')) return true;
    }
    return false;
  }

  Future<Result<int>> call({
    required String merchantId,
    required String merchantName,
    required Promotion promotion,
    required String callerUid,
  }) async {
    if (merchantId.isEmpty || promotion.id.isEmpty) return const Right(0);

    // Ownership guard — blocks cross-promotion (a merchant targeting another
    // merchant's followers). An empty callerUid means the caller is not
    // authenticated; we reject silently rather than crashing.
    if (callerUid.isEmpty || !(await _isOwner(merchantId, callerUid))) {
      LoggerService.logError(
        'NotifyFollowersOfPromotion: ownership check failed — aborting',
        error: 'callerUid=$callerUid merchantId=$merchantId',
      );
      return Left(UnexpectedFailure(
          message: 'Vous n\'êtes pas autorisé à envoyer des notifications pour ce commerce.'));
    }

    // 1. Resolve all follower IDs.
    final followersResult = await _followedRepo.getFollowerIds(merchantId);
    var targetIds = followersResult.fold((_) => <String>[], (ids) => ids);

    if (targetIds.isEmpty) {
      LoggerService.logInfo(
        'No followers to notify for promotion',
        context: {'merchantId': merchantId, 'promotionId': promotion.id},
      );
      return const Right(0);
    }

    // 2. Apply segment filter for premium promotions with explicit targets.
    //    gratuit and payant promotions broadcast to all followers.
    final mustFilter = promotion.selectedClientType == ClientType.premium &&
        promotion.targetSegments.isNotEmpty;

    if (mustFilter) {
      // Fetch loyalty segment map; fall back to all followers on error so
      // promotions are never silently dropped due to a transient read failure.
      final clientSegments =
          await _loyaltyRepo.getClientSegments(merchantId);

      if (clientSegments.isEmpty) {
        // Could not read loyalty data — broadcast to all to avoid data loss.
        LoggerService.logInfo(
          'Segment lookup returned empty — broadcasting promotion to all followers',
          context: {'merchantId': merchantId, 'promotionId': promotion.id},
        );
      } else {
        targetIds = targetIds.where((id) {
          // Followers with no loyalty doc have never visited → treat as 'nouveau'.
          final seg = clientSegments[id] ?? 'nouveau';
          return _segmentMatches(seg, promotion.targetSegments);
        }).toList();
      }
    }

    if (targetIds.isEmpty) {
      LoggerService.logInfo(
        'No followers match targeted segments — skipping promotion notification',
        context: {
          'merchantId': merchantId,
          'promotionId': promotion.id,
          'targetSegments': promotion.targetSegments,
        },
      );
      return const Right(0);
    }

    // 3. Write one notification doc per targeted follower.
    //    Cloud Function `onNotificationCreated` delivers the FCM push.
    int sent = 0;
    for (final clientId in targetIds) {
      final notification = ClientNotification(
        id: '',
        clientId: clientId,
        merchantId: merchantId,
        merchantName: merchantName,
        type: ClientNotificationType.promotion,
        title: 'Nouvelle promotion',
        body: '$merchantName\u202f: ${promotion.title}',
        isRead: false,
        createdAt: DateTime.now(),
        promotionId: promotion.id,
      );
      final result = await _notificationRepo.create(notification);
      result.fold(
        (f) => LoggerService.logError(
          'Failed to notify follower of promotion',
          error: f.message,
          context: {'clientId': clientId, 'promotionId': promotion.id},
        ),
        (_) => sent++,
      );
    }

    LoggerService.logInfo(
      'Promotion notifications sent',
      context: {
        'merchantId': merchantId,
        'promotionId': promotion.id,
        'sent': sent,
        'eligible': targetIds.length,
        'totalFollowers': followersResult.fold((_) => 0, (ids) => ids.length),
        'segments': promotion.targetSegments,
      },
    );

    return Right(sent);
  }
}
