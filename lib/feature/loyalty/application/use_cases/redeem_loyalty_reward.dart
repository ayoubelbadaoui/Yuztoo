import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../merchant/domain/entities/loyalty_program_config.dart';
import '../../../merchant/domain/entities/merchant.dart';
import '../../domain/entities/client_merchant_loyalty_progress.dart';
import '../../domain/repositories/client_loyalty_repository.dart';

/// Marks a loyalty reward as given by the merchant, deducting one reward cycle
/// from the client's progress so they can earn the next reward.
///
/// Only the merchant owner may call this; Firestore rules enforce this server-side.
class RedeemLoyaltyReward {
  RedeemLoyaltyReward(this._repository);

  final ClientLoyaltyRepository _repository;

  Future<Result<ClientMerchantLoyaltyProgress>> call({
    required String actingOwnerUid,
    required Merchant merchant,
    required String clientUid,
  }) async {
    if (actingOwnerUid.isEmpty || clientUid.isEmpty) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(message: 'Action non autorisée'),
      );
    }
    if (merchant.ownerUid != actingOwnerUid) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(
            message: 'Vous n\'êtes pas propriétaire de ce commerce'),
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

    final isSpendBased =
        config.triggerType == LoyaltyTriggerType.purchaseTotal;

    return _repository.redeemReward(
      merchantId: merchant.id,
      clientUid: clientUid,
      visitsRequired: config.visitsRequired,
      spendRequiredEuros: config.cumulativeSpendRequiredEuros,
      isSpendBased: isSpendBased,
    );
  }
}
