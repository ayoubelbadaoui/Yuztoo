import '../../merchant/domain/entities/merchant.dart';
import 'discovery_association_filter.dart';

/// Rules for Découvrir → « Proche de moi » (production product constraints):
///
/// * only **active** (en ligne) merchants
/// * shops / magasins only — **associations** belong in the Associations tab
/// * never merchants the client **already follows** (those live in Mon Carnet)
/// * never the client's **own** store
///
/// [cityMerchants] is expected to already be city-scoped; this function only
/// applies visibility rules so unit tests do not need Firestore.
List<Merchant> filterProcheDeMoiMerchants({
  required List<Merchant> cityMerchants,
  required Set<String> followedMerchantIds,
  String? currentUserId,
}) {
  final followed = followedMerchantIds;
  final selfId = currentUserId?.trim();
  final seen = <String>{};
  final out = <Merchant>[];

  for (final m in cityMerchants) {
    final id = m.id.trim();
    if (id.isEmpty || !seen.add(id)) continue;
    if (m.status != 'active') continue;
    if (isAssociationMerchant(m)) continue;
    if (followed.contains(id)) continue;
    if (selfId != null && selfId.isNotEmpty && id == selfId) continue;
    out.add(m);
  }
  return out;
}
