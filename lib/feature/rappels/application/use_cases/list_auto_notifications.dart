import '../../../../core/domain/core/result.dart';
import '../../domain/entities/active_notification.dart';
import '../../domain/repositories/auto_notification_repository.dart';

class ListAutoNotifications {
  const ListAutoNotifications(this._repository);

  final AutoNotificationRepository _repository;

  Future<Result<List<ActiveNotification>>> call(String merchantId) =>
      _repository.listByMerchantId(merchantId);
}
