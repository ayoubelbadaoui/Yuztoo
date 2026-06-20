import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../client_notification/domain/repositories/client_notification_repository.dart';
import '../../../loyalty/application/loyalty_passage_notification_helper.dart';
import '../../../loyalty/domain/entities/client_merchant_loyalty_progress.dart';
import '../../../loyalty/domain/loyalty_passage_program_policy.dart';
import '../../../loyalty/domain/repositories/client_loyalty_repository.dart';
import '../../domain/entities/loyalty_program_config.dart';
import '../../domain/entities/merchant.dart';

/// Records a passage when the merchant validates in person (BLE).
///
/// Synchronous write to loyalty_clients — no pending queue (those went away
/// with the active_validations rewrite). The merchant decides on the spot
/// whether the spend amount is needed (purchase-total programs) or not
/// (visit-count programs).
class MerchantRecordClientPassage {
  MerchantRecordClientPassage(this._loyaltyRepo, this._notificationRepo);

  final ClientLoyaltyRepository _loyaltyRepo;
  final ClientNotificationRepository _notificationRepo;

  Future<Result<ClientMerchantLoyaltyProgress>> call({
    required String clientUid,
    required Merchant merchant,
    double? purchaseAmountEuros,
  }) async {
    if (clientUid.isEmpty) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(message: 'Client invalide'),
      );
    }
    final loyaltyActive = merchant.loyaltyEnabled &&
        (merchant.loyaltyProgram?.programEnabled ?? merchant.loyaltyEnabled);

    final enforceCooldown = merchantPassageCooldownEnabled(merchant);

    if (!loyaltyActive) {
      return _loyaltyRepo.applyPassageDeltas(
        merchantId: merchant.id,
        clientUid: clientUid,
        validatedPassagesDelta: 1,
        enforcePassageCooldown: enforceCooldown,
      );
    }

    final LoyaltyProgramConfig config = merchant.loyaltyProgram ??
        LoyaltyProgramConfig.fallbackFromFlags(loyaltyEnabled: true);

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

    if (config.triggerType == LoyaltyTriggerType.visitCount) {
      final result = await _loyaltyRepo.applyPassageDeltas(
        merchantId: merchant.id,
        clientUid: clientUid,
        validatedPassagesDelta: 1,
        enrollProgram: config,
        enforcePassageCooldown: enforceCooldown,
      );
      await result.fold(
        (_) async {},
        (progress) async {
          await writePassageValidatedNotification(
            repository: _notificationRepo,
            clientUid: clientUid,
            merchant: merchant,
            config: config,
            progressAfter: progress,
          );
        },
      );
      return result;
    }

    final double spend = purchaseAmountEuros ?? 0;
    if (spend <= 0) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(message: 'Indiquez le montant de l\'achat (€)'),
      );
    }
    final result = await _loyaltyRepo.applyPassageDeltas(
      merchantId: merchant.id,
      clientUid: clientUid,
      cumulativeSpendEurosDelta: spend,
      enrollProgram: config,
      enforcePassageCooldown: enforceCooldown,
    );
    await result.fold(
      (_) async {},
      (progress) async {
        await writePassageValidatedNotification(
          repository: _notificationRepo,
          clientUid: clientUid,
          merchant: merchant,
          config: config,
          progressAfter: progress,
          validatedSpendEuros: spend,
        );
      },
    );
    return result;
  }
}
