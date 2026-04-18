import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/infrastructure/logger_service.dart';
import '../domain/repositories/followed_merchants_repository.dart';

/// Firestore: users/{userId}/followed_merchants/{merchantId}
/// with { followed_at: timestamp, heart_level: 0..3 }.
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
        'heart_level': 1,
        'merchant_id': merchantId,
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

  @override
  Future<Result<Map<String, int>>> getFollowedHeartLevels(String userId) async {
    if (userId.isEmpty) {
      return const Right<AppFailure, Map<String, int>>(<String, int>{});
    }
    try {
      final snapshot = await _followedRef(userId).get();
      final map = <String, int>{};
      for (final doc in snapshot.docs) {
        final raw = doc.data()['heart_level'];
        final level = raw is int ? raw : 1;
        map[doc.id] = level.clamp(0, 3);
      }
      return Right<AppFailure, Map<String, int>>(map);
    } on FirebaseException catch (e, st) {
      LoggerService.logError('Firebase error loading heart levels', error: e, stackTrace: st);
      return Left<AppFailure, Map<String, int>>(
        UnexpectedFailure(message: 'Impossible de charger les favoris', cause: e, stackTrace: st),
      );
    } catch (e, st) {
      LoggerService.logError('Error loading heart levels', error: e, stackTrace: st);
      return Left<AppFailure, Map<String, int>>(
        UnexpectedFailure(message: 'Erreur de chargement', cause: e, stackTrace: st),
      );
    }
  }

  @override
  Future<Result<Unit>> setHeartLevel(String userId, String merchantId, int heartLevel) async {
    if (userId.isEmpty || merchantId.isEmpty) {
      return const Left<AppFailure, Unit>(
        UnexpectedFailure(message: 'User ID and merchant ID are required'),
      );
    }
    final safeLevel = heartLevel.clamp(0, 3);
    try {
      await _followedRef(userId).doc(merchantId).set({
        'heart_level': safeLevel,
        'merchant_id': merchantId,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return const Right<AppFailure, Unit>(unit);
    } on FirebaseException catch (e, st) {
      LoggerService.logError('Firebase error saving heart level', error: e, stackTrace: st);
      return Left<AppFailure, Unit>(
        UnexpectedFailure(message: 'Impossible de sauvegarder le favori', cause: e, stackTrace: st),
      );
    } catch (e, st) {
      LoggerService.logError('Error saving heart level', error: e, stackTrace: st);
      return Left<AppFailure, Unit>(
        UnexpectedFailure(message: 'Erreur lors de la sauvegarde', cause: e, stackTrace: st),
      );
    }
  }

  @override
  Future<Result<Map<String, int>>> getFollowersCounts(List<String> merchantIds) async {
    if (merchantIds.isEmpty) {
      return const Right<AppFailure, Map<String, int>>(<String, int>{});
    }
    final distinctIds = merchantIds.toSet().toList();
    final baseCounts = <String, int>{for (final id in distinctIds) id: 0};
    // Avoid global users scan in client apps: rules usually deny list on /users.
    // Keep UI responsive with a stable fallback until a server-side counter exists.
    return Right<AppFailure, Map<String, int>>(baseCounts);
  }

  @override
  Future<Result<List<String>>> getFollowerIds(String merchantId) async {
    if (merchantId.isEmpty) {
      return const Right<AppFailure, List<String>>([]);
    }
    try {
      // Collection-group query across all users' followed_merchants subcollections.
      // Requires a Firestore index: collectionGroup=followed_merchants, field=merchant_id ASC.
      final snapshot = await _firestore
          .collectionGroup('followed_merchants')
          .where('merchant_id', isEqualTo: merchantId)
          .get();

      // The parent document of each result is the user doc → its ID is the clientId.
      final ids = snapshot.docs
          .map((d) => d.reference.parent.parent?.id)
          .whereType<String>()
          .toList();

      LoggerService.logInfo(
        'Follower IDs loaded for merchant',
        context: {'merchantId': merchantId, 'count': ids.length},
      );
      return Right<AppFailure, List<String>>(ids);
    } on FirebaseException catch (e, st) {
      LoggerService.logError('Firebase error loading follower IDs', error: e, stackTrace: st);
      return Left<AppFailure, List<String>>(
        UnexpectedFailure(
            message: 'Impossible de charger les abonnés', cause: e, stackTrace: st),
      );
    } catch (e, st) {
      LoggerService.logError('Error loading follower IDs', error: e, stackTrace: st);
      return Left<AppFailure, List<String>>(
        UnexpectedFailure(message: 'Erreur de chargement des abonnés', cause: e, stackTrace: st),
      );
    }
  }
}
