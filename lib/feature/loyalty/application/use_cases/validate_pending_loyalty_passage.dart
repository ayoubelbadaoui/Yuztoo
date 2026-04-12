import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../merchant/domain/entities/loyalty_program_config.dart';
import '../../../merchant/domain/entities/merchant.dart';
import '../../domain/entities/client_merchant_loyalty_progress.dart';
import '../../domain/repositories/client_loyalty_repository.dart';

/// Valide un passage en attente (fidélité à validation manuelle), côté commerçant.
class ValidatePendingLoyaltyPassage {
  ValidatePendingLoyaltyPassage(this._repository);

  final ClientLoyaltyRepository _repository;

  Future<Result<ClientMerchantLoyaltyProgress>> call({
    required String actingOwnerUid,
    required Merchant merchant,
    required String clientUid,
    double? declaredSpendEuros,
  }) async {
    if (actingOwnerUid.isEmpty || clientUid.isEmpty) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(message: 'Action non autorisée'),
      );
    }
    if (merchant.ownerUid != actingOwnerUid) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(message: 'Vous n’êtes pas propriétaire de ce commerce'),
      );
    }
    if (!merchant.loyaltyEnabled) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(message: 'Fidélité inactive'),
      );
    }

    final LoyaltyProgramConfig config = merchant.loyaltyProgram ??
        LoyaltyProgramConfig.fallbackFromFlags(loyaltyEnabled: true);
    if (!config.programEnabled) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(message: 'Programme de fidélité désactivé'),
      );
    }
    if (config.passageValidation != LoyaltyPassageValidation.manual) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(
          message: 'La validation des passages est automatique pour ce programme',
        ),
      );
    }

    if (config.triggerType == LoyaltyTriggerType.visitCount) {
      return _repository.applyPassageDeltas(
        merchantId: merchant.id,
        clientUid: clientUid,
        pendingPassagesDelta: -1,
        validatedPassagesDelta: 1,
      );
    }

    final double spend = declaredSpendEuros ?? 0;
    if (spend <= 0) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(
          message: 'Indiquez le montant d’achat à prendre en compte (€)',
        ),
      );
    }
    if (config.minimumPerVisitEnabled &&
        config.minimumPerVisitEuros != null &&
        config.minimumPerVisitEuros! > 0 &&
        spend < config.minimumPerVisitEuros!) {
      return Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(
          message:
              'Montant inférieur au minimum par passage (${config.minimumPerVisitEuros} €)',
        ),
      );
    }

    return _repository.applyPassageDeltas(
      merchantId: merchant.id,
      clientUid: clientUid,
      pendingPassagesDelta: -1,
      cumulativeSpendEurosDelta: spend,
    );
  }
}
