import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../client_notification/domain/repositories/client_notification_repository.dart';
import '../../../merchant/domain/entities/loyalty_program_config.dart';
import '../../../merchant/domain/entities/merchant.dart';
import '../../domain/entities/client_merchant_loyalty_progress.dart';
import '../../domain/repositories/client_loyalty_repository.dart';
import '../loyalty_passage_notification_helper.dart';

/// Valide un passage en attente côté commerçant (Rappels).
class ValidatePendingLoyaltyPassage {
  ValidatePendingLoyaltyPassage(
    this._repository,
    this._notificationRepository,
  );

  final ClientLoyaltyRepository _repository;
  final ClientNotificationRepository _notificationRepository;

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

    final Result<ClientMerchantLoyaltyProgress> result;
    if (config.triggerType == LoyaltyTriggerType.visitCount) {
      result = await _repository.applyPassageDeltas(
        merchantId: merchant.id,
        clientUid: clientUid,
        pendingPassagesDelta: -1,
        validatedPassagesDelta: 1,
      );
      await result.fold(
        (_) async {},
        (progress) async {
          await writePassageValidatedNotification(
            repository: _notificationRepository,
            clientUid: clientUid,
            merchant: merchant,
            config: config,
            progressAfter: progress,
          );
        },
      );
      return result;
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

    final spendResult = await _repository.applyPassageDeltas(
      merchantId: merchant.id,
      clientUid: clientUid,
      pendingPassagesDelta: -1,
      cumulativeSpendEurosDelta: spend,
    );
    await spendResult.fold(
      (_) async {},
      (progress) async {
        await writePassageValidatedNotification(
          repository: _notificationRepository,
          clientUid: clientUid,
          merchant: merchant,
          config: config,
          progressAfter: progress,
          validatedSpendEuros: spend,
        );
      },
    );
    return spendResult;
  }
}
