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
  }) {
    final dto = MerchantPartnerDto(
      id: '',
      merchantId: merchantId,
      partnerMerchantId: partnerMerchantId,
      partnerName: partnerName,
      partnerLogoUrl: partnerLogoUrl,
      partnerCity: partnerCity,
      addedAt: DateTime.now(),
      isPending: true,
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
