import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../merchant/domain/entities/loyalty_program_config.dart';
import '../../../merchant/domain/entities/merchant.dart';
import '../../domain/entities/client_merchant_loyalty_progress.dart';
import '../../domain/repositories/client_loyalty_repository.dart';

/// Enregistre un passage boutique selon la config fidélité du commerçant.
class RecordLoyaltyPassage {
  RecordLoyaltyPassage(this._repository);

  final ClientLoyaltyRepository _repository;

  Future<Result<ClientMerchantLoyaltyProgress>> call({
    required String clientUid,
    required Merchant merchant,
    double? purchaseAmountEuros,
  }) async {
    if (clientUid.isEmpty) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(message: 'Utilisateur non connecté'),
      );
    }
    if (!merchant.loyaltyEnabled) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(message: 'La fidélité n’est pas activée pour ce commerce'),
      );
    }

    final LoyaltyProgramConfig config = merchant.loyaltyProgram ??
        LoyaltyProgramConfig.fallbackFromFlags(loyaltyEnabled: true);
    if (!config.programEnabled) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(message: 'Le programme de fidélité est désactivé'),
      );
    }

    final bool needsAmount = config.effectiveAskClientPurchaseAmount;
    if (needsAmount) {
      if (purchaseAmountEuros == null || purchaseAmountEuros <= 0) {
        return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
          UnexpectedFailure(message: 'Indiquez le montant de votre achat (€)'),
        );
      }
    }

    if (purchaseAmountEuros != null &&
        purchaseAmountEuros > 0 &&
        config.minimumPerVisitEnabled &&
        config.minimumPerVisitEuros != null &&
        config.minimumPerVisitEuros! > 0 &&
        purchaseAmountEuros < config.minimumPerVisitEuros!) {
      return Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(
          message:
              'Montant minimum par passage : ${config.minimumPerVisitEuros} €',
        ),
      );
    }

    if (config.passageValidation == LoyaltyPassageValidation.manual) {
      return _repository.applyPassageDeltas(
        merchantId: merchant.id,
        clientUid: clientUid,
        pendingPassagesDelta: 1,
      );
    }

    if (config.triggerType == LoyaltyTriggerType.visitCount) {
      return _repository.applyPassageDeltas(
        merchantId: merchant.id,
        clientUid: clientUid,
        validatedPassagesDelta: 1,
      );
    }

    final double spend = purchaseAmountEuros ?? 0;
    if (spend <= 0) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(
          message: 'Indiquez le montant à ajouter à votre cumul (€)',
        ),
      );
    }

    return _repository.applyPassageDeltas(
      merchantId: merchant.id,
      clientUid: clientUid,
      cumulativeSpendEurosDelta: spend,
    );
  }
}
