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

/// Searches merchants by name — approximate, diacritics-insensitive.
///
/// Fetches up to 200 merchants and matches client-side with
/// [fuzzyMatchScore] so « cafe » finds « Café », « boul » finds
/// « La Boulangerie » and one-letter typos still match (« il faut que nous
/// puissions avoir une recherche approximative »). Results are ranked by
/// relevance (prefix > substring > approximate), ties broken by name.
/// Firestore caches results locally so calls after the first load are fast.
///
/// [merchantType] post-filters to 'b2b' or 'b2c' when non-null.
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
    final nameScore = fuzzyMatchScore(query: query, candidate: name);
    final displayScore = display.isEmpty
        ? 0.0
        : fuzzyMatchScore(query: query, candidate: display);
    final score = nameScore > displayScore ? nameScore : displayScore;
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
