import '../../../../core/domain/core/result.dart';
import '../entities/scheduled_notification.dart';

abstract class ScheduledNotificationRepository {
  /// Live stream of pending + recently completed scheduled notifications
  /// for a merchant. The UI filters to `status == pending` for the
  /// active list; sent/cancelled/failed entries can be shown in a
  /// "historique" section if/when the screen grows.
  Stream<List<ScheduledNotification>> watchAll(String merchantId);

  /// Schedules a new manual notification. Returns the doc id on success.
  Future<Result<String>> schedule({
    required String merchantId,
    required String createdByUid,
    required String text,
    required String audience,
    required List<String> segments,
    required DateTime scheduledAt,
  });

  /// Cancels a pending scheduled notification — safe no-op if the doc
  /// has already been picked up by the tick CF and flipped to `sent`.
  Future<Result<Unit>> cancel({
    required String merchantId,
    required String scheduledId,
  });
}
