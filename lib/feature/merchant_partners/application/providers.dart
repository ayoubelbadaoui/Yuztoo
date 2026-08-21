import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/text_search.dart';
import '../domain/entities/merchant_partner.dart';
import '../domain/repositories/i_merchant_partner_repository.dart';
import '../infrastructure/merchant_partner_repository_impl.dart';

final merchantPartnerRepositoryProvider =
    Provider<IMerchantPartnerRepository>((ref) {
  return FirestoreMerchantPartnerRepository(FirebaseFirestore.instance);
});

/// Live stream of partners for [merchantId].
final merchantPartnersProvider =
    StreamProvider.autoDispose.family<List<MerchantPartner>, String>(
  (ref, merchantId) {
    if (merchantId.isEmpty) return Stream.value([]);
    final repo = ref.watch(merchantPartnerRepositoryProvider);
    return repo.getMerchantPartners(merchantId);
  },
);

/// Searches merchants by name **and** commerce type/category — approximate,
/// diacritics-insensitive.
///
/// Matches `name`, `display_name`, `category_id`, `subcategory_title`, and
/// `categories[]` so « boulangerie » finds shops typed as such even when the
/// brand name does not contain the word.
Future<List<Map<String, dynamic>>> searchMerchantsProvider(
  String query, {
  String? merchantType,
}) async {
  if (normalizeForSearch(query).isEmpty) return [];
  final fs = FirebaseFirestore.instance;

  final snap = await fs.collection('merchants').limit(200).get();

  final scored = <({Map<String, dynamic> row, double score})>[];
  for (final doc in snap.docs) {
    final data = doc.data();
    final name = data['name'] as String? ?? '';
    final display = data['display_name'] as String? ?? '';
    final subcategory = data['subcategory_title'] as String? ?? '';
    final categoryId = data['category_id'] as String? ?? '';
    final categories = (data['categories'] as List?)
            ?.whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];

    final nameScore = fuzzyMatchScore(query: query, candidate: name);
    final displayScore = display.isEmpty
        ? 0.0
        : fuzzyMatchScore(query: query, candidate: display);
    final subScore = subcategory.isEmpty
        ? 0.0
        : fuzzyMatchScore(query: query, candidate: subcategory);
    final categoryIdScore = categoryId.isEmpty
        ? 0.0
        : fuzzyMatchScore(query: query, candidate: categoryId.replaceAll('_', ' '));
    var categoriesScore = 0.0;
    for (final c in categories) {
      final s = fuzzyMatchScore(query: query, candidate: c);
      if (s > categoriesScore) categoriesScore = s;
    }

    final score = [
      nameScore,
      displayScore,
      subScore,
      categoryIdScore,
      categoriesScore,
    ].reduce((a, b) => a > b ? a : b);
    if (score <= 0) continue;
    final rawType = data['merchant_type'] as String?;
    scored.add((
      row: {
        'id': doc.id,
        'name': name,
        'city': data['city'] as String? ?? '',
        'logoUrl': data['logo_url'] as String?,
        'merchantType':
            (rawType == 'b2b' || rawType == 'b2c') ? rawType : 'b2c',
        'category': subcategory.isNotEmpty
            ? subcategory
            : (categories.isNotEmpty ? categories.first : categoryId),
      },
      score: score,
    ));
  }

  scored.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    return (a.row['name'] as String)
        .toLowerCase()
        .compareTo((b.row['name'] as String).toLowerCase());
  });

  final results = scored.map((e) => e.row);
  if (merchantType == null) return results.take(20).toList();
  return results
      .where((m) => m['merchantType'] == merchantType)
      .take(20)
      .toList();
}
