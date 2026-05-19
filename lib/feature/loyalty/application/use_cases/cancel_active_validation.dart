import '../../../../core/domain/core/result.dart';
import '../../domain/repositories/active_validation_repository.dart';

/// Either side dismisses a live validation session.
///
/// - Merchant taps "Refuser" → flips status to 'cancelled' with the supplied
///   reason. The client's listener pops the waiting sheet and shows a toast.
/// - Client taps "Annuler" on the in-app banner → flips status to 'cancelled'
///   with reason 'client_cancelled'. The merchant's validation sheet listens in
///   real time and closes.
class CancelActiveValidation {
  CancelActiveValidation(this._repository);

  final ActiveValidationRepository _repository;

  Future<Result<void>> byMerchant({
    required String merchantId,
    required String clientUid,
    String? reason,
  }) =>
      _repository.cancelByMerchant(
        merchantId: merchantId,
        clientUid: clientUid,
        reason: reason,
      );

  Future<Result<void>> byClient({
    required String merchantId,
    required String clientUid,
  }) =>
      _repository.cancelByClient(
        merchantId: merchantId,
        clientUid: clientUid,
      );
}
