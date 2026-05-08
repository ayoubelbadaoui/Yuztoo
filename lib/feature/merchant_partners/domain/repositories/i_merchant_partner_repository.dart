import '../entities/merchant_partner.dart';

abstract class IMerchantPartnerRepository {
  Stream<List<MerchantPartner>> getMerchantPartners(String merchantId);

  Future<void> addPartner({
    required String merchantId,
    required String partnerMerchantId,
    required String partnerName,
    String? partnerLogoUrl,
    String? partnerCity,
    String? partnerMerchantType,
  });

  Future<void> removePartner({
    required String merchantId,
    required String partnerId,
  });
}
