import '../../../../core/domain/core/result.dart';
import '../entities/active_notification.dart';

/// Repository for auto-notifications. Path: merchants/{merchantId}/auto_notifications/{id}
abstract class AutoNotificationRepository {
  /// Create an auto-notification for a merchant.
  Future<Result<ActiveNotification>> create({
    required String merchantId,
    required ActiveNotification notification,
  });

  /// List all auto-notifications for a merchant.
  Future<Result<List<ActiveNotification>>> listByMerchantId(String merchantId);

  /// Update an auto-notification (e.g. text, trigger, audience, isEnabled).
  Future<Result<ActiveNotification>> update(ActiveNotification notification);

  /// Delete an auto-notification.
  Future<Result<Unit>> delete({
    required String merchantId,
    required String notificationId,
  });
}
