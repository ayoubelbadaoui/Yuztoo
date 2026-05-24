import '../../merchant/domain/entities/loyalty_program_config.dart';
import '../../merchant/domain/entities/merchant.dart';
import 'entities/active_validation_request.dart';
import 'entities/client_merchant_loyalty_progress.dart';

/// Live merchant loyalty config (Firestore `loyalty_program` or legacy flag).
LoyaltyProgramConfig merchantLiveLoyaltyProgram(Merchant merchant) {
  return merchant.loyaltyProgram ??
      LoyaltyProgramConfig.fallbackFromFlags(
        loyaltyEnabled: merchant.loyaltyEnabled,
      );
}

/// Programme fidélité actif pour ce commerce (switch + `programEnabled`).
bool isMerchantLoyaltyPassageActive(Merchant merchant) {
  if (!merchant.loyaltyEnabled) return false;
  return merchantLiveLoyaltyProgram(merchant).programEnabled;
}

/// BLE + scan automatique : mode [LoyaltyPassageValidation.automatic] uniquement.
bool isBlePassageAllowedForMerchant(Merchant merchant) {
  if (!isMerchantLoyaltyPassageActive(merchant)) return false;
  return merchantLiveLoyaltyProgram(merchant).passageValidation ==
      LoyaltyPassageValidation.automatic;
}

/// Demande vitrine (file « Vos clients ») : mode manuel uniquement.
bool isVitrinePassageRequestAllowedForMerchant(Merchant merchant) {
  if (!isMerchantLoyaltyPassageActive(merchant)) return false;
  return merchantLiveLoyaltyProgram(merchant).passageValidation ==
      LoyaltyPassageValidation.manual;
}

/// Rules applied when recording a passage (sheet + [ConfirmActiveValidation]).
///
/// - Live merchant doc gates whether fidélité is on at all.
/// - Enrolled clients keep their enrollment snapshot (E-Fidélité promise).
/// - Otherwise the session [programSnapshot] (terms at request / BLE connect).
LoyaltyProgramConfig resolveLoyaltyProgramForPassage({
  required Merchant merchant,
  required ActiveValidationRequest session,
  ClientMerchantLoyaltyProgress? clientProgress,
}) {
  final enrolled = clientProgress?.enrolledProgram;
  if (enrolled != null) {
    return enrolled;
  }
  return session.programSnapshot;
}
