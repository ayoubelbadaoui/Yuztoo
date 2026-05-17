import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/infrastructure/logger_service.dart';
import '../../merchant/domain/entities/client_gratification_config.dart';
import '../domain/entities/merchant_client_row.dart';
import '../domain/repositories/i_merchant_crm_repository.dart';

/// Firestore implementation of [IMerchantCrmRepository].
///
/// On each stream event this does exactly **2** Firestore reads:
///   1. Collection-group query on `followed_merchants` (the live stream).
///   2. Single batch read of `merchants/{id}/loyalty_clients` for passage data.
///
/// Then N user-profile reads (one per follower) for display name / city — the
/// same pattern used before this change.
///
/// Requires a Firestore composite index:
///   collectionGroup = followed_merchants
///   fields: merchant_id ASC, followed_at DESC
class FirestoreMerchantCrmRepository implements IMerchantCrmRepository {
  FirestoreMerchantCrmRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<MerchantClientRow>> watchClients(String merchantId) {
    if (merchantId.isEmpty) {
      return Stream<List<MerchantClientRow>>.value(<MerchantClientRow>[]);
    }
    return _firestore
        .collectionGroup('followed_merchants')
        .where('merchant_id', isEqualTo: merchantId)
        .orderBy('followed_at', descending: true)
        .snapshots()
        .asyncMap((QuerySnapshot<Map<String, dynamic>> snap) async {
      ClientGratificationConfig gratificationConfig =
          ClientGratificationConfig.defaults;
      try {
        final merchantSnap =
            await _firestore.collection('merchants').doc(merchantId).get();
        final raw = merchantSnap.data()?['gratification_config'];
        if (raw is Map) {
          gratificationConfig = ClientGratificationConfig.fromMap(
            Map<String, dynamic>.from(raw),
          );
        }
      } catch (e) {
        LoggerService.logError('CRM: fetch gratification_config', error: e);
      }

      // ── 1 read: fetch all loyalty_clients in one shot ──────────────────────
      // This gives us validated_passages + updated_at for every client without
      // an N+1 read per follower.
      Map<String, Map<String, dynamic>> loyaltyMap = {};
      try {
        final loyaltySnap = await _firestore
            .collection('merchants')
            .doc(merchantId)
            .collection('loyalty_clients')
            .get();
        for (final doc in loyaltySnap.docs) {
          loyaltyMap[doc.id] = doc.data();
        }
      } catch (e) {
        LoggerService.logError('CRM: fetch loyalty_clients batch', error: e);
      }

      // ── 1 read: merchant-side per-client overrides (manual segment etc.) ─
      // Stored at merchants/{merchantId}/clients/{clientUid} so the merchant
      // can write without needing access to the client's own user doc.
      final Map<String, Map<String, dynamic>> overridesMap =
          <String, Map<String, dynamic>>{};
      try {
        final overridesSnap = await _firestore
            .collection('merchants')
            .doc(merchantId)
            .collection('clients')
            .get();
        for (final doc in overridesSnap.docs) {
          overridesMap[doc.id] = doc.data();
        }
      } catch (e) {
        LoggerService.logError('CRM: fetch client overrides', error: e);
      }

      // ── N reads: user profiles (display name + photo + city) ────────────
      final futures = snap.docs.map(
        (QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
          final clientUid = doc.reference.parent.parent?.id ?? '';
          if (clientUid.isEmpty) return null;

          final ts = doc.data()['followed_at'];
          final followedAt = ts is Timestamp ? ts.toDate() : null;
          final heartLevel = (doc.data()['heart_level'] as int?) ?? 1;

          final loyalty = loyaltyMap[clientUid];
          final validatedPassages =
              (loyalty?['validated_passages'] as num?)?.toInt() ?? 0;
          // Prefer `last_passage_at` (set only on a real passage event).
          // `updated_at` also bumps on CRM edits and would understate
          // `daysSinceLastVisit`. Legacy docs that pre-date the cooldown
          // anchor still fall back to `updated_at`. Mirrors the same fix
          // in `FirestoreClientLoyaltyRepository.getClientSegments`, so
          // the CRM list and the notification-targeting view stay in sync.
          final lastPassageTs = loyalty?['last_passage_at'];
          final updatedAtTs = loyalty?['updated_at'];
          final DateTime? lastVisitAt = lastPassageTs is Timestamp
              ? lastPassageTs.toDate()
              : (updatedAtTs is Timestamp ? updatedAtTs.toDate() : null);

          String? displayName;
          String? firstName;
          String? lastName;
          String? photoUrl;
          String? city;
          try {
            final userDoc =
                await _firestore.collection('users').doc(clientUid).get();
            final data = userDoc.data();
            displayName = data?['displayName'] as String?;
            firstName = data?['first_name'] as String?;
            lastName = data?['last_name'] as String?;
            // Read both casings — Firebase Auth -> Firestore mirror uses
            // `photoUrl` (camelCase) but some legacy docs use `photo_url`.
            photoUrl = (data?['photoUrl'] as String?) ??
                (data?['photo_url'] as String?);
            city = data?['city'] as String?;
          } catch (e) {
            LoggerService.logError(
              'CRM: fetch user profile',
              error: e,
            );
          }

          final override = overridesMap[clientUid];
          final manualSegmentStr =
              override?['manual_segment'] as String?;
          final manualSegment = _segmentFromString(manualSegmentStr);

          return MerchantClientRow(
            clientUid: clientUid,
            displayName: displayName,
            firstName: firstName,
            lastName: lastName,
            photoUrl: photoUrl,
            city: city,
            followedAt: followedAt,
            heartLevel: heartLevel.clamp(1, 3),
            validatedPassages: validatedPassages,
            lastVisitAt: lastVisitAt,
            manualSegment: manualSegment,
            gratificationConfig: gratificationConfig,
          );
        },
      );

      final results = await Future.wait(futures);
      return results.whereType<MerchantClientRow>().toList();
    });
  }

  @override
  Future<void> setClientManualSegment({
    required String merchantId,
    required String clientUid,
    required ClientSegment? segment,
  }) async {
    if (merchantId.isEmpty || clientUid.isEmpty) return;
    final ref = _firestore
        .collection('merchants')
        .doc(merchantId)
        .collection('clients')
        .doc(clientUid);

    if (segment == null) {
      // Clearing the override — write `null` (rather than deleting the doc)
      // keeps any other future per-client merchant-side fields intact.
      await ref.set(
        <String, dynamic>{
          'manual_segment': FieldValue.delete(),
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } else {
      await ref.set(
        <String, dynamic>{
          'manual_segment': segment.name,
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
  }

  /// Reverse of [ClientSegment.name] — `null` and unknown values return null
  /// so we cleanly fall back to the auto-computed segment.
  static ClientSegment? _segmentFromString(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final s in ClientSegment.values) {
      if (s.name == raw) return s;
    }
    return null;
  }
}
