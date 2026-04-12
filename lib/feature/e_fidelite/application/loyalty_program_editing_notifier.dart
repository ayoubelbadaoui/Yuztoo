import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../merchant/domain/entities/loyalty_program_config.dart';
import '../../merchant/domain/entities/merchant.dart';

/// Holds the in-memory draft of the merchant loyalty questionnaire.
class LoyaltyProgramEditingNotifier extends StateNotifier<LoyaltyProgramConfig> {
  LoyaltyProgramEditingNotifier() : super(LoyaltyProgramConfig.initial());

  String? _hydrationKey;

  /// Loads server state once per merchant version (avoids wiping local edits).
  void hydrateFromMerchantIfNeeded(Merchant merchant) {
    final key =
        '${merchant.id}_${merchant.updatedAt?.millisecondsSinceEpoch ?? 0}';
    if (_hydrationKey == key) return;
    _hydrationKey = key;
    state = merchant.loyaltyProgram ??
        LoyaltyProgramConfig.fallbackFromFlags(
          loyaltyEnabled: merchant.loyaltyEnabled,
        );
  }

  /// After a successful save, align draft + hydration key with returned [Merchant].
  void applySavedMerchant(Merchant merchant) {
    _hydrationKey =
        '${merchant.id}_${merchant.updatedAt?.millisecondsSinceEpoch ?? 0}';
    state = merchant.loyaltyProgram ??
        LoyaltyProgramConfig.fallbackFromFlags(
          loyaltyEnabled: merchant.loyaltyEnabled,
        );
  }

  void setProgramEnabled(bool value) {
    state = state.copyWith(programEnabled: value);
  }

  void setTriggerType(LoyaltyTriggerType value) {
    state = state.copyWith(triggerType: value);
  }

  void setVisitsRequired(int value) {
    state = state.copyWith(visitsRequired: value.clamp(1, 999));
  }

  void setCumulativeSpendRequiredEuros(double value) {
    state = state.copyWith(
      cumulativeSpendRequiredEuros: value.clamp(1, 1e6),
    );
  }

  void setRewardKind(LoyaltyRewardKind value) {
    state = state.copyWith(rewardKind: value);
  }

  void setPurchaseVoucherUsesPercent(bool value) {
    state = state.copyWith(purchaseVoucherUsesPercent: value);
  }

  void setPurchaseVoucherValue(double value) {
    state = state.copyWith(purchaseVoucherValue: value.clamp(0.5, 1000));
  }

  void setDiscountNextPurchasePercent(double value) {
    state = state.copyWith(discountNextPurchasePercent: value.clamp(0.5, 100));
  }

  void setFreeProductSummaryLabel(String value) {
    final t = value.trim();
    if (t.isEmpty) {
      state = state.copyWith(clearFreeProductSummaryLabel: true);
    } else {
      state = state.copyWith(freeProductSummaryLabel: t);
    }
  }

  void setPointsPerEuro(double value) {
    state = state.copyWith(pointsPerEuro: value.clamp(0.1, 1000));
  }

  void setMinimumPerVisitEnabled(bool value) {
    state = state.copyWith(minimumPerVisitEnabled: value);
  }

  void setMinimumPerVisitEuros(double? value) {
    state = state.copyWith(minimumPerVisitEuros: value);
  }

  void setRewardValidityEnabled(bool value) {
    state = state.copyWith(rewardValidityEnabled: value);
  }

  void setRewardValidityDays(int? value) {
    state = state.copyWith(rewardValidityDays: value);
  }

  void setPassageValidation(LoyaltyPassageValidation value) {
    state = state.copyWith(passageValidation: value);
  }

  void setOptionalAskClientPurchaseAmount(bool value) {
    state = state.copyWith(optionalAskClientPurchaseAmount: value);
  }

  void reset() {
    _hydrationKey = null;
    state = LoyaltyProgramConfig.initial();
  }
}
