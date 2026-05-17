import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/infrastructure/logger_service.dart';
import '../../../followed_merchants/domain/repositories/followed_merchants_repository.dart';
import '../../../loyalty/domain/repositories/client_loyalty_repository.dart';
import '../../../promotions/domain/entities/promotion.dart';
import '../../domain/entities/client_notification.dart';
import '../../domain/promotion_segment_matching.dart';
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
/// Segment lookup mirrors [SendMerchantNotification]: followers without a
/// loyalty row are treated as `'nouveau'`; an empty segment map does not
/// widen the audience to all followers.
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
      return const Left(UnexpectedFailure(
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
      final clientSegments =
          await _loyaltyRepo.getClientSegments(merchantId);
      final beforeCount = targetIds.length;
      final segDistribution = <String, int>{};
      targetIds = targetIds.where((id) {
        // Same as Rappels manual sends: no loyalty doc → 'nouveau'.
        final seg = clientSegments[id] ?? 'nouveau';
        segDistribution.update(seg, (v) => v + 1, ifAbsent: () => 1);
        return promotionSegmentMatchesTarget(seg, promotion.targetSegments);
      }).toList();
      LoggerService.logInfo(
        'Segment filter applied to promotion notification',
        context: <String, Object?>{
          'merchantId': merchantId,
          'promotionId': promotion.id,
          'targetSegments': promotion.targetSegments,
          'followersBeforeFilter': beforeCount,
          'followersAfterFilter': targetIds.length,
          'segmentDistribution': segDistribution,
          'loyaltyRowsLoaded': clientSegments.length,
        },
      );
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
