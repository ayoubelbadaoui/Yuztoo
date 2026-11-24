import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/domain/core/either.dart';
import '../../../core/domain/core/result.dart';
import '../../../core/infrastructure/logger_service.dart';
import '../../../core/utils/city_input.dart';
import '../domain/entities/organization.dart';
import '../domain/entities/organization_member.dart';
import '../domain/organization_failure.dart';
import '../domain/repositories/organization_repository.dart';

/// Store fields shared across an enseigne: copied when a new point de vente
/// is created from an existing one. Photos, address, phone and opening
/// status stay per store.
const List<String> _sharedStoreFields = <String>[
  'name',
  'name_lowercase',
  'display_name',
  'email',
  'categories',
  'category_id',
  'subcategory_title',
  'description',
  'hours',
  'logo_url',
  'website_url',
  'merchant_type',
  'loyalty_enabled',
  'loyalty_program',
  'messaging_enabled',
  'notifications_auto_enabled',
  'galerie_enabled',
  'rappels_auto_client_validation',
  'rappels_auto_passage_validation',
  'passage_cooldown_enabled',
  'welcome_gift_description',
  'gratification_config',
];

class FirestoreOrganizationRepository implements OrganizationRepository {
  FirestoreOrganizationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _orgs =>
      _firestore.collection('organizations');

  CollectionReference<Map<String, dynamic>> get _merchants =>
      _firestore.collection('merchants');

  @override
  Future<Result<Organization>> createOrganization({
    required String ownerUid,
    required String name,
    required LoyaltyMode loyaltyMode,
    String? logoUrl,
    String? description,
    String? ownerDisplayName,
    List<String> existingStoreIds = const <String>[],
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 80) {
      return const Left(
        OrganizationValidationFailure('Le nom de l\'enseigne est requis.'),
      );
    }
    try {
      final orgRef = _orgs.doc();
      final batch = _firestore.batch();
      batch.set(orgRef, <String, dynamic>{
        'name': trimmed,
        'owner_uid': ownerUid,
        'loyalty_mode': loyaltyMode.firestoreValue,
        if (logoUrl != null && logoUrl.isNotEmpty) 'logo_url': logoUrl,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      batch.set(orgRef.collection('members').doc(ownerUid), <String, dynamic>{
        'uid': ownerUid,
        'org_id': orgRef.id,
        'role': OrganizationRole.owner.firestoreValue,
        'store_ids': <String>[],
        'status': 'active',
        if (ownerDisplayName != null && ownerDisplayName.isNotEmpty)
          'display_name': ownerDisplayName,
        'joined_at': FieldValue.serverTimestamp(),
      });
      for (final storeId in existingStoreIds) {
        batch.update(_merchants.doc(storeId), <String, dynamic>{
          'organization_id': orgRef.id,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      return Right(
        Organization(
          id: orgRef.id,
          name: trimmed,
          ownerUid: ownerUid,
          loyaltyMode: loyaltyMode,
          logoUrl: logoUrl,
          description: description,
        ),
      );
    } catch (e, st) {
      LoggerService.logError('createOrganization failed',
          error: e, stackTrace: st);
      return Left(OrganizationNetworkFailure(cause: e, stackTrace: st));
    }
  }

  @override
  Stream<Organization?> watchOrganization(String orgId) {
    if (orgId.isEmpty) return Stream<Organization?>.value(null);
    return _orgs.doc(orgId).snapshots().map(
          (doc) => doc.exists ? _organizationFromDoc(doc) : null,
        );
  }

  @override
  Future<Result<Unit>> updateOrganization(Organization organization) async {
    try {
      await _orgs.doc(organization.id).update(<String, dynamic>{
        'name': organization.name.trim(),
        'loyalty_mode': organization.loyaltyMode.firestoreValue,
        'logo_url': organization.logoUrl,
        'description': organization.description,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return const Right(unit);
    } catch (e, st) {
      return Left(OrganizationNetworkFailure(cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<String>> createStoreFromTemplate({
    required String orgId,
    required String ownerUid,
    required String templateStoreId,
    required NewStoreDraft draft,
  }) async {
    final city = CityInput.forFirestore(draft.city);
    if (city == null || city.isEmpty) {
      return const Left(
        OrganizationValidationFailure('Choisissez la ville du point de vente.'),
      );
    }
    try {
      final template = await _merchants.doc(templateStoreId).get();
      final source = template.data();
      if (source == null) return const Left(OrganizationNotFoundFailure());

      final data = <String, dynamic>{
        for (final key in _sharedStoreFields)
          if (source[key] != null) key: source[key],
        'owner_uid': ownerUid,
        'organization_id': orgId,
        'city': city,
        if (draft.cityMetadata != null) 'city_metadata': draft.cityMetadata,
        if (draft.address?.trim().isNotEmpty ?? false)
          'address': draft.address!.trim(),
        'phone': draft.phone?.trim() ?? '',
        if (draft.storeLabel?.trim().isNotEmpty ?? false)
          'store_label': draft.storeLabel!.trim(),
        'subscription_plan': 'gratuit',
        'status': 'inactive',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      final ref = _merchants.doc();
      await ref.set(data);
      return Right(ref.id);
    } catch (e, st) {
      LoggerService.logError('createStoreFromTemplate failed',
          error: e, stackTrace: st);
      return Left(OrganizationNetworkFailure(cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<List<String>>> storeIdsOf(String orgId) async {
    try {
      final snap =
          await _merchants.where('organization_id', isEqualTo: orgId).get();
      return Right(<String>[
        for (final doc in snap.docs)
          if (doc.data()['deleted_at'] == null) doc.id,
      ]);
    } catch (e, st) {
      return Left(OrganizationNetworkFailure(cause: e, stackTrace: st));
    }
  }

  @override
  Stream<List<OrganizationMember>> watchMyMemberships(String uid) {
    if (uid.isEmpty) return Stream.value(const <OrganizationMember>[]);
    return _firestore
        .collectionGroup('members')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snap) => <OrganizationMember>[
              for (final doc in snap.docs)
                if (_memberFromData(doc.data()) case final m? when m.isActive)
                  m,
            ]);
  }

  @override
  Stream<List<OrganizationMember>> watchMembers(String orgId) {
    if (orgId.isEmpty) return Stream.value(const <OrganizationMember>[]);
    return _orgs.doc(orgId).collection('members').snapshots().map(
          (snap) => <OrganizationMember>[
            for (final doc in snap.docs)
              if (_memberFromData(doc.data()) case final m?) m,
          ],
        );
  }

  @override
  Future<Result<Unit>> setActiveStore({
    required String uid,
    required String merchantId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .update(<String, dynamic>{'merchant_id': merchantId});
      return const Right(unit);
    } catch (e, st) {
      return Left(OrganizationNetworkFailure(cause: e, stackTrace: st));
    }
  }

  Organization _organizationFromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final created = d['created_at'];
    return Organization(
      id: doc.id,
      name: (d['name'] as String?) ?? '',
      ownerUid: (d['owner_uid'] as String?) ?? '',
      loyaltyMode: LoyaltyMode.fromFirestore(d['loyalty_mode'] as String?),
      logoUrl: d['logo_url'] as String?,
      description: d['description'] as String?,
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }

  OrganizationMember? _memberFromData(Map<String, dynamic> d) {
    final uid = d['uid'];
    final orgId = d['org_id'];
    if (uid is! String || orgId is! String) return null;
    final stores = d['store_ids'];
    return OrganizationMember(
      uid: uid,
      orgId: orgId,
      role: OrganizationRole.fromFirestore(d['role'] as String?),
      storeIds: stores is List ? stores.whereType<String>().toList() : const [],
      isActive: d['status'] == 'active',
      displayName: d['display_name'] as String?,
    );
  }
}
