import '../../../../core/domain/core/result.dart';
import '../../../merchant/domain/entities/loyalty_program_config.dart';
import '../entities/active_validation_request.dart';

/// Synchronous merchant-validates-client sessions.
///
/// Lifecycle: client tap `createForClient` → merchant listens on
/// `watchMerchantQueue` → on submit `completeSession` (also writes
/// loyalty_clients deltas) → on dismiss `cancelByMerchant`. The client can
/// `cancelByClient` while still in 'awaiting' state.
abstract class ActiveValidationRepository {
  /// Creates (or overwrites) the per-(merchant, client) session doc in
  /// 'awaiting' state. Used when the client taps "Demander un passage".
  Future<Result<void>> createForClient({
    required String merchantId,
    required String clientUid,
    required String clientDisplayName,
    String? clientPhotoUrl,
    required LoyaltyProgramConfig programSnapshot,
  });

  /// BLE: client tapped a nearby merchant — creates session with BLE metadata.
  Future<Result<void>> createBleSession({
    required String merchantId,
    required String clientUid,
    required String clientDisplayName,
    String? clientPhotoUrl,
    required LoyaltyProgramConfig programSnapshot,
    required String merchantDisplayName,
  });

  /// BLE: merchant tapped client row — stamps merchant-side connection time.
  Future<Result<void>> markMerchantBleConnected({
    required String merchantId,
    required String clientUid,
  });

  /// Streams the client's own session for a given merchant (null when no doc).
  /// Used by the loyalty card banner and the storefront waiting sheet.
  Stream<ActiveValidationRequest?> watchClientSession({
    required String merchantId,
    required String clientUid,
  });

  /// One-shot read of a session doc — used when opening validation from a
  /// push before the merchant queue stream has caught up.
  Future<Result<ActiveValidationRequest?>> getClientSession({
    required String merchantId,
    required String clientUid,
  });

  /// Streams every 'awaiting' session under the merchant. Used by the global
  /// merchant-shell listener to pop the validation form. Completed/cancelled
  /// docs are filtered out client-side so the merchant only sees actionable
  /// requests.
  Stream<List<ActiveValidationRequest>> watchMerchantQueue(String merchantId);

  /// Stamps `opened_at` server timestamp on the session — drives the client
  /// banner copy from "en attente" to "le commerçant valide votre passage".
  Future<Result<void>> markOpened({
    required String merchantId,
    required String clientUid,
  });

  /// Merchant-side completion. Writes `result_*` + `completed_at` + status,
  /// then deletes the session doc as housekeeping. The caller is responsible
  /// for writing the loyalty_clients deltas in the same atomic moment.
  Future<Result<void>> completeSession({
    required String merchantId,
    required String clientUid,
    int? resultValidatedDelta,
    double? resultSpendDelta,
    double? declaredSpendEuros,
  });

  /// Merchant-side dismissal — no counter changes.
  Future<Result<void>> cancelByMerchant({
    required String merchantId,
    required String clientUid,
    String? reason,
  });

  /// Client-side cancel — flips status from 'awaiting' to 'cancelled' with
  /// `cancel_reason: 'client_cancelled'`.
  Future<Result<void>> cancelByClient({
    required String merchantId,
    required String clientUid,
  });
}
