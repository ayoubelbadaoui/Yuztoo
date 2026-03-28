import '../../../../core/domain/core/result.dart';
import '../../domain/entities/active_notification.dart';
import '../../domain/repositories/auto_notification_repository.dart';

class UpdateAutoNotification {
  const UpdateAutoNotification(this._repository);

  final AutoNotificationRepository _repository;

  Future<Result<ActiveNotification>> call(ActiveNotification notification) =>
      _repository.update(notification);
}
