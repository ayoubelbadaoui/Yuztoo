import '../../client_notification/domain/entities/client_notification.dart';
import '../../client_notification/domain/repositories/client_notification_repository.dart';
import '../../merchant/domain/entities/loyalty_program_config.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../domain/entities/client_merchant_loyalty_progress.dart';

/// Writes an in-app (+ FCM via [onNotificationCreated]) notification when a
/// merchant validates a client passage.
Future<void> writePassageValidatedNotification({
  required ClientNotificationRepository repository,
  required String clientUid,
  required Merchant merchant,
  required LoyaltyProgramConfig config,
  required ClientMerchantLoyaltyProgress progressAfter,
  double? validatedSpendEuros,
}) async {
  final name = merchant.displayName?.isNotEmpty == true
      ? merchant.displayName!
      : merchant.name;

  final String body;
  if (config.triggerType == LoyaltyTriggerType.purchaseTotal &&
      validatedSpendEuros != null &&
      validatedSpendEuros > 0) {
    final spent = progressAfter.cumulativeSpendEuros.toStringAsFixed(0);
    final needed =
        config.cumulativeSpendRequiredEuros.toStringAsFixed(0);
    body =
        'Montant comptabilisé : ${validatedSpendEuros.toStringAsFixed(2)} €. '
        'Cumul : $spent € / $needed €.';
  } else {
    final v = progressAfter.validatedPassages;
    final needed = config.visitsRequired;
    body = needed > 0
        ? 'Passage validé ($v / $needed passages).'
        : 'Votre passage a été validé.';
  }

  await repository.create(
    ClientNotification(
      id: '',
      clientId: clientUid,
      merchantId: merchant.id,
      merchantName: name,
      type: ClientNotificationType.loyalty,
      title: 'Passage validé chez $name ✓',
      body: body,
      isRead: false,
      createdAt: DateTime.now(),
    ),
  );

  if (_rewardJustUnlocked(config, progressAfter, validatedSpendEuros)) {
    await writeRewardUnlockedNotification(
      repository: repository,
      clientUid: clientUid,
      merchant: merchant,
      config: config,
    );
  }
}

bool _rewardJustUnlocked(
  LoyaltyProgramConfig config,
  ClientMerchantLoyaltyProgress after,
  double? spendDelta,
) {
  if (config.triggerType == LoyaltyTriggerType.visitCount) {
    final threshold = config.visitsRequired;
    if (threshold <= 0) return false;
    final before = after.validatedPassages - 1;
    return after.validatedPassages >= threshold && before < threshold;
  }
  final threshold = config.cumulativeSpendRequiredEuros;
  if (threshold <= 0 || spendDelta == null || spendDelta <= 0) return false;
  final before = after.cumulativeSpendEuros - spendDelta;
  return after.cumulativeSpendEuros >= threshold && before < threshold;
}

Future<void> writeRewardUnlockedNotification({
  required ClientNotificationRepository repository,
  required String clientUid,
  required Merchant merchant,
  required LoyaltyProgramConfig config,
}) async {
  final name = merchant.displayName?.isNotEmpty == true
      ? merchant.displayName!
      : merchant.name;
  await repository.create(
    ClientNotification(
      id: '',
      clientId: clientUid,
      merchantId: merchant.id,
      merchantName: name,
      type: ClientNotificationType.loyalty,
      title: 'Récompense disponible chez $name 🎁',
      body: _rewardLabel(config),
      isRead: false,
      createdAt: DateTime.now(),
    ),
  );
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
      return config.freeProductSummaryLabel?.isNotEmpty == true
          ? 'Offert : ${config.freeProductSummaryLabel}'
          : 'Produit offert disponible.';
    case LoyaltyRewardKind.loyaltyPoints:
      return 'Points fidélité crédités (${config.pointsPerEuro.toStringAsFixed(1)} pts/€).';
  }
}
