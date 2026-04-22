import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/infrastructure/logger_service.dart';
import '../domain/entities/merchant_client_row.dart';
import '../domain/repositories/i_merchant_crm_repository.dart';

/// Firestore implementation of [IMerchantCrmRepository].
///
/// Queries the `followed_merchants` collection-group filtered by merchant,
/// then batch-fetches each follower's user profile for display name / city.
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
      final futures = snap.docs.map(
        (QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
          final clientUid = doc.reference.parent.parent?.id ?? '';
          if (clientUid.isEmpty) return null;

          final ts = doc.data()['followed_at'];
          final followedAt = ts is Timestamp ? ts.toDate() : null;
          final heartLevel = (doc.data()['heart_level'] as int?) ?? 1;

          String? displayName;
          String? city;
          try {
            final userDoc = await _firestore
                .collection('users')
                .doc(clientUid)
                .get();
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
          );
        },
      );

      final results = await Future.wait(futures);
      return results.whereType<MerchantClientRow>().toList();
    });
  }
}
