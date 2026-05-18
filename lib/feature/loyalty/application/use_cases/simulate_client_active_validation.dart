import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../merchant/domain/entities/loyalty_program_config.dart';
import '../../../merchant/domain/entities/merchant.dart';
import '../../domain/repositories/active_validation_repository.dart';

/// Debug / merchant QA: creates an `active_validations` session as if the client
/// tapped « Valider » on the vitrine. Requires Firestore rule
/// `activeValidationMerchantSimulateCreateValid`.
class SimulateClientActiveValidation {
  SimulateClientActiveValidation(this._repository);

  final ActiveValidationRepository _repository;

  Future<Result<void>> call({
    required Merchant merchant,
    required String clientUid,
    required String clientDisplayName,
    String? clientPhotoUrl,
  }) async {
    if (clientUid.isEmpty) {
      return const Left<AppFailure, void>(
        UnexpectedFailure(message: 'Client invalide'),
      );
    }
    if (!merchant.loyaltyEnabled) {
      return const Left<AppFailure, void>(
        UnexpectedFailure(
          message: 'La fidélité n\'est pas activée pour ce commerce',
        ),
      );
    }

    final LoyaltyProgramConfig config = merchant.loyaltyProgram ??
        LoyaltyProgramConfig.fallbackFromFlags(loyaltyEnabled: true);
    if (!config.programEnabled) {
      return const Left<AppFailure, void>(
        UnexpectedFailure(message: 'Le programme de fidélité est désactivé'),
      );
    }

    final name = clientDisplayName.trim().isNotEmpty
        ? clientDisplayName.trim()
        : 'Client';

    return _repository.createForClient(
      merchantId: merchant.id,
      clientUid: clientUid,
      clientDisplayName: name,
      clientPhotoUrl: clientPhotoUrl,
      programSnapshot: config,
    );
  }
}
