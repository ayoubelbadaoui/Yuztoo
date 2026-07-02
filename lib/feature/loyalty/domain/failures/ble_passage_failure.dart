import '../../../../core/domain/core/failure.dart';

/// Follow merchant before BLE fidélité session.
final class FollowRequiredFailure extends AppFailure {
  const FollowRequiredFailure({
    required this.merchantId,
    required this.merchantDisplayName,
  }) : super(
          'Suivez $merchantDisplayName pour être éligible au système de fidélité.',
        );

  final String merchantId;
  final String merchantDisplayName;
}

/// Merchant loyalty program not active for BLE passage.
final class MerchantLoyaltyInactiveFailure extends AppFailure {
  const MerchantLoyaltyInactiveFailure([String? customMessage])
      : super(
          customMessage ?? 'La fidélité n\'est pas activée pour ce commerce.',
        );
}

/// Session no longer actionable (expired, completed, cancelled).
final class BlePassageSessionFailure extends AppFailure {
  const BlePassageSessionFailure(super.reason);
}
