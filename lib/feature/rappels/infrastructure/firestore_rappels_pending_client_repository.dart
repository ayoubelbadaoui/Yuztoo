import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/infrastructure/logger_service.dart';
import '../domain/entities/pending_client_row.dart';
import '../domain/repositories/i_rappels_pending_client_repository.dart';

/// Firestore: `merchants/{merchantId}/pending_clients/{clientUid}`
class FirestoreRappelsPendingClientRepository
    implements IRappelsPendingClientRepository {
  FirestoreRappelsPendingClientRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String merchantId) =>
      _firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('pending_clients');

  static PendingClientRow _fromDocWithName(
    QueryDocumentSnapshot<Map<String, dynamic>> d,
    String? displayName,
  ) {
    final ts = d.data()['followed_at'];
    DateTime? followedAt;
    if (ts is Timestamp) followedAt = ts.toDate();
    return PendingClientRow(
      clientUid: d.id,
      displayName: displayName,
      followedAt: followedAt,
    );
  }

  @override
  Stream<List<PendingClientRow>> watchPendingClients(String merchantId) {
    if (merchantId.isEmpty) {
      return Stream<List<PendingClientRow>>.value(<PendingClientRow>[]);
    }
    return _col(merchantId)
        .orderBy('followed_at', descending: true)
        .snapshots()
        .asyncMap(
          (QuerySnapshot<Map<String, dynamic>> snap) async {
            final futures = snap.docs.map(
              (QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
                String? displayName;
                try {
                  final userDoc = await _firestore
                      .collection('users')
                      .doc(doc.id)
                      .get();
                  displayName =
                      userDoc.data()?['displayName'] as String?;
                } catch (_) {}
                return _fromDocWithName(doc, displayName);
              },
            );
            return Future.wait(futures);
          },
        );
  }

  @override
  Future<Result<Unit>> acknowledge(
    String merchantId,
    String clientUid,
  ) async {
    if (merchantId.isEmpty || clientUid.isEmpty) {
      return const Left<AppFailure, Unit>(
        UnexpectedFailure(message: 'IDs requis'),
      );
    }
    try {
      await _col(merchantId).doc(clientUid).delete();
      LoggerService.logInfo(
        'Pending client acknowledged',
        context: <String, Object?>{
          'merchantId': merchantId,
          'clientUid': clientUid,
        },
      );
      return const Right<AppFailure, Unit>(unit);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Firebase acknowledge pending client',
        error: e,
        stackTrace: st,
      );
      return Left<AppFailure, Unit>(
        UnexpectedFailure(
          message: 'Impossible d\'acquitter le client',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      LoggerService.logError(
        'Acknowledge pending client',
        error: e,
        stackTrace: st,
      );
      return Left<AppFailure, Unit>(
        UnexpectedFailure(
          message: 'Erreur inattendue',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Called by [FirestoreFollowedMerchantsRepository] on client follow.
  Future<void> writePendingClient(
    String merchantId,
    String clientUid,
  ) async {
    if (merchantId.isEmpty || clientUid.isEmpty) return;
    try {
      await _col(merchantId).doc(clientUid).set(<String, dynamic>{
        'followed_at': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      LoggerService.logError(
        'Write pending client',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Called by [FirestoreFollowedMerchantsRepository] on client unfollow.
  Future<void> removePendingClient(
    String merchantId,
    String clientUid,
  ) async {
    if (merchantId.isEmpty || clientUid.isEmpty) return;
    try {
      await _col(merchantId).doc(clientUid).delete();
    } catch (e, st) {
      LoggerService.logError(
        'Remove pending client',
        error: e,
        stackTrace: st,
      );
    }
  }
}
