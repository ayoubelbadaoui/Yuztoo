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
}
