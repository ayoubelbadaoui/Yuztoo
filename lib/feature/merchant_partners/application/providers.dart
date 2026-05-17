import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Searches merchants by name (substring, case-insensitive).
///
/// Fetches up to 200 merchants and filters client-side so that names like
/// "La Boulangerie" are found when the user types "boulangerie". Firestore
/// caches results locally so subsequent calls after the first load are fast.
///
/// [merchantType] post-filters to 'b2b' or 'b2c' when non-null.
Future<List<Map<String, dynamic>>> searchMerchantsProvider(
  String query, {
  String? merchantType,
}) async {
  if (query.trim().isEmpty) return [];
  final qLower = query.trim().toLowerCase();
  final fs = FirebaseFirestore.instance;

  final snap = await fs.collection('merchants').limit(200).get();

  final results = <Map<String, dynamic>>[];
  for (final doc in snap.docs) {
    final data = doc.data();
    final name = (data['name'] as String? ?? '').toLowerCase();
    final display = (data['display_name'] as String? ?? '').toLowerCase();
    if (!name.contains(qLower) && !display.contains(qLower)) continue;
    final rawType = data['merchant_type'] as String?;
    results.add({
      'id': doc.id,
      'name': data['name'] as String? ?? '',
      'city': data['city'] as String? ?? '',
      'logoUrl': data['logo_url'] as String?,
      'merchantType': (rawType == 'b2b' || rawType == 'b2c') ? rawType : 'b2c',
    });
  }

  if (merchantType == null) return results.take(20).toList();
  return results
      .where((m) => m['merchantType'] == merchantType)
      .take(20)
      .toList();
}
