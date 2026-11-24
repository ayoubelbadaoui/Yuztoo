import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/core/either.dart';
import '../../../core/domain/core/result.dart';
import '../../../core/infrastructure/firebase_providers.dart';
import '../../auth/core/application/providers.dart' as auth_providers;
import '../../auth/core/application/state/auth_state.dart';
import '../../merchant/application/providers.dart' as merchant_providers;
import '../../merchant/domain/entities/merchant.dart';
import '../../merchant/infrastructure/merchant_repository_provider.dart';
import '../domain/entities/organization.dart';
import '../domain/entities/organization_member.dart';
import '../domain/organization_failure.dart';
import '../domain/repositories/organization_repository.dart';
import '../infrastructure/firestore_organization_repository.dart';

final organizationRepositoryProvider = Provider<OrganizationRepository>(
  (ref) =>
      FirestoreOrganizationRepository(ref.watch(firebaseFirestoreProvider)),
);

String? _signedInUid(Ref ref) {
  final auth = ref.watch(auth_providers.authStateProvider);
  return auth is Authenticated ? auth.user.id : null;
}

/// Active enseigne memberships of the signed-in user.
final myMembershipsProvider =
    StreamProvider.autoDispose<List<OrganizationMember>>((ref) {
  final uid = _signedInUid(ref);
  if (uid == null) return Stream.value(const <OrganizationMember>[]);
  return ref.watch(organizationRepositoryProvider).watchMyMemberships(uid);
});

/// Every store the signed-in user can manage or operate: stores he owns plus
/// stores reached through enseigne memberships. Sorted by label / city.
final accessibleStoresProvider =
    FutureProvider.autoDispose<List<Merchant>>((ref) async {
  final owned =
      await ref.watch(merchant_providers.ownedMerchantsProvider.future);
  final memberships = await ref.watch(myMembershipsProvider.future);
  final orgRepo = ref.watch(organizationRepositoryProvider);
  final merchantRepo = ref.watch(merchantRepositoryProvider);

  final known = <String>{for (final m in owned) m.id};
  final extra = <String>{};
  for (final membership in memberships) {
    if (membership.role == OrganizationRole.owner) {
      final ids = await orgRepo.storeIdsOf(membership.orgId);
      extra.addAll(ids.fold((_) => const <String>[], (l) => l));
    } else {
      extra.addAll(membership.storeIds);
    }
  }
  extra.removeAll(known);

  final reached = extra.isEmpty
      ? const <Merchant>[]
      : (await merchantRepo.getMerchantsByIds(extra.toList()))
          .fold((_) => const <Merchant>[], (l) => l);

  final stores = <Merchant>[...owned, ...reached];
  stores.sort((a, b) => storeDisplayName(a)
      .toLowerCase()
      .compareTo(storeDisplayName(b).toLowerCase()));
  return stores;
});

/// "Boulangerie Dupont · Belfort Centre" — label, else city.
String storeDisplayName(Merchant m) {
  final name = (m.displayName?.trim().isNotEmpty ?? false)
      ? m.displayName!.trim()
      : m.name.trim();
  final suffix = (m.storeLabel?.trim().isNotEmpty ?? false)
      ? m.storeLabel!.trim()
      : m.city.trim();
  return suffix.isEmpty ? name : '$name · $suffix';
}

/// Enseigne of the active store, or null for an independent shop.
final currentOrganizationProvider =
    StreamProvider.autoDispose<Organization?>((ref) async* {
  final merchant = await ref
      .watch(merchant_providers.currentMerchantForOwnerProvider.future);
  final orgId = merchant?.organizationId;
  if (orgId == null || orgId.isEmpty) {
    yield null;
    return;
  }
  yield* ref.watch(organizationRepositoryProvider).watchOrganization(orgId);
});

/// Role of the signed-in user on the active store (owner of an independent
/// shop counts as [OrganizationRole.owner]).
final activeStoreRoleProvider =
    FutureProvider.autoDispose<OrganizationRole?>((ref) async {
  final uid = _signedInUid(ref);
  final merchant = await ref
      .watch(merchant_providers.currentMerchantForOwnerProvider.future);
  if (uid == null || merchant == null) return null;
  if (merchant.ownerUid == uid) return OrganizationRole.owner;
  final memberships = await ref.watch(myMembershipsProvider.future);
  for (final m in memberships) {
    if (m.orgId == merchant.organizationId && m.worksIn(merchant.id)) {
      return m.role;
    }
  }
  return null;
});

const _notSignedIn = OrganizationValidationFailure('Session expirée.');

class OrganizationActions {
  OrganizationActions(this._ref);

  final Ref _ref;

  OrganizationRepository get _repo => _ref.read(organizationRepositoryProvider);

  void _refreshStores() {
    _ref.invalidate(merchant_providers.ownedMerchantsProvider);
    _ref.invalidate(merchant_providers.currentMerchantForOwnerProvider);
    _ref.invalidate(accessibleStoresProvider);
  }

  /// Turns the signed-in owner's shops into an enseigne.
  Future<Result<Organization>> createOrganization({
    required String name,
    required LoyaltyMode loyaltyMode,
  }) async {
    final auth = _ref.read(auth_providers.authStateProvider);
    if (auth is! Authenticated) return const Left(_notSignedIn);
    final uid = auth.user.id;
    final owned =
        await _ref.read(merchant_providers.ownedMerchantsProvider.future);
    final template = owned.isEmpty ? null : owned.first;
    final result = await _repo.createOrganization(
      ownerUid: uid,
      name: name,
      loyaltyMode: loyaltyMode,
      logoUrl: template?.logoUrl,
      description: template?.description,
      ownerDisplayName: template?.name,
      existingStoreIds: <String>[
        for (final m in owned)
          if (m.organizationId == null) m.id,
      ],
    );
    _refreshStores();
    return result;
  }

  /// Duplicates [templateStoreId] into a new offline store and, when
  /// [switchToIt], makes it the active store.
  Future<Result<String>> addStore({
    required String orgId,
    required String templateStoreId,
    required NewStoreDraft draft,
    bool switchToIt = true,
  }) async {
    final auth = _ref.read(auth_providers.authStateProvider);
    if (auth is! Authenticated) return const Left(_notSignedIn);
    final result = await _repo.createStoreFromTemplate(
      orgId: orgId,
      ownerUid: auth.user.id,
      templateStoreId: templateStoreId,
      draft: draft,
    );
    final newId = result.rightOrNull;
    if (newId != null && switchToIt) {
      await _repo.setActiveStore(uid: auth.user.id, merchantId: newId);
    }
    _refreshStores();
    return result;
  }

  Future<Result<Unit>> switchStore(String merchantId) async {
    final auth = _ref.read(auth_providers.authStateProvider);
    if (auth is! Authenticated) return const Left(_notSignedIn);
    final result =
        await _repo.setActiveStore(uid: auth.user.id, merchantId: merchantId);
    _ref.invalidate(merchant_providers.currentMerchantForOwnerProvider);
    return result;
  }
}

final organizationActionsProvider =
    Provider<OrganizationActions>(OrganizationActions.new);
