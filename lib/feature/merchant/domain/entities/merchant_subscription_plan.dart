/// Merchant billing tier on Yuztoo (Découvrir visibility + future admin gates).
enum MerchantSubscriptionPlan {
  /// Plan gratuit — visible in Découvrir for [discoveryFreePlanVisibilityDays].
  gratuit,

  /// Paid Essentiel — unlimited Découvrir visibility.
  essentiel,

  /// Paid Premium — unlimited Découvrir visibility.
  premium;

  bool get isPaid => this != MerchantSubscriptionPlan.gratuit;

  static MerchantSubscriptionPlan fromFirestore(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'essentiel':
        return MerchantSubscriptionPlan.essentiel;
      case 'premium':
        return MerchantSubscriptionPlan.premium;
      default:
        return MerchantSubscriptionPlan.gratuit;
    }
  }

  String get firestoreValue => switch (this) {
        MerchantSubscriptionPlan.gratuit => 'gratuit',
        MerchantSubscriptionPlan.essentiel => 'essentiel',
        MerchantSubscriptionPlan.premium => 'premium',
      };
}
