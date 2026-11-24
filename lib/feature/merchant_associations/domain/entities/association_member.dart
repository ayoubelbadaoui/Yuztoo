import 'package:equatable/equatable.dart';

import 'merchant_association.dart';

/// Where a merchant stands in an association.
enum AssociationMemberStatus {
  /// Join request sent, waiting for the founder.
  pending,

  /// Approved by the founder — visible to clients on the group page.
  approved;

  String get firestoreValue => switch (this) {
        AssociationMemberStatus.pending => 'pending',
        AssociationMemberStatus.approved => 'approved',
      };

  static AssociationMemberStatus fromFirestore(String? raw) =>
      raw?.trim().toLowerCase() == 'approved'
          ? AssociationMemberStatus.approved
          : AssociationMemberStatus.pending;
}

/// One merchant's membership in an association.
///
/// Stored at `merchant_associations/{associationId}/association_members/{merchantId}`
/// — the merchant id is the document id, so a merchant cannot queue two
/// requests for the same association.
class AssociationMember extends Equatable {
  const AssociationMember({
    required this.merchantId,
    required this.associationId,
    required this.merchantName,
    required this.status,
    this.merchantLogoUrl,
    this.merchantCity,
    this.requestedAt,
    this.approvedAt,
  });

  final String merchantId;
  final String associationId;

  /// Snapshot of the shop name so the group page renders without N reads.
  final String merchantName;
  final String? merchantLogoUrl;
  final String? merchantCity;

  final AssociationMemberStatus status;
  final DateTime? requestedAt;
  final DateTime? approvedAt;

  bool get isApproved => status == AssociationMemberStatus.approved;
  bool get isPending => status == AssociationMemberStatus.pending;

  @override
  List<Object?> get props => [
        merchantId,
        associationId,
        merchantName,
        merchantLogoUrl,
        merchantCity,
        status,
        requestedAt,
        approvedAt,
      ];
}

/// An association plus the viewing merchant's membership in it.
class MerchantAssociationMembership extends Equatable {
  const MerchantAssociationMembership({
    required this.association,
    required this.member,
  });

  final MerchantAssociation association;
  final AssociationMember member;

  @override
  List<Object?> get props => [association, member];
}
