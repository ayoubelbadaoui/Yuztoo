import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/merchant_partner.dart';

class MerchantPartnerDto {
  const MerchantPartnerDto({
    required this.id,
    required this.merchantId,
    required this.partnerMerchantId,
    required this.partnerName,
    required this.addedAt,
    this.partnerLogoUrl,
    this.partnerCity,
    this.isPending = false,
  });

  final String id;
  final String merchantId;
  final String partnerMerchantId;
  final String partnerName;
  final String? partnerLogoUrl;
  final String? partnerCity;
  final DateTime addedAt;
  final bool isPending;

  static MerchantPartnerDto? fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String merchantId,
  ) {
    final data = doc.data();
    if (data == null) return null;
    final addedAtRaw = data['added_at'];
    final addedAt = addedAtRaw is Timestamp
        ? addedAtRaw.toDate()
        : DateTime.now();
    return MerchantPartnerDto(
      id: doc.id,
      merchantId: merchantId,
      partnerMerchantId: data['partner_merchant_id'] as String? ?? '',
      partnerName: data['partner_name'] as String? ?? '',
      partnerLogoUrl: data['partner_logo_url'] as String?,
      partnerCity: data['partner_city'] as String?,
      addedAt: addedAt,
      isPending: data['is_pending'] as bool? ?? false,
    );
  }

  MerchantPartner toDomain() => MerchantPartner(
        id: id,
        merchantId: merchantId,
        partnerMerchantId: partnerMerchantId,
        partnerName: partnerName,
        partnerLogoUrl: partnerLogoUrl,
        partnerCity: partnerCity,
        addedAt: addedAt,
        isPending: isPending,
      );

  Map<String, dynamic> toFirestore() => {
        'partner_merchant_id': partnerMerchantId,
        'partner_name': partnerName,
        if (partnerLogoUrl != null) 'partner_logo_url': partnerLogoUrl,
        if (partnerCity != null) 'partner_city': partnerCity,
        'added_at': Timestamp.fromDate(addedAt),
        'is_pending': isPending,
      };
}
