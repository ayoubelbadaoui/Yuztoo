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
/// Returns a plain list of maps with keys: id, name, city, logoUrl.
Future<List<Map<String, dynamic>>> searchMerchantsProvider(String query) async {
  if (query.isEmpty) return [];
  final q = query.toLowerCase();
  final snap = await FirebaseFirestore.instance
      .collection('merchants')
      .orderBy('name_lowercase')
      .startAt([q])
      .endAt(['$q\uf8ff'])
      .limit(20)
      .get();
  return snap.docs.map((doc) {
    final data = doc.data();
    return {
      'id': doc.id,
      'name': data['name'] as String? ?? '',
      'city': data['city'] as String? ?? '',
      'logoUrl': data['logo_url'] as String?,
    };
  }).toList();
}
