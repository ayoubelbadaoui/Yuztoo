import 'package:equatable/equatable.dart';

/// Loyalty tier computed from validated passage count.
enum ClientLoyaltyTier {
  /// 0–2 passages — first-time visitor.
  nouveau,
  /// 3–9 passages — regular supporter.
  soutien,
  /// 10–19 passages — loyal customer.
  habitue,
  /// 20+ passages — VIP client.
  vip;

  /// Compute tier from validated passage count.
  static ClientLoyaltyTier fromPassages(int passages) {
    if (passages >= 20) return vip;
    if (passages >= 10) return habitue;
    if (passages >= 3) return soutien;
    return nouveau;
  }

  /// Human-readable French label.
  String get label {
    switch (this) {
      case ClientLoyaltyTier.nouveau:
        return 'Nouveau';
      case ClientLoyaltyTier.soutien:
        return 'Soutien';
      case ClientLoyaltyTier.habitue:
        return 'Habitué';
      case ClientLoyaltyTier.vip:
        return 'VIP';
    }
  }
}

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
