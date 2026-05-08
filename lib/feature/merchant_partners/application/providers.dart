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

/// Searches merchants by name prefix (case-insensitive start-of-string match).
/// Returns a plain list of maps with keys:
///   id, name, city, logoUrl, merchantType ('b2b'|'b2c'|null).
///
/// When [merchantType] is non-null, the result set is post-filtered so
/// only matching businesses come back. Done client-side rather than via
/// a Firestore composite index so the existing name-prefix index keeps
/// covering the search; we already cap the query at 40 docs (`limit`)
/// so the cost is trivial. Pre-filter docs with no `merchant_type` are
/// considered B2C by default (the merchantType default in the entity).
Future<List<Map<String, dynamic>>> searchMerchantsProvider(
  String query, {
  String? merchantType,
}) async {
  if (query.isEmpty) return [];
  final q = query.toLowerCase();
  final snap = await FirebaseFirestore.instance
      .collection('merchants')
      .orderBy('name_lowercase')
      .startAt([q])
      .endAt(['$q\uf8ff'])
      // Read more than 20 so a 100% B2C-only filter still has results
      // even when a few B2B entries lead the prefix range.
      .limit(40)
      .get();
  final results = snap.docs.map((doc) {
    final data = doc.data();
    final rawType = data['merchant_type'] as String?;
    final type = (rawType == 'b2b' || rawType == 'b2c') ? rawType : 'b2c';
    return {
      'id': doc.id,
      'name': data['name'] as String? ?? '',
      'city': data['city'] as String? ?? '',
      'logoUrl': data['logo_url'] as String?,
      'merchantType': type,
    };
  });
  if (merchantType == null) {
    return results.take(20).toList();
  }
  return results
      .where((m) => m['merchantType'] == merchantType)
      .take(20)
      .toList();
}
