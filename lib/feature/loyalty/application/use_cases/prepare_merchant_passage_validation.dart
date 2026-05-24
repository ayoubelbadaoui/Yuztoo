import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../domain/entities/active_validation_request.dart';
import '../../domain/failures/ble_passage_failure.dart';

/// Validates that a merchant-side session can open [ActiveValidationSheet].
///
/// Does **not** stamp `merchant_ble_connected_at` — that requires an explicit
/// merchant proximity confirmation ([AcceptBlePassageAsMerchant]) before
/// opening the sheet.
class PrepareMerchantPassageValidation {
  const PrepareMerchantPassageValidation();

  Future<Result<ActiveValidationRequest>> call({
    required String merchantId,
    required ActiveValidationRequest session,
  }) async {
    if (!session.isAwaiting) {
      return Left<AppFailure, ActiveValidationRequest>(
        BlePassageSessionFailure(
          session.isCompleted
              ? 'Ce passage a déjà été validé.'
              : 'Cette demande a été annulée.',
        ),
      );
    }
    if (session.isExpired) {
      return const Left<AppFailure, ActiveValidationRequest>(
        BlePassageSessionFailure(
          'La demande a expiré. Le client doit réessayer.',
        ),
      );
    }
    if (session.isBle && !session.isMerchantBleConnected) {
      return const Left<AppFailure, ActiveValidationRequest>(
        BlePassageSessionFailure(
          'Confirmez la proximité du client (BLE) avant de valider le passage.',
        ),
      );
    }
    return Right<AppFailure, ActiveValidationRequest>(session);
  }
}
