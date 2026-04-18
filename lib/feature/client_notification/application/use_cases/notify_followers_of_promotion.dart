import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/infrastructure/logger_service.dart';
import '../../../followed_merchants/domain/repositories/followed_merchants_repository.dart';
import '../../../promotions/domain/entities/promotion.dart';
import '../../domain/entities/client_notification.dart';
import '../../domain/repositories/client_notification_repository.dart';

/// Creates an in-app [ClientNotification] for every client that follows
/// [merchantId], then queues a push notification for each.
///
/// This is the primary orchestration use case triggered when a merchant
/// publishes or activates a promotion.
class NotifyFollowersOfPromotion {
  const NotifyFollowersOfPromotion({
    required FollowedMerchantsRepository followedRepo,
    required ClientNotificationRepository notificationRepo,
  })  : _followedRepo = followedRepo,
        _notificationRepo = notificationRepo;

  final FollowedMerchantsRepository _followedRepo;
  final ClientNotificationRepository _notificationRepo;

  Future<Result<int>> call({
    required String merchantId,
    required String merchantName,
    required Promotion promotion,
  }) async {
    if (merchantId.isEmpty || promotion.id.isEmpty) {
      return const Right(0);
    }

    // 1. Resolve follower IDs via collection-group query.
    final followersResult = await _followedRepo.getFollowerIds(merchantId);
    final followerIds = followersResult.fold((_) => <String>[], (ids) => ids);

    if (followerIds.isEmpty) {
      LoggerService.logInfo(
        'No followers to notify',
        context: {'merchantId': merchantId, 'promotionId': promotion.id},
      );
      return const Right(0);
    }

    // 2. Write one notification document per follower.
    int sent = 0;
    for (final clientId in followerIds) {
      final notification = ClientNotification(
        id: '',
        clientId: clientId,
        merchantId: merchantId,
        merchantName: merchantName,
        type: ClientNotificationType.promotion,
        title: 'Nouvelle promotion',
        body: '$merchantName : ${promotion.title}',
        isRead: false,
        createdAt: DateTime.now(),
        promotionId: promotion.id,
      );
      final result = await _notificationRepo.create(notification);
      result.fold(
        (f) => LoggerService.logError(
          'Failed to create notification for follower',
          error: f.message,
          context: {'clientId': clientId},
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
        'total': followerIds.length,
      },
    );

    return Right(sent);
  }
}
