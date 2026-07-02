import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/domain/core/either.dart';
import '../../../core/domain/core/failure.dart';
import '../../../core/domain/core/result.dart';
import '../../../core/infrastructure/logger_service.dart';
import '../../merchant/domain/entities/loyalty_program_config.dart';
import '../domain/entities/active_validation_request.dart';
import '../domain/repositories/active_validation_repository.dart';

class FirestoreActiveValidationRepository
    implements ActiveValidationRepository {
  FirestoreActiveValidationRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String merchantId) =>
      _firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('active_validations');

  DocumentReference<Map<String, dynamic>> _docRef({
    required String merchantId,
    required String clientUid,
  }) =>
      _collection(merchantId).doc(clientUid);

  /// Replaces a stale `awaiting` doc so client `set` always succeeds as create.
  Future<void> _replaceStaleAwaitingSession(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    final snap = await ref.get();
    if (!snap.exists) return;
    final status = snap.data()?['status'] as String?;
    if (status == 'awaiting') {
      await ref.delete();
    }
  }

  @override
  Future<Result<void>> createBleSession({
    required String merchantId,
    required String clientUid,
    required String clientDisplayName,
    String? clientPhotoUrl,
    required LoyaltyProgramConfig programSnapshot,
    required String merchantDisplayName,
  }) async {
    if (merchantId.isEmpty || clientUid.isEmpty) {
      return const Left<AppFailure, void>(
        UnexpectedFailure(message: 'Commerce ou utilisateur invalide'),
      );
    }
    try {
      final payload = ActiveValidationRequest.toFirestoreBleCreate(
        clientUid: clientUid,
        clientDisplayName: clientDisplayName,
        clientPhotoUrl: clientPhotoUrl,
        programSnapshot: programSnapshot,
        merchantDisplayName: merchantDisplayName,
      );
      final ref = _docRef(merchantId: merchantId, clientUid: clientUid);
      await _replaceStaleAwaitingSession(ref);
      await ref.set(payload);
      return const Right<AppFailure, void>(null);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Active validation createBleSession',
        error: e,
        stackTrace: st,
      );
      return Left<AppFailure, void>(
        UnexpectedFailure(
          message: 'Impossible d\'envoyer la demande',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> markMerchantBleConnected({
    required String merchantId,
    required String clientUid,
  }) async {
    if (merchantId.isEmpty || clientUid.isEmpty) {
      return const Left<AppFailure, void>(
        UnexpectedFailure(message: 'Session invalide'),
      );
    }
    try {
      await _docRef(merchantId: merchantId, clientUid: clientUid).set(
        <String, dynamic>{
          'merchant_ble_connected_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return const Right<AppFailure, void>(null);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Active validation markMerchantBleConnected',
        error: e,
        stackTrace: st,
      );
      return Left<AppFailure, void>(
        UnexpectedFailure(
          message: 'Impossible de confirmer la connexion',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> createForClient({
    required String merchantId,
    required String clientUid,
    required String clientDisplayName,
    String? clientPhotoUrl,
    required LoyaltyProgramConfig programSnapshot,
  }) async {
    if (merchantId.isEmpty || clientUid.isEmpty) {
      return const Left<AppFailure, void>(
        UnexpectedFailure(message: 'Commerce ou utilisateur invalide'),
      );
    }
    try {
      final payload = ActiveValidationRequest.toFirestoreCreate(
        clientUid: clientUid,
        clientDisplayName: clientDisplayName,
        clientPhotoUrl: clientPhotoUrl,
        programSnapshot: programSnapshot,
      );
      final ref = _docRef(merchantId: merchantId, clientUid: clientUid);
      await _replaceStaleAwaitingSession(ref);
      await ref.set(payload);
      return const Right<AppFailure, void>(null);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Active validation create',
        error: e,
        stackTrace: st,
      );
      return Left<AppFailure, void>(
        UnexpectedFailure(
          message: 'Impossible d\'envoyer la demande',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  ActiveValidationRequest? _sessionFromSnap({
    required String merchantId,
    required String clientUid,
    required DocumentSnapshot<Map<String, dynamic>> snap,
  }) {
    if (!snap.exists) return null;
    return ActiveValidationRequest.fromFirestoreMap(
      merchantId: merchantId,
      clientUid: clientUid,
      data: snap.data() ?? <String, dynamic>{},
    );
  }

  @override
  Stream<ActiveValidationRequest?> watchClientSession({
    required String merchantId,
    required String clientUid,
  }) {
    if (merchantId.isEmpty || clientUid.isEmpty) {
      return Stream<ActiveValidationRequest?>.value(null);
    }
    return _docRef(merchantId: merchantId, clientUid: clientUid)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> snap) {
      return _sessionFromSnap(
        merchantId: merchantId,
        clientUid: clientUid,
        snap: snap,
      );
    });
  }

  @override
  Future<Result<ActiveValidationRequest?>> getClientSession({
    required String merchantId,
    required String clientUid,
  }) async {
    if (merchantId.isEmpty || clientUid.isEmpty) {
      return const Left<AppFailure, ActiveValidationRequest?>(
        UnexpectedFailure(message: 'Session invalide'),
      );
    }
    try {
      final snap = await _docRef(merchantId: merchantId, clientUid: clientUid)
          .get();
      return Right<AppFailure, ActiveValidationRequest?>(
        _sessionFromSnap(
          merchantId: merchantId,
          clientUid: clientUid,
          snap: snap,
        ),
      );
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Active validation getClientSession',
        error: e,
        stackTrace: st,
      );
      return Left<AppFailure, ActiveValidationRequest?>(
        UnexpectedFailure(
          message: 'Impossible de charger la demande',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Stream<List<ActiveValidationRequest>> watchMerchantQueue(
    String merchantId,
  ) {
    if (merchantId.isEmpty) {
      return Stream<List<ActiveValidationRequest>>.value(
        const <ActiveValidationRequest>[],
      );
    }
    return _collection(merchantId)
        .where('status', isEqualTo: 'awaiting')
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snap) {
      return snap.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> d) =>
              ActiveValidationRequest.fromFirestoreMap(
                merchantId: merchantId,
                clientUid: d.id,
                data: d.data(),
              ))
          .where((r) => !r.isExpired)
          .toList();
    });
  }

  @override
  Future<Result<void>> markOpened({
    required String merchantId,
    required String clientUid,
  }) async {
    if (merchantId.isEmpty || clientUid.isEmpty) {
      return const Left<AppFailure, void>(
        UnexpectedFailure(message: 'Session invalide'),
      );
    }
    try {
      await _docRef(merchantId: merchantId, clientUid: clientUid).update({
        'opened_at': FieldValue.serverTimestamp(),
      });
      return const Right<AppFailure, void>(null);
    } on FirebaseException catch (e, st) {
      // markOpened is best-effort UI signal — never block validation on this.
      LoggerService.logError(
        'Active validation markOpened',
        error: e,
        stackTrace: st,
      );
      return const Right<AppFailure, void>(null);
    }
  }

  @override
  Future<Result<void>> completeSession({
    required String merchantId,
    required String clientUid,
    int? resultValidatedDelta,
    double? resultSpendDelta,
    double? declaredSpendEuros,
  }) async {
    if (merchantId.isEmpty || clientUid.isEmpty) {
      return const Left<AppFailure, void>(
        UnexpectedFailure(message: 'Session invalide'),
      );
    }
    try {
      final write = <String, dynamic>{
        'status': 'completed',
        'completed_at': FieldValue.serverTimestamp(),
        if (resultValidatedDelta != null)
          'result_validated_delta': resultValidatedDelta,
        if (resultSpendDelta != null) 'result_spend_delta': resultSpendDelta,
        if (declaredSpendEuros != null)
          'declared_spend_euros': declaredSpendEuros,
      };
      await _docRef(merchantId: merchantId, clientUid: clientUid)
          .set(write, SetOptions(merge: true));
      return const Right<AppFailure, void>(null);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Active validation complete',
        error: e,
        stackTrace: st,
      );
      return Left<AppFailure, void>(
        UnexpectedFailure(
          message: 'Impossible de finaliser la validation',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> cancelByMerchant({
    required String merchantId,
    required String clientUid,
    String? reason,
  }) async {
    if (merchantId.isEmpty || clientUid.isEmpty) {
      return const Left<AppFailure, void>(
        UnexpectedFailure(message: 'Session invalide'),
      );
    }
    try {
      await _docRef(merchantId: merchantId, clientUid: clientUid)
          .set(<String, dynamic>{
        'status': 'cancelled',
        'cancel_reason': reason ?? 'merchant_refused',
        'completed_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return const Right<AppFailure, void>(null);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Active validation cancelByMerchant',
        error: e,
        stackTrace: st,
      );
      return Left<AppFailure, void>(
        UnexpectedFailure(
          message: 'Impossible d\'annuler la validation',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> cancelByClient({
    required String merchantId,
    required String clientUid,
  }) async {
    if (merchantId.isEmpty || clientUid.isEmpty) {
      return const Left<AppFailure, void>(
        UnexpectedFailure(message: 'Session invalide'),
      );
    }
    try {
      await _docRef(merchantId: merchantId, clientUid: clientUid).update({
        'status': 'cancelled',
        'cancel_reason': 'client_cancelled',
      });
      return const Right<AppFailure, void>(null);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Active validation cancelByClient',
        error: e,
        stackTrace: st,
      );
      return Left<AppFailure, void>(
        UnexpectedFailure(
          message: 'Impossible d\'annuler la demande',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
