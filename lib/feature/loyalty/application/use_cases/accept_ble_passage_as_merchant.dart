import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../domain/entities/active_validation_request.dart';
import '../../domain/failures/ble_passage_failure.dart';
import '../../domain/repositories/active_validation_repository.dart';

/// Merchant BLE: stamp merchant-side connection on the live session.
class AcceptBlePassageAsMerchant {
  AcceptBlePassageAsMerchant(this._repository);

  final ActiveValidationRepository _repository;

  Future<Result<ActiveValidationRequest>> call({
    required String merchantId,
    required String clientUid,
    required ActiveValidationRequest? existingSession,
  }) async {
    if (merchantId.isEmpty || clientUid.isEmpty) {
      return const Left<AppFailure, ActiveValidationRequest>(
        UnexpectedFailure(message: 'Session invalide'),
      );
    }

    final session = existingSession;
    if (session == null) {
      return const Left<AppFailure, ActiveValidationRequest>(
        BlePassageSessionFailure(
          'Aucune demande en cours — le client doit d\'abord confirmer la connexion.',
        ),
      );
    }
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
        BlePassageSessionFailure('La demande a expiré. Le client doit réessayer.'),
      );
    }

    if (!session.isMerchantBleConnected) {
      final mark = await _repository.markMerchantBleConnected(
        merchantId: merchantId,
        clientUid: clientUid,
      );
      final markFailure = mark.fold((f) => f, (_) => null);
      if (markFailure != null) {
        return Left<AppFailure, ActiveValidationRequest>(markFailure);
      }
    }

    return Right<AppFailure, ActiveValidationRequest>(
      ActiveValidationRequest(
        merchantId: session.merchantId,
        clientUid: session.clientUid,
        clientDisplayName: session.clientDisplayName,
        clientPhotoUrl: session.clientPhotoUrl,
        status: session.status,
        programSnapshot: session.programSnapshot,
        createdAt: session.createdAt,
        openedAt: session.openedAt,
        cancelReason: session.cancelReason,
        declaredSpendEuros: session.declaredSpendEuros,
        resultValidatedDelta: session.resultValidatedDelta,
        resultSpendDelta: session.resultSpendDelta,
        completedAt: session.completedAt,
        source: session.source,
        clientBleConnectedAt: session.clientBleConnectedAt,
        merchantBleConnectedAt:
            session.merchantBleConnectedAt ?? DateTime.now(),
        merchantDisplayName: session.merchantDisplayName,
      ),
    );
  }
}
