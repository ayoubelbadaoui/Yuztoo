import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../client_notification/domain/entities/client_notification.dart';
import '../../../client_notification/domain/repositories/client_notification_repository.dart';
import '../../../loyalty/domain/entities/client_merchant_loyalty_progress.dart';
import '../../../loyalty/domain/repositories/client_loyalty_repository.dart';
import '../../domain/entities/loyalty_program_config.dart';
import '../../domain/entities/merchant.dart';

/// Records a passage on behalf of a client when the merchant physically
/// validates it in real-time (BLE proximity or QR scan).
///
/// Unlike [RecordLoyaltyPassage] — which routes through `pending_passages` for
/// manual-validation merchants — this use case always writes directly to
/// `validated_passages` because the merchant's presence IS the confirmation.
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
        (merchant.loyaltyProgram?.programEnabled ??
            merchant.loyaltyEnabled);

    if (!loyaltyActive) {
      return _loyaltyRepo.applyPassageDeltas(
        merchantId: merchant.id,
        clientUid: clientUid,
        validatedPassagesDelta: 1,
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
      );
      await result.fold((_) async {}, (progress) async {
        final after = progress.validatedPassages;
        final threshold = config.visitsRequired;
        if (threshold > 0 && after >= threshold && (after - 1) < threshold) {
          await _writeRewardNotification(
              clientUid: clientUid, merchant: merchant, config: config);
        }
      });
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
    );
    await result.fold((_) async {}, (progress) async {
      final after = progress.cumulativeSpendEuros;
      final threshold = config.cumulativeSpendRequiredEuros;
      final before = after - spend;
      if (threshold > 0 && after >= threshold && before < threshold) {
        await _writeRewardNotification(
            clientUid: clientUid, merchant: merchant, config: config);
      }
    });
    return result;
  }

  Future<void> _writeRewardNotification({
    required String clientUid,
    required Merchant merchant,
    required LoyaltyProgramConfig config,
  }) async {
    final name = merchant.displayName?.isNotEmpty == true
        ? merchant.displayName!
        : merchant.name;
    final notification = ClientNotification(
      id: '',
      clientId: clientUid,
      merchantId: merchant.id,
      merchantName: name,
      type: ClientNotificationType.loyalty,
      title: 'Récompense disponible chez $name 🎁',
      body: _rewardLabel(config),
      isRead: false,
      createdAt: DateTime.now(),
    );
    await _notificationRepo.create(notification);
  }

  String _rewardLabel(LoyaltyProgramConfig config) {
    switch (config.rewardKind) {
      case LoyaltyRewardKind.purchaseVoucher:
        if (config.purchaseVoucherUsesPercent) {
          return 'Bon d\'achat ${config.purchaseVoucherValue.toStringAsFixed(0)} % disponible.';
        }
        return 'Bon d\'achat ${config.purchaseVoucherValue.toStringAsFixed(0)} € disponible.';
      case LoyaltyRewardKind.discountPercent:
        return 'Remise ${config.discountNextPurchasePercent.toStringAsFixed(0)} % sur votre prochain achat.';
      case LoyaltyRewardKind.freeProduct:
      case LoyaltyRewardKind.loyaltyPoints:
        return 'Votre récompense fidélité est disponible.';
    }
  }
}
