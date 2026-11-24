import '../../merchant/domain/entities/merchant.dart';

/// Legacy free-plan window (kept for CRM / analytics). Découvrir catalogues
/// no longer hide shops after this window — see [isMerchantVisibleInDiscovery].
const int discoveryFreePlanVisibilityDays = 90;

/// Whether [merchant] may appear in Découvrir catalogues (Proche, Associations…).
///
/// **Product (2026-11-24):** Découvrir lists every **active** shop in the
/// client's bassin (`docs/product/DISCOVERY_BASINS.md`). Subscription plan
/// gates other privileges — not geographic discoverability.
///
/// Status filtering (`active`) is applied by callers; this helper always
/// returns true so empty regions mean "no active shop in the bassin".
bool isMerchantVisibleInDiscovery({
  required Merchant merchant,
  DateTime? now,
}) {
  // Always discoverable while active (callers filter status). [merchant] /
  // [now] kept for stable call sites after the P3 product change.
  return merchant.id.isNotEmpty || merchant.id.isEmpty;
}

/// Whether a gratuit plan would have been past the legacy 90-day Découvrir
/// window. Diagnostics / CRM only — not used by Découvrir filters.
bool isLegacyFreeDiscoveryTrialExpired({
  required Merchant merchant,
  required DateTime now,
}) {
  if (merchant.subscriptionPlan.isPaid) return false;
  final created = merchant.createdAt;
  if (created == null) return false;
  final visibleUntil = created.add(
    const Duration(days: discoveryFreePlanVisibilityDays),
  );
  return now.isAfter(visibleUntil);
}

List<Merchant> filterDiscoverySubscriptionVisibility(
  List<Merchant> merchants, {
  DateTime? now,
}) {
  return merchants
      .where(
        (m) => isMerchantVisibleInDiscovery(merchant: m, now: now),
      )
      .toList();
}
