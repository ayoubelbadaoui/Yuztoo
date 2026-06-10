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

/// Mode automatique : un scan (NFC, QR, deep-link) ou une connexion BLE
/// déclenche un passage validé sans confirmation côté commerçant.
///
/// Renommé depuis `isBlePassageAllowedForMerchant` parce que le BLE n'est
/// qu'un des transports possibles — le NFC est désormais la voie principale
/// (cf. NFC MVP). La sémantique de la règle (`passageValidation == automatic`)
/// est inchangée : seul le nom suit la nouvelle réalité produit.
bool isAutomaticPassageAllowedForMerchant(Merchant merchant) {
  if (!isMerchantLoyaltyPassageActive(merchant)) return false;
  return merchantLiveLoyaltyProgram(merchant).passageValidation ==
      LoyaltyPassageValidation.automatic;
}

/// Alias historique. Conservé le temps que les écrans BLE existants migrent
/// vers [isAutomaticPassageAllowedForMerchant]. Ne rien y ajouter.
@Deprecated('Use isAutomaticPassageAllowedForMerchant')
bool isBlePassageAllowedForMerchant(Merchant merchant) =>
    isAutomaticPassageAllowedForMerchant(merchant);

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
