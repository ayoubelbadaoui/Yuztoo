import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/infrastructure/logger_service.dart';
import '../domain/repositories/followed_merchants_repository.dart';

/// Firestore: users/{userId}/followed_merchants/{merchantId} with { followed_at: timestamp }.
class FirestoreFollowedMerchantsRepository implements FollowedMerchantsRepository {
  FirestoreFollowedMerchantsRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _followedRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('followed_merchants');

  @override
  Future<Result<Unit>> add(String userId, String merchantId) async {
    if (userId.isEmpty || merchantId.isEmpty) {
      return const Left<AppFailure, Unit>(
        UnexpectedFailure(message: 'User ID and merchant ID are required'),
      );
    }
    try {
      await _followedRef(userId).doc(merchantId).set({
        'followed_at': FieldValue.serverTimestamp(),
      });
      LoggerService.logInfo('Followed merchant added', context: {'userId': userId, 'merchantId': merchantId});
      return const Right<AppFailure, Unit>(unit);
    } on FirebaseException catch (e, st) {
      LoggerService.logError('Firebase error adding followed merchant', error: e, stackTrace: st);
      return Left<AppFailure, Unit>(
        UnexpectedFailure(message: 'Impossible d\'ajouter le commerce', cause: e, stackTrace: st),
      );
    } catch (e, st) {
      LoggerService.logError('Error adding followed merchant', error: e, stackTrace: st);
      return Left<AppFailure, Unit>(
        UnexpectedFailure(message: 'Erreur lors du suivi du commerce', cause: e, stackTrace: st),
      );
    }
  }

  @override
  Future<Result<Unit>> remove(String userId, String merchantId) async {
    if (userId.isEmpty || merchantId.isEmpty) {
      return const Right<AppFailure, Unit>(unit);
    }
    try {
      await _followedRef(userId).doc(merchantId).delete();
      LoggerService.logInfo('Followed merchant removed', context: {'userId': userId, 'merchantId': merchantId});
      return const Right<AppFailure, Unit>(unit);
    } on FirebaseException catch (e, st) {
      LoggerService.logError('Firebase error removing followed merchant', error: e, stackTrace: st);
      return Left<AppFailure, Unit>(
        UnexpectedFailure(message: 'Impossible de ne plus suivre le commerce', cause: e, stackTrace: st),
      );
    } catch (e, st) {
      LoggerService.logError('Error removing followed merchant', error: e, stackTrace: st);
      return Left<AppFailure, Unit>(
        UnexpectedFailure(message: 'Erreur lors de l\'arrêt du suivi', cause: e, stackTrace: st),
      );
    }
  }

  @override
  Future<Result<List<String>>> getFollowedIds(String userId) async {
    if (userId.isEmpty) {
      return const Right<AppFailure, List<String>>([]);
    }
    try {
      final snapshot = await _followedRef(userId).get();
      final ids = snapshot.docs.map((d) => d.id).toList();
      LoggerService.logInfo('Followed merchant IDs loaded', context: {'userId': userId, 'count': ids.length});
      return Right<AppFailure, List<String>>(ids);
    } on FirebaseException catch (e, st) {
      LoggerService.logError('Firebase error loading followed merchants', error: e, stackTrace: st);
      return Left<AppFailure, List<String>>(
        UnexpectedFailure(message: 'Impossible de charger les commerces suivis', cause: e, stackTrace: st),
      );
    } catch (e, st) {
      LoggerService.logError('Error loading followed merchants', error: e, stackTrace: st);
      return Left<AppFailure, List<String>>(
        UnexpectedFailure(message: 'Erreur de chargement', cause: e, stackTrace: st),
      );
    }
  }

  @override
  Future<Result<bool>> isFollowing(String userId, String merchantId) async {
    if (userId.isEmpty || merchantId.isEmpty) {
      return const Right<AppFailure, bool>(false);
    }
    try {
      final doc = await _followedRef(userId).doc(merchantId).get();
      return Right<AppFailure, bool>(doc.exists);
    } on FirebaseException catch (e, st) {
      LoggerService.logError('Firebase error checking follow state', error: e, stackTrace: st);
      return const Right<AppFailure, bool>(false);
    } catch (e, st) {
      LoggerService.logError('Error checking follow state', error: e, stackTrace: st);
      return const Right<AppFailure, bool>(false);
    }
  }
}
