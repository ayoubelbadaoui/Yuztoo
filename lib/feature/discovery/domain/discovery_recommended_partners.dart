import 'package:cloud_firestore/cloud_firestore.dart';

import '../../merchant/domain/entities/merchant.dart';

/// Partner row on `merchants/{id}/partners/{partnerDocId}`.
class DiscoveryPartnerSnapshot {
  const DiscoveryPartnerSnapshot({
    required this.partnerMerchantId,
    this.partnerName = '',
    this.partnerLogoUrl,
    this.partnerCity,
  });

  final String partnerMerchantId;
  final String partnerName;
  final String? partnerLogoUrl;
  final String? partnerCity;
}

/// Reads [partner_merchant_id] from Firestore (string or document reference).
String? partnerMerchantIdFromFirestore(Map<String, dynamic> data) {
  final raw = data['partner_merchant_id'];
  if (raw is String) {
    final trimmed = raw.trim();
    if (trimmed.isNotEmpty) return trimmed;
  }
  if (raw is DocumentReference) return raw.id;
  return null;
}

/// Whether a partner business should appear in Découvrir → Recommandés.
bool shouldIncludeInDiscoveryRecommendations({
  required String partnerMerchantId,
  required String currentUserId,
  required Set<String> followedMerchantIds,
  required Set<String> blockedMerchantIds,
}) {
  if (partnerMerchantId.isEmpty) return false;
  if (partnerMerchantId == currentUserId) return false;
  if (followedMerchantIds.contains(partnerMerchantId)) return false;
  if (blockedMerchantIds.contains(partnerMerchantId)) return false;
  return true;
}

/// Builds a minimal [Merchant] from vitrine partner snapshot fields when the
/// full merchant doc cannot be loaded (e.g. permissions edge case).
Merchant merchantFromPartnerSnapshot(DiscoveryPartnerSnapshot snap) {
  return Merchant(
    id: snap.partnerMerchantId,
    ownerUid: snap.partnerMerchantId,
    name: snap.partnerName,
    email: '',
    phone: '',
    city: snap.partnerCity ?? '',
    logoUrl: snap.partnerLogoUrl,
    status: 'active',
  );
}
