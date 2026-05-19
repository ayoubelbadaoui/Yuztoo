import '../../merchant/domain/entities/loyalty_program_config.dart';
import '../../merchant/domain/entities/merchant.dart';

/// How E-Fidélité opens when the merchant navigates to the screen.
enum EFideliteInitialMode {
  wizard,
  recap,
}

const int loyaltyWizardLastStepIndex = 6;

/// Wizard vs recap on first paint (after merchant hydration).
EFideliteInitialMode resolveEFideliteInitialMode({
  required Merchant merchant,
  required bool pendingConfiguration,
}) {
  if (pendingConfiguration || !merchant.hasSavedLoyaltyProgram) {
    return EFideliteInitialMode.wizard;
  }
  return EFideliteInitialMode.recap;
}

/// Header / bottom-bar save affordance while configuring the questionnaire.
bool loyaltyWizardSaveEnabled({
  required LoyaltyProgramConfig config,
  required bool hasSavedLoyaltyProgram,
  required bool editingFromRecap,
  required int maxStepVisited,
}) {
  if (!config.programEnabled) return true;
  if (hasSavedLoyaltyProgram && editingFromRecap) return true;
  if (maxStepVisited >= loyaltyWizardLastStepIndex) return true;
  return false;
}
