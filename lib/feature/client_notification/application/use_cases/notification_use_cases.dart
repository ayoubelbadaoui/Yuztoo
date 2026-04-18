import '../../../../core/domain/core/result.dart';
import '../../domain/entities/client_notification.dart';
import '../../domain/repositories/client_notification_repository.dart';

/// Returns a real-time stream of notifications for a given client.
class WatchClientNotifications {
  const WatchClientNotifications(this._repository);

  final ClientNotificationRepository _repository;

  Stream<List<ClientNotification>> call(String clientId) =>
      _repository.watchForClient(clientId);
}

/// Marks a single notification as read.
class MarkNotificationRead {
  const MarkNotificationRead(this._repository);

  final ClientNotificationRepository _repository;

  Future<Result<Unit>> call(String clientId, String notificationId) =>
      _repository.markAsRead(clientId, notificationId);
}

/// Marks all notifications for a client as read.
class MarkAllNotificationsRead {
  const MarkAllNotificationsRead(this._repository);

  final ClientNotificationRepository _repository;

  Future<Result<Unit>> call(String clientId) =>
      _repository.markAllAsRead(clientId);
}
