import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/infrastructure/logger_service.dart';
import '../../../core/infrastructure/tolerant_mapping.dart';
import '../../../core/utils/text_search.dart';
import '../domain/entities/association_member.dart';
import '../domain/entities/merchant_association.dart';
import '../domain/repositories/i_merchant_association_repository.dart';

/// Firestore layout:
///
/// ```
/// merchant_associations/{associationId}
///   name, name_lowercase, city, description,
///   founder_merchant_id, founder_uid, member_count, created_at
///
/// merchant_associations/{associationId}/association_members/{merchantId}
///   association_id, merchant_id, merchant_name, merchant_logo_url,
///   merchant_city, owner_uid, status, requested_at, approved_at
/// ```
///
/// `association_members` is queried as a collection group so a merchant's
/// own membership resolves in one read without duplicating state on the
/// merchant document. `member_count` counts approved members only and is
/// kept in step with membership writes inside a transaction.
class FirestoreMerchantAssociationRepository
    implements IMerchantAssociationRepository {
  FirestoreMerchantAssociationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  /// Shared by the collection-group query and the security rules.
  static const String membersCollection = 'association_members';

  CollectionReference<Map<String, dynamic>> get _associations =>
      _firestore.collection('merchant_associations');

  CollectionReference<Map<String, dynamic>> _members(String associationId) =>
      _associations.doc(associationId).collection(membersCollection);

  @override
  Future<MerchantAssociation> createAssociation({
    required String founderMerchantId,
    required String founderName,
    required String name,
    String city = '',
    String? description,
    String? founderLogoUrl,
  }) async {
    final cleanName = name.trim();
    if (founderMerchantId.isEmpty || cleanName.isEmpty) {
      throw ArgumentError('Association name and founder are required');
    }

    final ref = _associations.doc();
    final cleanDescription = description?.trim() ?? '';
    final batch = _firestore.batch();

    batch.set(ref, <String, dynamic>{
      'name': cleanName,
      'name_lowercase': cleanName.toLowerCase(),
      'city': city.trim(),
      if (cleanDescription.isNotEmpty) 'description': cleanDescription,
      // Rules resolve the founder's owner_uid from this merchant id, the
      // same way isMerchantOwner() already guards merchant subcollections.
      'founder_merchant_id': founderMerchantId,
      'member_count': 1,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    // The founder is a member from the start, already approved.
    batch.set(
        ref.collection(membersCollection).doc(founderMerchantId),
        <String, dynamic>{
          'association_id': ref.id,
          'merchant_id': founderMerchantId,
          'merchant_name': founderName.trim(),
          if (founderLogoUrl != null && founderLogoUrl.isNotEmpty)
            'merchant_logo_url': founderLogoUrl,
          'merchant_city': city.trim(),
          'status': AssociationMemberStatus.approved.firestoreValue,
          'requested_at': FieldValue.serverTimestamp(),
          'approved_at': FieldValue.serverTimestamp(),
        });

    await batch.commit();

    return MerchantAssociation(
      id: ref.id,
      name: cleanName,
      founderMerchantId: founderMerchantId,
      city: city.trim(),
      description: cleanDescription.isEmpty ? null : cleanDescription,
      memberCount: 1,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<List<MerchantAssociation>> searchAssociations(String query) async {
    final normalized = normalizeForSearch(query);
    if (normalized.isEmpty) return const [];

    try {
      // Associations are few; score client-side so the search tolerates
      // accents and typos exactly like the partner search does.
      final snap = await _associations.limit(200).get();
      final scored = <({MerchantAssociation association, double score})>[];
      for (final doc in snap.docs) {
        final association = _associationFrom(doc);
        if (association == null) continue;
        final score = fuzzyMatchScore(
          query: query,
          candidate: association.name,
        );
        final cityScore = association.city.isEmpty
            ? 0.0
            : fuzzyMatchScore(query: query, candidate: association.city);
        final best = score > cityScore ? score : cityScore;
        if (best <= 0) continue;
        scored.add((association: association, score: best));
      }
      scored.sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return a.association.name
            .toLowerCase()
            .compareTo(b.association.name.toLowerCase());
      });
      return scored.map((e) => e.association).take(20).toList();
    } catch (e, st) {
      LoggerService.logError(
        'Failed to search merchant associations',
        error: e,
        stackTrace: st,
      );
      return const [];
    }
  }

  @override
  Future<MerchantAssociation?> getAssociationById(String associationId) async {
    if (associationId.isEmpty) return null;
    try {
      final snap = await _associations.doc(associationId).get();
      return _associationFrom(snap);
    } catch (e, st) {
      LoggerService.logError(
        'Failed to load association $associationId',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  @override
  Stream<MerchantAssociationMembership?> watchMembershipFor(
    String merchantId,
  ) {
    return watchMembershipsFor(merchantId).map(
      (list) => list.isEmpty ? null : list.first,
    );
  }

  @override
  Stream<List<MerchantAssociationMembership>> watchMembershipsFor(
    String merchantId,
  ) {
    if (merchantId.isEmpty) {
      return Stream.value(const <MerchantAssociationMembership>[]);
    }
    return _firestore
        .collectionGroup(membersCollection)
        .where('merchant_id', isEqualTo: merchantId)
        .snapshots()
        .asyncMap((snap) async {
      final out = <MerchantAssociationMembership>[];
      for (final doc in snap.docs) {
        final member = _memberFrom(doc);
        if (member == null) continue;
        final association = await getAssociationById(member.associationId);
        if (association == null) continue;
        out.add(
          MerchantAssociationMembership(
            association: association,
            member: member,
          ),
        );
      }
      return out;
    });
  }

  @override
  Stream<List<AssociationMember>> watchMembers(
    String associationId, {
    bool approvedOnly = false,
  }) {
    if (associationId.isEmpty) return Stream.value(const []);
    Query<Map<String, dynamic>> query = _members(associationId);
    if (approvedOnly) {
      query = query.where(
        'status',
        isEqualTo: AssociationMemberStatus.approved.firestoreValue,
      );
    }
    return query.snapshots().map(
          (snap) => snap.docs
              .mapSkippingInvalid(_memberFrom)
              .whereType<AssociationMember>()
              .toList(),
        );
  }

  @override
  Future<List<AssociationMember>> getApprovedMembersForMerchant(
    String merchantId,
  ) async {
    if (merchantId.isEmpty) return const [];
    try {
      final own = await _firestore
          .collectionGroup(membersCollection)
          .where('merchant_id', isEqualTo: merchantId)
          .where(
            'status',
            isEqualTo: AssociationMemberStatus.approved.firestoreValue,
          )
          .limit(1)
          .get();
      if (own.docs.isEmpty) return const [];
      final member = _memberFrom(own.docs.first);
      if (member == null) return const [];

      final snap = await _members(member.associationId)
          .where(
            'status',
            isEqualTo: AssociationMemberStatus.approved.firestoreValue,
          )
          .get();
      return snap.docs
          .mapSkippingInvalid(_memberFrom)
          .whereType<AssociationMember>()
          .toList();
    } catch (e, st) {
      LoggerService.logError(
        'Failed to load association members for merchant=$merchantId',
        error: e,
        stackTrace: st,
      );
      return const [];
    }
  }

  @override
  Future<void> requestToJoin({
    required String associationId,
    required String merchantId,
    required String merchantName,
    String? merchantLogoUrl,
    String? merchantCity,
  }) async {
    if (associationId.isEmpty || merchantId.isEmpty) return;
    await _members(associationId).doc(merchantId).set(<String, dynamic>{
      'association_id': associationId,
      'merchant_id': merchantId,
      'merchant_name': merchantName.trim(),
      if (merchantLogoUrl != null && merchantLogoUrl.isNotEmpty)
        'merchant_logo_url': merchantLogoUrl,
      'merchant_city': merchantCity?.trim() ?? '',
      'status': AssociationMemberStatus.pending.firestoreValue,
      'requested_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> approveMember({
    required String associationId,
    required String merchantId,
  }) async {
    if (associationId.isEmpty || merchantId.isEmpty) return;
    final memberRef = _members(associationId).doc(merchantId);
    final associationRef = _associations.doc(associationId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(memberRef);
      final data = snap.data();
      if (!snap.exists || data == null) return;
      // Approving twice must not inflate member_count.
      if (AssociationMemberStatus.fromFirestore(data['status'] as String?) ==
          AssociationMemberStatus.approved) {
        return;
      }
      tx.update(memberRef, <String, dynamic>{
        'status': AssociationMemberStatus.approved.firestoreValue,
        'approved_at': FieldValue.serverTimestamp(),
      });
      tx.set(
        associationRef,
        <String, dynamic>{
          'member_count': FieldValue.increment(1),
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  @override
  Future<void> addMemberAsFounder({
    required String associationId,
    required String merchantId,
    required String merchantName,
    String? merchantLogoUrl,
    String? merchantCity,
  }) async {
    if (associationId.isEmpty || merchantId.isEmpty) return;
    final memberRef = _members(associationId).doc(merchantId);
    final associationRef = _associations.doc(associationId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(memberRef);
      final alreadyApproved = snap.exists &&
          AssociationMemberStatus.fromFirestore(
                snap.data()?['status'] as String?,
              ) ==
              AssociationMemberStatus.approved;
      tx.set(
        memberRef,
        <String, dynamic>{
          'association_id': associationId,
          'merchant_id': merchantId,
          'merchant_name': merchantName.trim(),
          if (merchantLogoUrl != null && merchantLogoUrl.isNotEmpty)
            'merchant_logo_url': merchantLogoUrl,
          'merchant_city': merchantCity?.trim() ?? '',
          'status': AssociationMemberStatus.approved.firestoreValue,
          'requested_at': FieldValue.serverTimestamp(),
          'approved_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      if (!alreadyApproved) {
        tx.set(
          associationRef,
          <String, dynamic>{
            'member_count': FieldValue.increment(1),
            'updated_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });
  }

  @override
  Future<void> removeMember({
    required String associationId,
    required String merchantId,
  }) async {
    if (associationId.isEmpty || merchantId.isEmpty) return;
    final memberRef = _members(associationId).doc(merchantId);
    final associationRef = _associations.doc(associationId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(memberRef);
      final data = snap.data();
      if (!snap.exists || data == null) return;
      final wasApproved =
          AssociationMemberStatus.fromFirestore(data['status'] as String?) ==
              AssociationMemberStatus.approved;
      tx.delete(memberRef);
      if (wasApproved) {
        tx.set(
          associationRef,
          <String, dynamic>{
            'member_count': FieldValue.increment(-1),
            'updated_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });
  }

  MerchantAssociation? _associationFrom(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) return null;
    final name = (data['name'] as String? ?? '').trim();
    final founder = (data['founder_merchant_id'] as String? ?? '').trim();
    if (name.isEmpty || founder.isEmpty) return null;
    return MerchantAssociation(
      id: doc.id,
      name: name,
      founderMerchantId: founder,
      city: (data['city'] as String? ?? '').trim(),
      description: (data['description'] as String?)?.trim(),
      memberCount: _nonNegInt(data['member_count']),
      createdAt: _parseTimestamp(data['created_at']),
    );
  }

  AssociationMember? _memberFrom(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final merchantId = (data['merchant_id'] as String? ?? doc.id).trim();
    // The parent id is authoritative; `association_id` is a denormalised copy
    // that only exists to make the collection-group query self-describing.
    final associationId = doc.reference.parent.parent?.id ??
        (data['association_id'] as String? ?? '').trim();
    if (merchantId.isEmpty || associationId.isEmpty) return null;
    return AssociationMember(
      merchantId: merchantId,
      associationId: associationId,
      merchantName: (data['merchant_name'] as String? ?? '').trim(),
      merchantLogoUrl: (data['merchant_logo_url'] as String?)?.trim(),
      merchantCity: (data['merchant_city'] as String?)?.trim(),
      status: AssociationMemberStatus.fromFirestore(data['status'] as String?),
      requestedAt: _parseTimestamp(data['requested_at']),
      approvedAt: _parseTimestamp(data['approved_at']),
    );
  }

  static int _nonNegInt(dynamic value) {
    if (value is int) return value < 0 ? 0 : value;
    if (value is num) return value.toInt().clamp(0, 1 << 30);
    return 0;
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
