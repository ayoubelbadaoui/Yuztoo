import '../entities/association_member.dart';
import '../entities/merchant_association.dart';

/// Merchant associations: create one, ask to join an existing one, and
/// approve or remove members as the founder.
abstract class IMerchantAssociationRepository {
  /// Creates an association founded by [founderMerchantId]; the founder is
  /// stored as an already-approved member. Returns the created association.
  Future<MerchantAssociation> createAssociation({
    required String founderMerchantId,
    required String founderName,
    required String name,
    String city,
    String? description,
    String? founderLogoUrl,
  });

  /// Associations whose name matches [query] (diacritics-insensitive).
  Future<List<MerchantAssociation>> searchAssociations(String query);

  Future<MerchantAssociation?> getAssociationById(String associationId);

  /// The association [merchantId] belongs to (pending or approved), or null.
  /// Prefer [watchMembershipsFor] when a merchant can join several associations.
  Stream<MerchantAssociationMembership?> watchMembershipFor(String merchantId);

  /// All associations [merchantId] belongs to (pending or approved).
  Stream<List<MerchantAssociationMembership>> watchMembershipsFor(
    String merchantId,
  );

  /// Members of [associationId]; pass [approvedOnly] for client-facing views.
  Stream<List<AssociationMember>> watchMembers(
    String associationId, {
    bool approvedOnly = false,
  });

  /// Approved members of [merchantId]'s association, for the client group
  /// page. Empty when the merchant is not an approved member of any.
  Future<List<AssociationMember>> getApprovedMembersForMerchant(
    String merchantId,
  );

  /// Sends a join request for [merchantId]; starts in
  /// [AssociationMemberStatus.pending].
  Future<void> requestToJoin({
    required String associationId,
    required String merchantId,
    required String merchantName,
    String? merchantLogoUrl,
    String? merchantCity,
  });

  Future<void> approveMember({
    required String associationId,
    required String merchantId,
  });

  /// Founder adds a commerce directly as an approved member (no join request).
  Future<void> addMemberAsFounder({
    required String associationId,
    required String merchantId,
    required String merchantName,
    String? merchantLogoUrl,
    String? merchantCity,
  });

  /// Rejects a pending request, removes an approved member, or lets a
  /// member leave on their own.
  Future<void> removeMember({
    required String associationId,
    required String merchantId,
  });
}
