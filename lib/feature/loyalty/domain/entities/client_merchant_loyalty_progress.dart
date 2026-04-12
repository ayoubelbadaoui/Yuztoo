import 'package:equatable/equatable.dart';

/// Progression fidélité d'un client chez un commerçant (Firestore:
/// `merchants/{merchantId}/loyalty_clients/{clientUid}`).
class ClientMerchantLoyaltyProgress extends Equatable {
  const ClientMerchantLoyaltyProgress({
    required this.validatedPassages,
    required this.pendingPassages,
    required this.cumulativeSpendEuros,
  });

  const ClientMerchantLoyaltyProgress.empty()
      : validatedPassages = 0,
        pendingPassages = 0,
        cumulativeSpendEuros = 0;

  final int validatedPassages;
  final int pendingPassages;
  final double cumulativeSpendEuros;

  @override
  List<Object?> get props =>
      <Object?>[validatedPassages, pendingPassages, cumulativeSpendEuros];
}
