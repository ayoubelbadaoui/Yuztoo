import 'package:equatable/equatable.dart';

/// A partner recommendation added by a merchant.
/// Stored at: `merchants/{merchantId}/partners/{partnerId}`.
class MerchantPartner extends Equatable {
  const MerchantPartner({
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

  @override
  List<Object?> get props => [
        id,
        merchantId,
        partnerMerchantId,
        partnerName,
        partnerLogoUrl,
        partnerCity,
        addedAt,
        isPending,
      ];
}
