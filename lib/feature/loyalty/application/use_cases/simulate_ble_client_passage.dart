import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../merchant/domain/entities/loyalty_program_config.dart';
import '../../../merchant/domain/entities/merchant.dart';
import '../../domain/failures/ble_passage_failure.dart';
import '../../domain/loyalty_passage_program_policy.dart';
import '../../domain/repositories/active_validation_repository.dart';

/// Debug / merchant QA: creates a BLE `active_validations` session as if the
/// client confirmed connection from [ClientBleBroadcastScreen].
class SimulateBleClientPassage {
  SimulateBleClientPassage(this._repository);

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
    if (!isBlePassageAllowedForMerchant(merchant)) {
      if (!isMerchantLoyaltyPassageActive(merchant)) {
        return const Left<AppFailure, void>(
          UnexpectedFailure(
            message: 'La fidélité n\'est pas activée pour ce commerce',
          ),
        );
      }
      return const Left<AppFailure, void>(
        BlePassageSessionFailure(
          'Simulation BLE indisponible en mode validation manuelle.',
        ),
      );
    }

    final LoyaltyProgramConfig config = merchantLiveLoyaltyProgram(merchant);

    final name = clientDisplayName.trim().isNotEmpty
        ? clientDisplayName.trim()
        : 'Client';
    final merchantName = merchant.displayName?.trim().isNotEmpty == true
        ? merchant.displayName!.trim()
        : merchant.name;

    return _repository.createBleSession(
      merchantId: merchant.id,
      clientUid: clientUid,
      clientDisplayName: name,
      clientPhotoUrl: clientPhotoUrl,
      programSnapshot: config,
      merchantDisplayName: merchantName,
    );
  }
}
