/// Types of merchant-facing alerts on the Rappels page.
enum RappelAlertType {
  /// One or more active promotions expire within 3 days.
  promoExpiring,

  /// Clients have loyalty passages waiting for merchant validation.
  loyaltyPendingValidation,

  /// Clients are eligible for their loyalty reward right now.
  loyaltyRewardReady,
}

/// A single alert surfaced on the Rappels screen.
class RappelAlert {
  const RappelAlert({
    required this.type,
    required this.count,
    this.detail,
  });

  final RappelAlertType type;

  /// Number of affected items (promos, clients, etc.).
  final int count;

  /// Optional human-readable detail (e.g., promo title or days remaining).
  final String? detail;
}
