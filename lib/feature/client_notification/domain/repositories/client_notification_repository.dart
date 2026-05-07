import '../../../../core/domain/core/result.dart';
import '../entities/client_notification.dart';

/// Repository for client in-app notifications.
///
/// Firestore path: `users/{clientId}/notifications/{notificationId}`.
abstract class ClientNotificationRepository {
  /// Real-time stream of a client's notifications, newest first.
  Stream<List<ClientNotification>> watchForClient(String clientId);

  /// Persist a new notification document (id may be empty — repo assigns one).
  Future<Result<ClientNotification>> create(ClientNotification notification);

  /// Mark a single notification as read.
  Future<Result<Unit>> markAsRead(String clientId, String notificationId);

  /// Mark every notification for [clientId] as read.
  Future<Result<Unit>> markAllAsRead(String clientId);

  /// Delete a single notification document.
  Future<Result<Unit>> deleteNotification(
      String clientId, String notificationId);

  /// Delete all notifications for [clientId] in a single batch.
  /// Operates on the most-recent 50 notifications (matching the watch limit).
  Future<Result<Unit>> deleteAllNotifications(String clientId);
}
