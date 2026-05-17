import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/merchant_partner.dart';
import '../domain/repositories/i_merchant_partner_repository.dart';
import 'dto/merchant_partner_dto.dart';

class FirestoreMerchantPartnerRepository implements IMerchantPartnerRepository {
  FirestoreMerchantPartnerRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String merchantId) =>
      _firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('partners');

  @override
  Stream<List<MerchantPartner>> getMerchantPartners(String merchantId) {
    if (merchantId.isEmpty) return Stream.value([]);
    return _col(merchantId)
        .orderBy('added_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MerchantPartnerDto.fromFirestore(doc, merchantId)
                ?.toDomain())
            .whereType<MerchantPartner>()
            .toList());
  }

  @override
  Future<void> addPartner({
    required String merchantId,
    required String partnerMerchantId,
    required String partnerName,
    String? partnerLogoUrl,
    String? partnerCity,
    String? partnerMerchantType,
  }) {
    // Defensive: only persist a value the schema knows about. Anything
    // exotic gets dropped here so a typo at the call site never reaches
    // Firestore.
    final cleanType =
        (partnerMerchantType == 'b2b' || partnerMerchantType == 'b2c')
            ? partnerMerchantType
            : null;
    final dto = MerchantPartnerDto(
      id: '',
      merchantId: merchantId,
      partnerMerchantId: partnerMerchantId,
      partnerName: partnerName,
      partnerLogoUrl: partnerLogoUrl,
      partnerCity: partnerCity,
      partnerMerchantType: cleanType,
      addedAt: DateTime.now(),
      isPending: false,
    );
    return _col(merchantId).add(dto.toFirestore());
  }

  @override
  Future<void> removePartner({
    required String merchantId,
    required String partnerId,
  }) =>
      _col(merchantId).doc(partnerId).delete();
}
