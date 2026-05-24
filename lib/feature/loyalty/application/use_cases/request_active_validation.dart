import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../auth/core/domain/entities/auth_user.dart';
import '../../../merchant/domain/entities/loyalty_program_config.dart';
import '../../../merchant/domain/entities/merchant.dart';
import '../../domain/failures/ble_passage_failure.dart';
import '../../domain/loyalty_passage_program_policy.dart';
import '../../domain/repositories/active_validation_repository.dart';

/// Client-side: opens a synchronous validation session at the merchant. The
/// merchant's app sees the new doc instantly via [watchMerchantQueue] and
/// pops a smart per-program form. Replaces the legacy
/// `RecordLoyaltyPassage → pending_passages += 1` flow.
class RequestActiveValidation {
  RequestActiveValidation(this._repository);

  final ActiveValidationRepository _repository;

  Future<Result<void>> call({
    required AuthUser client,
    required Merchant merchant,
  }) async {
    if (client.id.isEmpty) {
      return const Left<AppFailure, void>(
        UnexpectedFailure(message: 'Utilisateur non connecté'),
      );
    }
    if (!isVitrinePassageRequestAllowedForMerchant(merchant)) {
      if (!isMerchantLoyaltyPassageActive(merchant)) {
        return const Left<AppFailure, void>(
          UnexpectedFailure(message: 'Le programme de fidélité est désactivé'),
        );
      }
      return const Left<AppFailure, void>(
        BlePassageSessionFailure(
          'Présentez-vous au comptoir : ce commerce valide les passages '
          'en proximité (BLE).',
        ),
      );
    }

    final LoyaltyProgramConfig config = merchantLiveLoyaltyProgram(merchant);

    final displayName = (client.displayName?.trim().isNotEmpty == true
        ? client.displayName!.trim()
        : (client.email?.split('@').first.trim() ?? 'Client'));

    return _repository.createForClient(
      merchantId: merchant.id,
      clientUid: client.id,
      clientDisplayName: displayName,
      clientPhotoUrl: client.photoUrl,
      programSnapshot: config,
    );
  }
}
