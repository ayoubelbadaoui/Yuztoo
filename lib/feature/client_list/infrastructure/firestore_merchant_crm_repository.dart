import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/infrastructure/logger_service.dart';
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
        // Non-fatal — proceed with empty loyalty map; segment falls back to
        // followedAt-based inactif check in MerchantClientRow.segment.
      }

      // ── N reads: user profiles (display name + city) ────────────────────
      final futures = snap.docs.map(
        (QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
          final clientUid = doc.reference.parent.parent?.id ?? '';
          if (clientUid.isEmpty) return null;

          final ts = doc.data()['followed_at'];
          final followedAt = ts is Timestamp ? ts.toDate() : null;
          final heartLevel = (doc.data()['heart_level'] as int?) ?? 1;

          // Loyalty data (may be absent for followers with no visits).
          final loyalty = loyaltyMap[clientUid];
          final validatedPassages =
              (loyalty?['validated_passages'] as num?)?.toInt() ?? 0;
          final updatedAtTs = loyalty?['updated_at'];
          final lastVisitAt =
              updatedAtTs is Timestamp ? updatedAtTs.toDate() : null;

          String? displayName;
          String? city;
          try {
            final userDoc =
                await _firestore.collection('users').doc(clientUid).get();
            final data = userDoc.data();
            displayName = data?['displayName'] as String?;
            city = data?['city'] as String?;
          } catch (e) {
            LoggerService.logError(
              'CRM: fetch user profile',
              error: e,
            );
          }

          return MerchantClientRow(
            clientUid: clientUid,
            displayName: displayName,
            city: city,
            followedAt: followedAt,
            heartLevel: heartLevel.clamp(1, 3),
            validatedPassages: validatedPassages,
            lastVisitAt: lastVisitAt,
          );
        },
      );

      final results = await Future.wait(futures);
      return results.whereType<MerchantClientRow>().toList();
    });
  }
}
