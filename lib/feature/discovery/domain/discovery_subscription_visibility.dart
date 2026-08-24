import '../../merchant/domain/entities/merchant.dart';

/// Free merchants remain discoverable for three months after creation.
const int discoveryFreePlanVisibilityDays = 90;

/// Whether [merchant] may appear in Découvrir catalogues (Proche, Associations…).
///
/// * **Paid** (`essentiel` / `premium`): always visible while `active`.
/// * **Gratuit**: visible until [discoveryFreePlanVisibilityDays] after
///   [Merchant.createdAt]. Legacy docs without `created_at` stay visible.
bool isMerchantVisibleInDiscovery({
  required Merchant merchant,
  required DateTime now,
}) {
  if (merchant.subscriptionPlan.isPaid) return true;
  final created = merchant.createdAt;
  if (created == null) return true;
  final visibleUntil = created.add(
    const Duration(days: discoveryFreePlanVisibilityDays),
  );
  return !now.isAfter(visibleUntil);
}

List<Merchant> filterDiscoverySubscriptionVisibility(
  List<Merchant> merchants, {
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  return merchants
      .where(
        (m) => isMerchantVisibleInDiscovery(merchant: m, now: clock),
      )
      .toList();
}
