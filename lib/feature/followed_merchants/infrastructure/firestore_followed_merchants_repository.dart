import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/infrastructure/logger_service.dart';
import '../../rappels/infrastructure/firestore_rappels_pending_client_repository.dart';
import '../domain/repositories/followed_merchants_repository.dart';

/// Firestore: users/{userId}/followed_merchants/{merchantId}
/// with { followed_at: timestamp, heart_level: 0..3 }.
class FirestoreFollowedMerchantsRepository implements FollowedMerchantsRepository {
  FirestoreFollowedMerchantsRepository({
    required FirebaseFirestore firestore,
    required FirestoreRappelsPendingClientRepository pendingClientRepo,
  })  : _firestore = firestore,
        _pendingClientRepo = pendingClientRepo;

  final FirebaseFirestore _firestore;
  final FirestoreRappelsPendingClientRepository _pendingClientRepo;

  CollectionReference<Map<String, dynamic>> _followedRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('followed_merchants');

  @override
  Future<Result<Unit>> add(String userId, String merchantId) async {
    if (userId.isEmpty || merchantId.isEmpty) {
      return const Left<AppFailure, Unit>(
        UnexpectedFailure(message: 'Identifiant utilisateur et identifiant commerce requis'),
      );
    }
    try {
      await _followedRef(userId).doc(merchantId).set({
        'followed_at': FieldValue.serverTimestamp(),
        'heart_level': 1,
        'merchant_id': merchantId,
      });
      LoggerService.logInfo('Followed merchant added', context: {'userId': userId, 'merchantId': merchantId});
      // Side effects must not block the client UI (Découvrir / carnet refresh).
      unawaited(_runFollowSideEffects(merchantId: merchantId, userId: userId));
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

  Future<void> _runFollowSideEffects({
    required String merchantId,
    required String userId,
  }) async {
    try {
      await _pendingClientRepo.writePendingClient(merchantId, userId);
      await _incrementMerchantMonthlyCounter(
        merchantId: merchantId,
        counterField: 'rappels_monthly_connected_clients',
        ymField: 'rappels_monthly_connected_ym',
      );
    } catch (e, st) {
      LoggerService.logError(
        'Follow side effects failed (non-blocking)',
        error: e,
        stackTrace: st,
        context: {'userId': userId, 'merchantId': merchantId},
      );
    }
  }

  /// Increments a monthly counter on the merchant document.
  /// If the stored year-month differs from the current one, the counter is reset
  /// to 1 instead of being incremented (first event of the new month).
  Future<void> _incrementMerchantMonthlyCounter({
    required String merchantId,
    required String counterField,
    required String ymField,
  }) async {
    final now = DateTime.now();
    final currentYm =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final merchantRef =
        _firestore.collection('merchants').doc(merchantId);
    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(merchantRef);
        final storedYm = snap.data()?[ymField] as String?;
        final newCount = storedYm == currentYm
            ? FieldValue.increment(1)
            : 1;
        tx.set(
          merchantRef,
          {counterField: newCount, ymField: currentYm},
          SetOptions(merge: true),
        );
      });
    } catch (e) {
      // Best-effort — never crash the app for a stats counter.
      LoggerService.logError('incrementMerchantMonthlyCounter', error: e);
    }
  }

  @override
  Future<Result<Unit>> remove(String userId, String merchantId) async {
    if (userId.isEmpty || merchantId.isEmpty) {
      return const Right<AppFailure, Unit>(unit);
    }
    try {
      await _followedRef(userId).doc(merchantId).delete();
      // Clean up any pending notification for the merchant.
      await _pendingClientRepo.removePendingClient(merchantId, userId);
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
        UnexpectedFailure(message: 'Identifiant utilisateur et identifiant commerce requis'),
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
  Future<Result<bool>> getMuteState(String userId, String merchantId) async {
    if (userId.isEmpty || merchantId.isEmpty) {
      return const Right<AppFailure, bool>(false);
    }
    try {
      final doc = await _followedRef(userId).doc(merchantId).get();
      final muted = doc.data()?['is_muted'] as bool? ?? false;
      return Right<AppFailure, bool>(muted);
    } catch (_) {
      return const Right<AppFailure, bool>(false);
    }
  }

  @override
  Future<Result<Unit>> setMuteState(
      String userId, String merchantId, {required bool muted}) async {
    if (userId.isEmpty || merchantId.isEmpty) {
      return const Left<AppFailure, Unit>(
        UnexpectedFailure(message: 'Identifiants requis'),
      );
    }
    try {
      await _followedRef(userId).doc(merchantId).set(
        {'is_muted': muted, 'merchant_id': merchantId},
        SetOptions(merge: true),
      );
      return const Right<AppFailure, Unit>(unit);
    } on FirebaseException catch (e, st) {
      return Left<AppFailure, Unit>(
        UnexpectedFailure(
            message: 'Impossible de modifier les notifications', cause: e, stackTrace: st),
      );
    } catch (e, st) {
      return Left<AppFailure, Unit>(
        UnexpectedFailure(message: 'Erreur', cause: e, stackTrace: st),
      );
    }
  }

  @override
  Future<Result<Set<String>>> getMutedMerchantIds(String userId) async {
    if (userId.isEmpty) {
      return const Right<AppFailure, Set<String>>(<String>{});
    }
    try {
      final snapshot = await _followedRef(userId)
          .where('is_muted', isEqualTo: true)
          .get();
      final ids = snapshot.docs.map((d) => d.id).toSet();
      return Right<AppFailure, Set<String>>(ids);
    } on FirebaseException catch (e, st) {
      LoggerService.logError('Firebase error loading muted merchants', error: e, stackTrace: st);
      return const Right<AppFailure, Set<String>>(<String>{});
    } catch (e, st) {
      LoggerService.logError('Error loading muted merchants', error: e, stackTrace: st);
      return const Right<AppFailure, Set<String>>(<String>{});
    }
  }

  @override
  Future<Result<Map<String, int>>> getFollowersCounts(
      List<String> merchantIds) async {
    if (merchantIds.isEmpty) {
      return const Right<AppFailure, Map<String, int>>(<String, int>{});
    }
    final distinctIds = merchantIds.toSet().toList();
    final counts = <String, int>{for (final id in distinctIds) id: 0};

    try {
      // For each merchant, run the same collection-group query used by
      // [getFollowerIds] but only count the results via Firestore's
      // server-side `count()` aggregation — no document payload transferred,
      // which keeps the storefront badge snappy. The query is covered by the
      // existing collectionGroup=followed_merchants, merchant_id ASC index.
      await Future.wait(distinctIds.map((id) async {
        try {
          final agg = await _firestore
              .collectionGroup('followed_merchants')
              .where('merchant_id', isEqualTo: id)
              .count()
              .get();
          counts[id] = agg.count ?? 0;
        } on FirebaseException catch (e, st) {
          LoggerService.logError(
            'Follower count query failed for merchant',
            error: e,
            stackTrace: st,
            context: {'merchantId': id, 'code': e.code},
          );
          // Leave the entry at 0 rather than failing the whole batch.
        }
      }));

      return Right<AppFailure, Map<String, int>>(counts);
    } catch (e, st) {
      LoggerService.logError(
        'Error loading follower counts batch',
        error: e,
        stackTrace: st,
      );
      return Right<AppFailure, Map<String, int>>(counts);
    }
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

  @override
  Future<Result<Map<String, int>>> getFollowedSortIndexes(String userId) async {
    if (userId.isEmpty) {
      return const Right<AppFailure, Map<String, int>>(<String, int>{});
    }
    try {
      final snap = await _followedRef(userId).get();
      final result = <String, int>{};
      for (final doc in snap.docs) {
        final idx = doc.data()['sort_index'];
        if (idx is int) result[doc.id] = idx;
      }
      return Right<AppFailure, Map<String, int>>(result);
    } catch (e, st) {
      LoggerService.logError('Error loading carnet sort indexes', error: e, stackTrace: st);
      return const Right<AppFailure, Map<String, int>>(<String, int>{});
    }
  }

  @override
  Future<Result<Unit>> updateSortOrder(
      String userId, Map<String, int> sortIndexes) async {
    if (userId.isEmpty || sortIndexes.isEmpty) {
      return const Right<AppFailure, Unit>(unit);
    }
    try {
      final batch = _firestore.batch();
      sortIndexes.forEach((merchantId, index) {
        // Merge so reorder succeeds even if the followed doc is missing
        // fields or was created on another device (update() would fail).
        batch.set(
          _followedRef(userId).doc(merchantId),
          {
            'sort_index': index,
            'merchant_id': merchantId,
          },
          SetOptions(merge: true),
        );
      });
      await batch.commit();
      return const Right<AppFailure, Unit>(unit);
    } on FirebaseException catch (e, st) {
      LoggerService.logError('Firebase error saving carnet order', error: e, stackTrace: st);
      return Left<AppFailure, Unit>(
        UnexpectedFailure(message: 'Impossible de sauvegarder l\'ordre', cause: e, stackTrace: st),
      );
    } catch (e, st) {
      LoggerService.logError('Error saving carnet order', error: e, stackTrace: st);
      return Left<AppFailure, Unit>(
        UnexpectedFailure(message: 'Erreur de sauvegarde de l\'ordre', cause: e, stackTrace: st),
      );
    }
  }
}
