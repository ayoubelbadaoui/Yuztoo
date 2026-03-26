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
    try {
      final counts = await _getFollowersCountsWithoutIndex(distinctIds);
      return Right<AppFailure, Map<String, int>>(counts);
    } on FirebaseException catch (_, __) {
      // Keep UI stable even if Firestore rules block global reads.
      return Right<AppFailure, Map<String, int>>(baseCounts);
    } catch (e, st) {
      LoggerService.logError('Error loading followers counts fallback', error: e, stackTrace: st);
      return Right<AppFailure, Map<String, int>>(baseCounts);
    }
  }

  Future<Map<String, int>> _getFollowersCountsWithoutIndex(List<String> merchantIds) async {
    final wanted = merchantIds.toSet();
    final counts = <String, int>{for (final id in merchantIds) id: 0};
    final usersSnap = await _firestore.collection('users').get();
    for (final userDoc in usersSnap.docs) {
      final followedSnap = await userDoc.reference.collection('followed_merchants').get();
      for (final followedDoc in followedSnap.docs) {
        final merchantId = followedDoc.id;
        if (wanted.contains(merchantId)) {
          counts[merchantId] = (counts[merchantId] ?? 0) + 1;
        }
      }
    }
    return counts;
  }
}
