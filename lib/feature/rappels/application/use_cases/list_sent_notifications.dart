import '../../../../core/domain/core/result.dart';
import '../../domain/entities/sent_notification.dart';
import '../../domain/repositories/i_sent_notification_repository.dart';

class ListSentNotifications {
  const ListSentNotifications(this._repo);
  final ISentNotificationRepository _repo;

  Future<Result<List<SentNotification>>> call(String merchantId,
      {int limit = 20}) =>
      _repo.list(merchantId, limit: limit);
}
