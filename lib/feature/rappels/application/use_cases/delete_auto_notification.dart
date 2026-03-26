import '../../../../core/domain/core/result.dart';
import '../../domain/repositories/auto_notification_repository.dart';

class DeleteAutoNotification {
  const DeleteAutoNotification(this._repository);

  final AutoNotificationRepository _repository;

  Future<Result<Unit>> call({
    required String merchantId,
    required String notificationId,
  }) =>
      _repository.delete(
        merchantId: merchantId,
        notificationId: notificationId,
      );
}
