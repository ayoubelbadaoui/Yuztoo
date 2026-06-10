import '../../../../core/infrastructure/logger_service.dart';

/// Funnel events emitted along the NFC + vitrine scan path.
///
/// Names are kept stable and snake_case so they can be picked up
/// verbatim by Firebase Analytics, BigQuery exports or grep across
/// LoggerService output. **Do not rename without a migration plan.**
abstract class NfcAnalyticsEvent {
  static const String tagReadAttempt = 'nfc_tag_read_attempt';
  static const String tagReadSuccess = 'nfc_tag_read_success';
  static const String tagReadEmpty = 'nfc_tag_read_empty';
  static const String tagReadInvalid = 'nfc_tag_read_invalid';
  static const String tagReadCancelled = 'nfc_tag_read_cancelled';
  static const String tagReadError = 'nfc_tag_read_error';

  static const String tagWriteAttempt = 'nfc_tag_write_attempt';
  static const String tagWriteSuccess = 'nfc_tag_write_success';
  static const String tagWriteRejectedNotNdef = 'nfc_tag_write_rejected_not_ndef';
  static const String tagWriteRejectedReadOnly = 'nfc_tag_write_rejected_read_only';
  static const String tagWriteRejectedCapacity = 'nfc_tag_write_rejected_capacity';
  static const String tagWriteCancelled = 'nfc_tag_write_cancelled';
  static const String tagWriteError = 'nfc_tag_write_error';

  static const String scanArrival = 'vitrine_scan_arrival';
  static const String scanResultGuest = 'vitrine_scan_result_guest';
  static const String scanResultNotFollowing = 'vitrine_scan_result_not_following';
  static const String scanResultLoyaltyInactive = 'vitrine_scan_result_loyalty_inactive';
  static const String scanResultVisitRecorded = 'vitrine_scan_result_visit_recorded';
  static const String scanResultAwaitingMerchant = 'vitrine_scan_result_awaiting_merchant';
  static const String scanResultCooldownBlocked = 'vitrine_scan_result_cooldown_blocked';
  static const String scanResultError = 'vitrine_scan_result_error';
}

/// Thin analytics shim. Today it forwards to [LoggerService] so the
/// funnel is grep-able from device logs and BigQuery via the existing
/// Crashlytics/Analytics breadcrumb pipeline. When Firebase Analytics
/// is added, override [logEvent] in a Riverpod provider with
/// `analytics.logEvent(name: ..., parameters: ...)` and the rest of
/// the codebase keeps working unchanged.
class NfcAnalytics {
  const NfcAnalytics();

  void logEvent(String name, {Map<String, Object?>? parameters}) {
    LoggerService.logInfo(
      'analytics.event',
      context: <String, Object?>{
        'event': name,
        if (parameters != null) ...parameters,
      },
    );
  }
}
