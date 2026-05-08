import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/domain/core/either.dart';
import '../../../core/domain/core/failure.dart';
import '../../../core/domain/core/result.dart';
import '../../../core/infrastructure/logger_service.dart';
import '../domain/repositories/user_safety_repository.dart';

/// Firestore-backed [UserSafetyRepository]. Strictly mirrors the
/// firestore.rules constraints (allowlist of fields, length caps), so the
/// client never sends a payload that would be rejected server-side.
class FirestoreUserSafetyRepository implements UserSafetyRepository {
  FirestoreUserSafetyRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _blocksOf(String userId) =>
      _firestore.collection('users').doc(userId).collection('blocked_merchants');

  @override
  Stream<Set<String>> watchBlockedMerchantIds(String userId) {
    if (userId.isEmpty) return Stream<Set<String>>.value(const <String>{});
    return _blocksOf(userId).snapshots().map(
          (snap) => snap.docs.map((d) => d.id).toSet(),
        );
  }

  @override
  Future<Result<Unit>> blockMerchant({
    required String userId,
    required String merchantId,
  }) async {
    if (userId.isEmpty || merchantId.isEmpty) {
      return const Left<AppFailure, Unit>(
        UnexpectedFailure(message: 'Identifiants invalides'),
      );
    }
    try {
      // Set with merge:true so a re-block doesn't error out if the doc
      // already exists. The payload contains exactly one allowlisted
      // field — anything else would fail rule validation.
      await _blocksOf(userId).doc(merchantId).set(
        <String, dynamic>{'created_at': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      return const Right<AppFailure, Unit>(unit);
    } on FirebaseException catch (e, st) {
      LoggerService.logError('blockMerchant', error: e, stackTrace: st);
      return Left<AppFailure, Unit>(
        UnexpectedFailure(
          message: 'Impossible de bloquer ce commerce',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      LoggerService.logError('blockMerchant unexpected',
          error: e, stackTrace: st);
      return Left<AppFailure, Unit>(
        UnexpectedFailure(
          message: 'Erreur inattendue',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Unit>> unblockMerchant({
    required String userId,
    required String merchantId,
  }) async {
    if (userId.isEmpty || merchantId.isEmpty) {
      return const Left<AppFailure, Unit>(
        UnexpectedFailure(message: 'Identifiants invalides'),
      );
    }
    try {
      // Delete is naturally idempotent on Firestore — removing a
      // non-existent doc is a no-op success.
      await _blocksOf(userId).doc(merchantId).delete();
      return const Right<AppFailure, Unit>(unit);
    } on FirebaseException catch (e, st) {
      LoggerService.logError('unblockMerchant', error: e, stackTrace: st);
      return Left<AppFailure, Unit>(
        UnexpectedFailure(
          message: 'Impossible de débloquer',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Unit>> submitReport({
    required String reporterUid,
    required ReportTargetType targetType,
    required String targetId,
    required ReportReason reason,
    String? message,
  }) async {
    if (reporterUid.isEmpty || targetId.isEmpty) {
      return const Left<AppFailure, Unit>(
        UnexpectedFailure(message: 'Signalement incomplet'),
      );
    }
    if (targetId.length > 128) {
      return const Left<AppFailure, Unit>(
        UnexpectedFailure(message: 'Identifiant de cible trop long'),
      );
    }
    final trimmedMessage = message?.trim();
    if (trimmedMessage != null && trimmedMessage.length > 500) {
      return const Left<AppFailure, Unit>(
        UnexpectedFailure(
          message: 'Le message dépasse 500 caractères',
        ),
      );
    }

    try {
      final doc = <String, dynamic>{
        'reporter_uid': reporterUid,
        'target_type': targetType.wire,
        'target_id': targetId,
        'reason': reason.wire,
        if (trimmedMessage != null && trimmedMessage.isNotEmpty)
          'message': trimmedMessage,
        'created_at': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('reports').add(doc);
      return const Right<AppFailure, Unit>(unit);
    } on FirebaseException catch (e, st) {
      LoggerService.logError('submitReport', error: e, stackTrace: st);
      return Left<AppFailure, Unit>(
        UnexpectedFailure(
          message: 'Impossible d’envoyer le signalement',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      LoggerService.logError('submitReport unexpected',
          error: e, stackTrace: st);
      return Left<AppFailure, Unit>(
        UnexpectedFailure(
          message: 'Erreur inattendue',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
