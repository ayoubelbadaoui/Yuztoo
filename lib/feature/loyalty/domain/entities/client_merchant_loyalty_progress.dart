import 'package:equatable/equatable.dart';

import '../../../merchant/domain/entities/loyalty_program_config.dart';

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
    this.isFirstVisit = false,
    this.hasFirstVisit = false,
    this.welcomeBonClaimed = false,
    this.enrolledProgram,
    this.programStatus,
  });

  const ClientMerchantLoyaltyProgress.empty()
      : validatedPassages = 0,
        pendingPassages = 0,
        cumulativeSpendEuros = 0,
        isFirstVisit = false,
        hasFirstVisit = false,
        welcomeBonClaimed = false,
        enrolledProgram = null,
        programStatus = null;

  final int validatedPassages;
  final int pendingPassages;
  final double cumulativeSpendEuros;

  /// Transient: true only for the duration of the `applyPassageDeltas` call
  /// when the `loyalty_clients` document did not exist before the write.
  /// Used to show the welcome-gift sheet immediately after recording a passage.
  final bool isFirstVisit;

  /// Persistent: true when `first_visit_at` is present in the Firestore doc,
  /// meaning the client's first-visit bonus was already awarded at some point.
  /// Survives app restarts and can be used to show a durable badge in the
  /// Fidélité tab.
  final bool hasFirstVisit;

  /// Persistent: true when `welcome_bon_claimed_at` is present, meaning the
  /// client has already claimed (used) the welcome bon at this merchant.
  /// Once true, the bon must NOT reappear in "Mes avantages".
  final bool welcomeBonClaimed;

  /// Snapshot of the loyalty program at enrollment (grandfathering).
  final LoyaltyProgramConfig? enrolledProgram;

  /// `active` | `merchant_disabled` | `merchant_changed` (Firestore string).
  final String? programStatus;

  bool get hasEnrolledProgram => enrolledProgram != null;

  @override
  List<Object?> get props => <Object?>[
        validatedPassages,
        pendingPassages,
        cumulativeSpendEuros,
        isFirstVisit,
        hasFirstVisit,
        welcomeBonClaimed,
        enrolledProgram,
        programStatus,
      ];
}
