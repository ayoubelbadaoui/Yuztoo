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
    this.partnerMerchantType,
    this.isPending = false,
  });

  final String id;
  final String merchantId;
  final String partnerMerchantId;
  final String partnerName;
  final String? partnerLogoUrl;
  final String? partnerCity;

  /// Snapshot of the partner merchant's `merchant_type` ('b2b' or 'b2c')
  /// captured at invite time. Stored on the partner doc so the
  /// recommandations screen can filter without re-querying the
  /// underlying merchant doc on every render. Null for entries created
  /// before this field existed — those fall under the "Tous" filter
  /// only and are re-typed the next time the merchant is opened.
  final String? partnerMerchantType;

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
        partnerMerchantType,
        addedAt,
        isPending,
      ];
}
