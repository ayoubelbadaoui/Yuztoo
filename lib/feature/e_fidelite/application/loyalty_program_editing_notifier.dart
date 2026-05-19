import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../merchant/domain/entities/loyalty_program_config.dart';
import '../../merchant/domain/entities/merchant.dart';

/// Holds the in-memory draft of the merchant loyalty questionnaire.
class LoyaltyProgramEditingNotifier extends StateNotifier<LoyaltyProgramConfig> {
  LoyaltyProgramEditingNotifier() : super(LoyaltyProgramConfig.initial());

  String? _hydrationKey;

  /// When set, [hydrateFromMerchantIfNeeded] keeps the current draft (e.g. new
  /// programme wizard) until save, abandon, or the merchant doc epoch changes.
  String? _pauseHydrationForMerchantEpochKey;

  static String _merchantEpochKey(Merchant merchant) =>
      '${merchant.id}_${merchant.updatedAt?.millisecondsSinceEpoch ?? 0}';

  /// Loads server state once per merchant version (avoids wiping local edits).
  void hydrateFromMerchantIfNeeded(Merchant merchant) {
    final key = _merchantEpochKey(merchant);
    if (_pauseHydrationForMerchantEpochKey != null) {
      if (_pauseHydrationForMerchantEpochKey == key) {
        return;
      }
      // Remote or concurrent update changed the doc — drop pause and sync.
      _pauseHydrationForMerchantEpochKey = null;
    }
    if (_hydrationKey == key) return;
    _hydrationKey = key;
    state = merchant.loyaltyProgram ??
        LoyaltyProgramConfig.fallbackFromFlags(
          loyaltyEnabled: merchant.loyaltyEnabled,
        );
  }

  /// After a successful save, align draft + hydration key with returned [Merchant].
  void applySavedMerchant(Merchant merchant) {
    _pauseHydrationForMerchantEpochKey = null;
    _hydrationKey = _merchantEpochKey(merchant);
    state = merchant.loyaltyProgram ??
        LoyaltyProgramConfig.fallbackFromFlags(
          loyaltyEnabled: merchant.loyaltyEnabled,
        );
  }

  /// Fresh questionnaire while the saved programme stays disabled on the server
  /// until the merchant saves a new configuration.
  void beginFreshProgramDraft(Merchant merchant) {
    _pauseHydrationForMerchantEpochKey = _merchantEpochKey(merchant);
    _hydrationKey = null;
    state = LoyaltyProgramConfig.initial().copyWith(programEnabled: true);
  }

  /// Abandon in-memory draft and reload from [merchant] (same Firestore epoch).
  void resumeHydrationIfPaused(Merchant? merchant) {
    if (merchant == null || _pauseHydrationForMerchantEpochKey == null) return;
    final key = _merchantEpochKey(merchant);
    if (_pauseHydrationForMerchantEpochKey != key) return;
    _pauseHydrationForMerchantEpochKey = null;
    _hydrationKey = null;
    hydrateFromMerchantIfNeeded(merchant);
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
    _pauseHydrationForMerchantEpochKey = null;
    _hydrationKey = null;
    state = LoyaltyProgramConfig.initial();
  }
}
