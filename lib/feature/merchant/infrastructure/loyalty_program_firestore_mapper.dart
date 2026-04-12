import '../domain/entities/loyalty_program_config.dart';

/// Maps [LoyaltyProgramConfig] ↔ Firestore `loyalty_program` map on merchant docs.
///
/// Infrastructure only — keeps Firebase field names out of the domain entity.
class LoyaltyProgramFirestoreMapper {
  const LoyaltyProgramFirestoreMapper._();

  static const String triggerVisitCount = 'visit_count';
  static const String triggerPurchaseTotal = 'purchase_total';

  static const String rewardVoucher = 'purchase_voucher';
  static const String rewardDiscount = 'discount_percent';
  static const String rewardFreeProduct = 'free_product';
  static const String rewardPoints = 'loyalty_points';

  static const String passageAutomatic = 'automatic';
  static const String passageManual = 'manual';

  static LoyaltyProgramConfig? fromFirestoreMap(dynamic raw) {
    if (raw == null || raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    if (map.isEmpty) return null;

    bool b(String k, {bool fallback = false}) {
      final v = map[k];
      if (v is bool) return v;
      return fallback;
    }

    int i(String k, int fallback) {
      final v = map[k];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return fallback;
    }

    double d(String k, double fallback) {
      final v = map[k];
      if (v is num) return v.toDouble();
      return fallback;
    }

    String? s(String k) {
      final v = map[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      return null;
    }

    LoyaltyTriggerType trigger;
    switch (map['trigger_type'] as String?) {
      case triggerPurchaseTotal:
        trigger = LoyaltyTriggerType.purchaseTotal;
        break;
      default:
        trigger = LoyaltyTriggerType.visitCount;
    }

    LoyaltyRewardKind reward;
    switch (map['reward_kind'] as String?) {
      case rewardDiscount:
        reward = LoyaltyRewardKind.discountPercent;
        break;
      case rewardFreeProduct:
        reward = LoyaltyRewardKind.freeProduct;
        break;
      case rewardPoints:
        reward = LoyaltyRewardKind.loyaltyPoints;
        break;
      default:
        reward = LoyaltyRewardKind.purchaseVoucher;
    }

    LoyaltyPassageValidation passage;
    switch (map['passage_validation'] as String?) {
      case passageManual:
        passage = LoyaltyPassageValidation.manual;
        break;
      default:
        passage = LoyaltyPassageValidation.automatic;
    }

    return LoyaltyProgramConfig(
      programEnabled: b('program_enabled', fallback: true),
      triggerType: trigger,
      visitsRequired: i('visits_required', 10).clamp(1, 999),
      cumulativeSpendRequiredEuros: d('cumulative_spend_required_euros', 100).clamp(1, 1e6),
      rewardKind: reward,
      purchaseVoucherUsesPercent: b('purchase_voucher_uses_percent', fallback: true),
      purchaseVoucherValue: d('purchase_voucher_value', 10).clamp(0.5, 1000),
      discountNextPurchasePercent:
          d('discount_next_purchase_percent', 10).clamp(0.5, 100),
      freeProductSummaryLabel: s('free_product_summary_label'),
      pointsPerEuro: d('points_per_euro', 1).clamp(0.1, 1000),
      minimumPerVisitEnabled: b('minimum_per_visit_enabled', fallback: false),
      minimumPerVisitEuros: map['minimum_per_visit_euros'] != null
          ? d('minimum_per_visit_euros', 0).clamp(0, 1e6)
          : null,
      rewardValidityEnabled: b('reward_validity_enabled', fallback: false),
      rewardValidityDays: map['reward_validity_days'] != null
          ? i('reward_validity_days', 30).clamp(1, 3650)
          : null,
      passageValidation: passage,
      optionalAskClientPurchaseAmount:
          b('optional_ask_client_purchase_amount', fallback: false),
    );
  }

  static Map<String, dynamic> toFirestoreMap(LoyaltyProgramConfig c) {
    return <String, dynamic>{
      'program_enabled': c.programEnabled,
      'trigger_type': c.triggerType == LoyaltyTriggerType.purchaseTotal
          ? triggerPurchaseTotal
          : triggerVisitCount,
      'visits_required': c.visitsRequired,
      'cumulative_spend_required_euros': c.cumulativeSpendRequiredEuros,
      'reward_kind': switch (c.rewardKind) {
        LoyaltyRewardKind.purchaseVoucher => rewardVoucher,
        LoyaltyRewardKind.discountPercent => rewardDiscount,
        LoyaltyRewardKind.freeProduct => rewardFreeProduct,
        LoyaltyRewardKind.loyaltyPoints => rewardPoints,
      },
      'purchase_voucher_uses_percent': c.purchaseVoucherUsesPercent,
      'purchase_voucher_value': c.purchaseVoucherValue,
      'discount_next_purchase_percent': c.discountNextPurchasePercent,
      if (c.freeProductSummaryLabel != null &&
          c.freeProductSummaryLabel!.trim().isNotEmpty)
        'free_product_summary_label': c.freeProductSummaryLabel!.trim(),
      'points_per_euro': c.pointsPerEuro,
      'minimum_per_visit_enabled': c.minimumPerVisitEnabled,
      if (c.minimumPerVisitEuros != null)
        'minimum_per_visit_euros': c.minimumPerVisitEuros,
      'reward_validity_enabled': c.rewardValidityEnabled,
      if (c.rewardValidityDays != null) 'reward_validity_days': c.rewardValidityDays,
      'passage_validation': c.passageValidation == LoyaltyPassageValidation.manual
          ? passageManual
          : passageAutomatic,
      'optional_ask_client_purchase_amount': c.optionalAskClientPurchaseAmount,
    };
  }
}
