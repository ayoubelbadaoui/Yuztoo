import '../../../../core/domain/core/result.dart';
import '../entities/sent_notification.dart';

abstract class ISentNotificationRepository {
  /// Returns the last [limit] sent notifications for a merchant, newest first.
  Future<Result<List<SentNotification>>> list(
    String merchantId, {
    int limit = 20,
  });

  /// Persists a record after a batch send (id is empty — repo assigns one).
  Future<Result<SentNotification>> create(SentNotification notification);

  /// Increments the rolling weekly quota counter on the merchant doc.
  /// Resets the counter to 1 + updates [weekly_notif_reset_at] if 7+ days
  /// have passed since the last reset (or if never set).
  Future<void> incrementWeeklyNotifCount(String merchantId);
}
