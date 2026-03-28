import '../../../../core/domain/core/result.dart';
import '../../domain/entities/active_notification.dart';
import '../../domain/repositories/auto_notification_repository.dart';

class CreateAutoNotification {
  const CreateAutoNotification(this._repository);

  final AutoNotificationRepository _repository;

  Future<Result<ActiveNotification>> call({
    required String merchantId,
    required ActiveNotification notification,
  }) =>
      _repository.create(merchantId: merchantId, notification: notification);
}
