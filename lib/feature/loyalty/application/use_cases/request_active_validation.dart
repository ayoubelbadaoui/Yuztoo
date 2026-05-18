import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../auth/core/domain/entities/auth_user.dart';
import '../../../merchant/domain/entities/loyalty_program_config.dart';
import '../../../merchant/domain/entities/merchant.dart';
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
