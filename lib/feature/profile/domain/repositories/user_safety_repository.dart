import '../../../../core/domain/core/result.dart';

/// App-store-safety primitives for the *current signed-in user*: blocking
/// merchants they no longer want to hear from, reporting abusive content,
/// and listing their current blocklist for UI filtering.
///
/// Strict scope rules:
///   - Block list is per-user, private, write-only-by-owner. Merchants must
///     never learn they were blocked (App Store guideline 1.2 — silent &
///     one-sided).
///   - Report writes are append-only. The collection is NOT readable from
///     the client; admins triage via Firebase Console with the Admin SDK.
abstract class UserSafetyRepository {
  /// Stream of merchant IDs the current user has blocked. Emits an empty
  /// list when there is no signed-in user. Used by the carnet,
  /// notifications, and recommendations UIs to filter blocked merchants
  /// out of every feed.
  Stream<Set<String>> watchBlockedMerchantIds(String userId);

  /// Adds [merchantId] to the user's blocklist. Idempotent: a second call
  /// with the same id is a no-op success. Writing only `created_at`
  /// (server timestamp) so we never leak the user's reason for blocking.
  Future<Result<Unit>> blockMerchant({
    required String userId,
    required String merchantId,
  });

  /// Removes [merchantId] from the user's blocklist. Idempotent.
  Future<Result<Unit>> unblockMerchant({
    required String userId,
    required String merchantId,
  });

  /// Files a moderation report. The schema mirrors the Firestore rules
  /// allowlist exactly — passing an out-of-bounds [reason] or
  /// [targetType] returns a Left so the UI never tries to write a
  /// payload that would be rejected at the rules layer.
  Future<Result<Unit>> submitReport({
    required String reporterUid,
    required ReportTargetType targetType,
    required String targetId,
    required ReportReason reason,
    String? message,
  });
}

/// Allowed report reason categories. The wire form is the snake_case
/// string, locked to match the Firestore rules.
enum ReportReason {
  spam('spam'),
  harassment('harassment'),
  inappropriate('inappropriate'),
  fraud('fraud'),
  fakeBusiness('fake_business'),
  other('other');

  const ReportReason(this.wire);
  final String wire;

  /// Human-readable French label for the picker.
  String get label {
    switch (this) {
      case ReportReason.spam:
        return 'Spam / Sollicitations répétées';
      case ReportReason.harassment:
        return 'Harcèlement / Comportement abusif';
      case ReportReason.inappropriate:
        return 'Contenu inapproprié';
      case ReportReason.fraud:
        return 'Arnaque / Fraude';
      case ReportReason.fakeBusiness:
        return 'Faux commerce';
      case ReportReason.other:
        return 'Autre';
    }
  }
}

/// Allowed report target categories. Locked to match the Firestore rules.
enum ReportTargetType {
  merchant('merchant'),
  promotion('promotion'),
  notification('notification'),
  user('user');

  const ReportTargetType(this.wire);
  final String wire;
}
