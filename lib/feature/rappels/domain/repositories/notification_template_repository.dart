import '../../../../core/domain/core/result.dart';
import '../entities/notification_template.dart';

/// CRUD over a merchant's saved notification templates. Reads via stream
/// so the picker stays live when the merchant edits a template on
/// another device or just deleted one — useful when their rappels
/// screen is open in two windows / tabs.
abstract class NotificationTemplateRepository {
  Stream<List<NotificationTemplate>> watchAll(String merchantId);

  /// Persists a new template. Returns the assigned id on success.
  Future<Result<String>> create({
    required String merchantId,
    required NotificationTemplate template,
  });

  /// Updates name/text/audience/segments. The id MUST already exist.
  Future<Result<Unit>> update({
    required String merchantId,
    required NotificationTemplate template,
  });

  Future<Result<Unit>> delete({
    required String merchantId,
    required String templateId,
  });
}
