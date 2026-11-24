import 'package:equatable/equatable.dart';

/// A merchant-run association ("association de commerçants").
///
/// Stored at `merchant_associations/{associationId}`. Any merchant can
/// create one; other merchants ask to join and the founder approves.
class MerchantAssociation extends Equatable {
  const MerchantAssociation({
    required this.id,
    required this.name,
    required this.founderMerchantId,
    this.city = '',
    this.description,
    this.memberCount = 0,
    this.createdAt,
  });

  final String id;
  final String name;

  /// Merchant who created the association and approves join requests.
  final String founderMerchantId;

  /// Free-text city, used to help merchants find a local association.
  final String city;

  final String? description;

  /// Approved members only (maintained on write, read-only for the UI).
  final int memberCount;

  final DateTime? createdAt;

  bool isFoundedBy(String merchantId) =>
      merchantId.isNotEmpty && merchantId == founderMerchantId;

  MerchantAssociation copyWith({
    String? id,
    String? name,
    String? founderMerchantId,
    String? city,
    String? description,
    int? memberCount,
    DateTime? createdAt,
  }) {
    return MerchantAssociation(
      id: id ?? this.id,
      name: name ?? this.name,
      founderMerchantId: founderMerchantId ?? this.founderMerchantId,
      city: city ?? this.city,
      description: description ?? this.description,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        founderMerchantId,
        city,
        description,
        memberCount,
        createdAt,
      ];
}
