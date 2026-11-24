import '../../../../core/domain/core/result.dart';
import '../entities/organization.dart';
import '../entities/organization_member.dart';

/// Details of a new point de vente; everything else is copied from the
/// template store (logo, category, description, hours…).
class NewStoreDraft {
  const NewStoreDraft({
    required this.city,
    this.cityMetadata,
    this.address,
    this.phone,
    this.storeLabel,
  });

  final String city;
  final Map<String, dynamic>? cityMetadata;
  final String? address;
  final String? phone;
  final String? storeLabel;
}

abstract class OrganizationRepository {
  /// Creates the enseigne and the owner's membership, and links the owner's
  /// [existingStoreIds] to it — one atomic write.
  Future<Result<Organization>> createOrganization({
    required String ownerUid,
    required String name,
    required LoyaltyMode loyaltyMode,
    String? logoUrl,
    String? description,
    String? ownerDisplayName,
    List<String> existingStoreIds = const <String>[],
  });

  Stream<Organization?> watchOrganization(String orgId);

  Future<Result<Unit>> updateOrganization(Organization organization);

  /// New offline store in [orgId], copying shared fields from
  /// [templateStoreId]. Returns the new store id.
  Future<Result<String>> createStoreFromTemplate({
    required String orgId,
    required String ownerUid,
    required String templateStoreId,
    required NewStoreDraft draft,
  });

  /// Ids of every store linked to [orgId].
  Future<Result<List<String>>> storeIdsOf(String orgId);

  /// Active memberships of [uid] across all enseignes.
  Stream<List<OrganizationMember>> watchMyMemberships(String uid);

  Stream<List<OrganizationMember>> watchMembers(String orgId);

  /// Makes [merchantId] the store the user is currently managing.
  Future<Result<Unit>> setActiveStore({
    required String uid,
    required String merchantId,
  });
}
