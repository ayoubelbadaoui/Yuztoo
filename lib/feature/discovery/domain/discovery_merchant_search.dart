import '../../../core/utils/text_search.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../../merchant_onboarding/presentation/widgets/merchant_category_catalog.dart';
import '../../merchant_onboarding/presentation/widgets/subcategory/merchant_subcategory_catalog.dart';

List<String> _nonEmptyLabels(Iterable<String?> values) => [
      for (final value in values)
        if (value != null && value.trim().isNotEmpty) value.trim(),
    ];

/// Searchable labels for a [Merchant] (name, type, onboarding catalogue).
List<String> discoverySearchLabelsFor(Merchant merchant) {
  final categoryId = merchant.categoryId?.trim();
  return _nonEmptyLabels([
    merchant.displayName,
    merchant.name,
    merchant.subcategoryTitle,
    merchant.displayCategory,
    if (categoryId != null && categoryId.isNotEmpty) ...[
      categoryId.replaceAll('_', ' '),
      MerchantCategoryCatalog.byId(categoryId)?.title,
      MerchantSubcategoryCatalog.titleForId(categoryId),
    ],
    ...?merchant.categories,
  ]);
}

/// Same label expansion for raw Firestore merchant maps (partner invite search).
List<String> discoverySearchLabelsFromFirestore(Map<String, dynamic> data) {
  final categoryId = (data['category_id'] as String?)?.trim();
  final categories = data['categories'];
  return _nonEmptyLabels([
    data['display_name'] as String?,
    data['name'] as String?,
    data['subcategory_title'] as String?,
    if (categoryId != null && categoryId.isNotEmpty) ...[
      categoryId.replaceAll('_', ' '),
      MerchantCategoryCatalog.byId(categoryId)?.title,
      MerchantSubcategoryCatalog.titleForId(categoryId),
    ],
    if (categories is List)
      for (final c in categories)
        if (c is String) c,
  ]);
}

double _labelSearchScore(
  String query,
  String label, {
  required bool allowSubstring,
}) {
  final score = fuzzyMatchScore(query: query, candidate: label);
  if (!allowSubstring && score == 3) return 0;
  return score;
}

double _discoveryMerchantSearchScore(Merchant merchant, String query) {
  final normalized = normalizeForSearch(query);
  if (normalized.length < 2) return 0;

  final nameLabels = _nonEmptyLabels([merchant.displayName, merchant.name]);
  final categoryLabels = discoverySearchLabelsFor(merchant)
      .where((label) => !nameLabels.contains(label))
      .toList();

  var nameBest = 0.0;
  for (final label in nameLabels) {
    final score = _labelSearchScore(
      query,
      label,
      allowSubstring: normalized.length >= 4,
    );
    if (score > nameBest) nameBest = score;
  }

  // 2-letter queries: commerce name only (e.g. « ca » → CADENCE, not Commerce).
  if (normalized.length < 3) {
    return nameBest >= 2 ? nameBest : 0;
  }

  var categoryBest = 0.0;
  for (final label in categoryLabels) {
    final score = _labelSearchScore(
      query,
      label,
      allowSubstring: normalized.length >= 4,
    );
    if (score > categoryBest) categoryBest = score;
  }

  final best = nameBest > categoryBest ? nameBest : categoryBest;
  return best >= 2 ? best : 0;
}

/// Filters [merchants] whose name **or** category/type matches [query]
/// (e.g. « Café » → « Café & Bar », `bouche_cafe`, commerces nommés Café…).
List<Merchant> filterDiscoverySearchMerchants({
  required List<Merchant> merchants,
  required String query,
}) {
  final q = query.trim();
  if (normalizeForSearch(q).length < 2) return const [];

  final scored = <({Merchant merchant, double score})>[];
  for (final merchant in merchants) {
    final score = _discoveryMerchantSearchScore(merchant, q);
    if (score <= 0) continue;
    scored.add((merchant: merchant, score: score));
  }

  scored.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    return (a.merchant.displayName ?? a.merchant.name)
        .toLowerCase()
        .compareTo((b.merchant.displayName ?? b.merchant.name).toLowerCase());
  });

  return scored.map((e) => e.merchant).toList();
}

Map<String, dynamic> discoverySearchResultRow(Merchant merchant) => {
      'id': merchant.id,
      'name': merchant.displayName ?? merchant.name,
      'city': merchant.city,
      'logoUrl': merchant.logoUrl,
      'merchantType': merchant.merchantType,
      'category': merchant.displayCategory ?? '',
    };
