import '../../merchant/domain/entities/merchant.dart';
import '../../promotions/domain/entities/promotion.dart';

/// One enseigne / magasin block in the client promotions list.
class PromotionEnseigneGroup {
  const PromotionEnseigneGroup({
    required this.key,
    required this.title,
    required this.primaryMerchantId,
    required this.merchantIds,
    required this.promotions,
    this.subtitle,
    this.logoUrl,
  });

  /// `organizationId` when set, otherwise `merchantId`.
  final String key;

  /// Public enseigne name (`displayName` then `name`).
  final String title;

  /// Optional store label or human promo count.
  final String? subtitle;

  /// Merchant opened when the header is tapped.
  final String primaryMerchantId;

  final List<String> merchantIds;
  final List<Promotion> promotions;
  final String? logoUrl;

  int get promoCount => promotions.length;
}

String enseigneGroupKeyForMerchant(Merchant? merchant, String merchantId) {
  final org = merchant?.organizationId?.trim() ?? '';
  if (org.isNotEmpty) return 'org:$org';
  return 'm:${merchantId.trim()}';
}

String enseigneTitleForMerchant(Merchant? merchant, String merchantId) {
  if (merchant != null) {
    final display = merchant.displayName?.trim() ?? '';
    if (display.isNotEmpty) return display;
    final name = merchant.name.trim();
    if (name.isNotEmpty) return name;
  }
  return merchantId.trim().isEmpty ? 'Commerce' : merchantId.trim();
}

/// Groups [promotions] under enseigne keys.
///
/// * Same `organizationId` → one group (multi-PDV enseigne).
/// * Otherwise one group per `merchantId`.
/// * Groups ordered by newest `dateTo` among their promos.
/// * Promos inside a group keep [promotions] relative order (caller sorts).
List<PromotionEnseigneGroup> groupPromotionsByEnseigne({
  required List<Promotion> promotions,
  required Map<String, Merchant> merchantsById,
}) {
  if (promotions.isEmpty) return const [];

  final order = <String>[];
  final buckets = <String, List<Promotion>>{};
  final merchantIdsByKey = <String, Set<String>>{};

  for (final promo in promotions) {
    final mid = promo.merchantId.trim();
    if (mid.isEmpty) continue;
    final merchant = merchantsById[mid];
    final key = enseigneGroupKeyForMerchant(merchant, mid);
    if (!buckets.containsKey(key)) {
      order.add(key);
      buckets[key] = <Promotion>[];
      merchantIdsByKey[key] = <String>{};
    }
    buckets[key]!.add(promo);
    merchantIdsByKey[key]!.add(mid);
  }

  final groups = <PromotionEnseigneGroup>[];
  for (final key in order) {
    final promos = buckets[key]!;
    final ids = merchantIdsByKey[key]!.toList(growable: false);
    final primaryId = ids.first;
    final primary = merchantsById[primaryId];
    final storeLabel = primary?.storeLabel?.trim();
    final countLabel =
        '${promos.length} promotion${promos.length > 1 ? 's' : ''}';
    final subtitle = (storeLabel != null && storeLabel.isNotEmpty)
        ? '$storeLabel · $countLabel'
        : countLabel;

    groups.add(
      PromotionEnseigneGroup(
        key: key,
        title: enseigneTitleForMerchant(primary, primaryId),
        subtitle: subtitle,
        primaryMerchantId: primaryId,
        merchantIds: ids,
        promotions: List<Promotion>.unmodifiable(promos),
        logoUrl: primary?.logoUrl,
      ),
    );
  }

  groups.sort((a, b) {
    final aMax = a.promotions.map((p) => p.dateTo).reduce(
          (x, y) => x.isAfter(y) ? x : y,
        );
    final bMax = b.promotions.map((p) => p.dateTo).reduce(
          (x, y) => x.isAfter(y) ? x : y,
        );
    return bMax.compareTo(aMax);
  });

  return groups;
}

/// Keeps groups/promos that match [query] against enseigne name, category,
/// or promo title/subtitle. Empty query returns [groups] unchanged.
List<PromotionEnseigneGroup> filterPromotionEnseigneGroups({
  required List<PromotionEnseigneGroup> groups,
  required Map<String, Merchant> merchantsById,
  required String query,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return groups;

  final out = <PromotionEnseigneGroup>[];
  for (final group in groups) {
    final titleHit = group.title.toLowerCase().contains(q);
    final subtitleHit = (group.subtitle ?? '').toLowerCase().contains(q);

    var categoryHit = false;
    for (final mid in group.merchantIds) {
      final m = merchantsById[mid];
      if (m == null) continue;
      final hay = <String>[
        if (m.displayCategory != null) m.displayCategory!,
        if (m.subcategoryTitle != null) m.subcategoryTitle!,
        ...?m.categories,
        if (m.categoryId != null) m.categoryId!,
        if (m.storeLabel != null) m.storeLabel!,
        m.name,
        if (m.displayName != null) m.displayName!,
      ].join(' ').toLowerCase();
      if (hay.contains(q)) {
        categoryHit = true;
        break;
      }
    }

    if (titleHit || subtitleHit || categoryHit) {
      out.add(group);
      continue;
    }

    final matchingPromos = group.promotions
        .where(
          (p) =>
              p.title.toLowerCase().contains(q) ||
              p.subtitle.toLowerCase().contains(q),
        )
        .toList(growable: false);
    if (matchingPromos.isEmpty) continue;

    out.add(
      PromotionEnseigneGroup(
        key: group.key,
        title: group.title,
        subtitle: group.subtitle,
        primaryMerchantId: group.primaryMerchantId,
        merchantIds: group.merchantIds,
        promotions: matchingPromos,
        logoUrl: group.logoUrl,
      ),
    );
  }
  return out;
}
