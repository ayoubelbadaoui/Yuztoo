import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../client_notification/domain/repositories/client_notification_repository.dart';
import '../../../loyalty/application/loyalty_passage_notification_helper.dart';
import '../../../loyalty/domain/entities/client_merchant_loyalty_progress.dart';
import '../../../loyalty/domain/repositories/client_loyalty_repository.dart';
import '../../domain/entities/loyalty_program_config.dart';
import '../../domain/entities/merchant.dart';

/// Records a passage when the merchant validates in person (BLE).
///
/// Clears a pending client request when present, then writes validated progress.
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

    if (!loyaltyActive) {
      final pendingClear = await _pendingClearDelta(clientUid, merchant.id);
      return _loyaltyRepo.applyPassageDeltas(
        merchantId: merchant.id,
        clientUid: clientUid,
        validatedPassagesDelta: 1,
        pendingPassagesDelta: pendingClear,
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

    final pendingClear = await _pendingClearDelta(clientUid, merchant.id);

    if (config.triggerType == LoyaltyTriggerType.visitCount) {
      final result = await _loyaltyRepo.applyPassageDeltas(
        merchantId: merchant.id,
        clientUid: clientUid,
        pendingPassagesDelta: pendingClear,
        validatedPassagesDelta: 1,
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
      pendingPassagesDelta: pendingClear,
      cumulativeSpendEurosDelta: spend,
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

  Future<int> _pendingClearDelta(String clientUid, String merchantId) async {
    final snap = await _loyaltyRepo.readProgress(merchantId, clientUid);
    if (snap.pendingPassages > 0) return -1;
    return 0;
  }
}
