import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/infrastructure/firebase_providers.dart';
import '../domain/entities/association_member.dart';
import '../domain/repositories/i_merchant_association_repository.dart';
import '../infrastructure/firestore_merchant_association_repository.dart';

final merchantAssociationRepositoryProvider =
    Provider<IMerchantAssociationRepository>((ref) {
  return FirestoreMerchantAssociationRepository(
    ref.watch(firebaseFirestoreProvider),
  );
});

/// The association the merchant belongs to (pending or approved), or null.
/// Prefer [merchantAssociationMembershipsProvider] for multi-association UI.
final merchantAssociationMembershipProvider = StreamProvider.autoDispose
    .family<MerchantAssociationMembership?, String>((ref, merchantId) {
  if (merchantId.isEmpty) return Stream.value(null);
  return ref
      .watch(merchantAssociationRepositoryProvider)
      .watchMembershipFor(merchantId);
});

/// All associations the merchant belongs to (pending or approved).
final merchantAssociationMembershipsProvider = StreamProvider.autoDispose
    .family<List<MerchantAssociationMembership>, String>((ref, merchantId) {
  if (merchantId.isEmpty) {
    return Stream.value(const <MerchantAssociationMembership>[]);
  }
  return ref
      .watch(merchantAssociationRepositoryProvider)
      .watchMembershipsFor(merchantId);
});

/// All members of an association, including pending requests — the founder's
/// management view.
final associationMembersProvider = StreamProvider.autoDispose
    .family<List<AssociationMember>, String>((ref, associationId) {
  if (associationId.isEmpty) return Stream.value(const []);
  return ref
      .watch(merchantAssociationRepositoryProvider)
      .watchMembers(associationId);
});

/// Approved members only — what clients see on the group page.
final approvedAssociationMembersProvider = StreamProvider.autoDispose
    .family<List<AssociationMember>, String>((ref, associationId) {
  if (associationId.isEmpty) return Stream.value(const []);
  return ref
      .watch(merchantAssociationRepositoryProvider)
      .watchMembers(associationId, approvedOnly: true);
});

/// Association of a merchant as seen from a client vitrine: resolved only
/// when the merchant is an approved member.
final publicAssociationForMerchantProvider = FutureProvider.autoDispose
    .family<MerchantAssociationMembership?, String>((ref, merchantId) async {
  if (merchantId.isEmpty) return null;
  final repo = ref.watch(merchantAssociationRepositoryProvider);
  final membership = await repo.watchMembershipFor(merchantId).first;
  if (membership == null || !membership.member.isApproved) return null;
  return membership;
});
