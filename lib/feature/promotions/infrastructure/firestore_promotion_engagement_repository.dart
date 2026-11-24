import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/infrastructure/logger_service.dart';
import '../domain/entities/promotion_engagement.dart';
import '../domain/repositories/promotion_engagement_repository.dart';

/// Firestore layout:
///
/// ```
/// merchants/{merchantId}/promotion_stats/{promoId}
///   likes_count, updated_at
///
/// merchants/{merchantId}/promotion_likes/{promoId}_{viewerUid}
///   promotion_id, viewer_uid, created_at
/// ```
class FirestorePromotionEngagementRepository
    implements PromotionEngagementRepository {
  FirestorePromotionEngagementRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _stats(String merchantId) =>
      _firestore.collection('merchants/$merchantId/promotion_stats');

  CollectionReference<Map<String, dynamic>> _likes(String merchantId) =>
      _firestore.collection('merchants/$merchantId/promotion_likes');

  String _markerId(String promotionId, String viewerId) =>
      '${promotionId}_$viewerId';

  @override
  Future<Map<String, PromotionEngagement>> getEngagementForPromotions({
    required String merchantId,
    required List<String> promotionIds,
    String? viewerId,
  }) async {
    if (merchantId.isEmpty || promotionIds.isEmpty) {
      return const {};
    }

    final ids = promotionIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();
    if (ids.isEmpty) return const {};

    try {
      final entries = await Future.wait(ids.map((id) async {
        final statsSnap = await _stats(merchantId).doc(id).get();
        final likes = _nonNeg(statsSnap.data()?['likes_count']);

        var likedByMe = false;
        if (viewerId != null && viewerId.isNotEmpty) {
          final likeSnap =
              await _likes(merchantId).doc(_markerId(id, viewerId)).get();
          likedByMe = likeSnap.exists;
        }

        return MapEntry(
          id,
          PromotionEngagement(
            promotionId: id,
            likesCount: likes,
            likedByMe: likedByMe,
          ),
        );
      }));
      return Map<String, PromotionEngagement>.fromEntries(entries);
    } catch (e, st) {
      LoggerService.logError(
        'Failed to load promotion engagement merchant=$merchantId',
        error: e,
        stackTrace: st,
      );
      return const {};
    }
  }

  @override
  Future<bool?> toggleLike({
    required String merchantId,
    required String viewerId,
    required String promotionId,
  }) async {
    if (merchantId.isEmpty ||
        viewerId.isEmpty ||
        promotionId.trim().isEmpty ||
        merchantId == viewerId) {
      return null;
    }

    final likeRef = _likes(merchantId).doc(_markerId(promotionId, viewerId));
    final statsRef = _stats(merchantId).doc(promotionId);

    try {
      return await _firestore.runTransaction((tx) async {
        // All reads before writes (Firestore transaction requirement).
        final existing = await tx.get(likeRef);
        final statsSnap = await tx.get(statsRef);
        final currentCount = _nonNeg(statsSnap.data()?['likes_count']);

        if (existing.exists) {
          tx.delete(likeRef);
          // Never push the counter below 0 (orphan marker / desync).
          if (currentCount > 0) {
            tx.set(
              statsRef,
              {
                'likes_count': FieldValue.increment(-1),
                'updated_at': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
          } else if (!statsSnap.exists) {
            tx.set(
              statsRef,
              {
                'likes_count': 0,
                'updated_at': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
          }
          return false;
        }

        tx.set(likeRef, {
          'promotion_id': promotionId,
          'viewer_uid': viewerId,
          'created_at': FieldValue.serverTimestamp(),
        });
        tx.set(
          statsRef,
          {
            'likes_count': FieldValue.increment(1),
            'updated_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        return true;
      });
    } catch (e, st) {
      LoggerService.logError(
        'Failed to toggle promotion like merchant=$merchantId promo=$promotionId',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  static int _nonNeg(dynamic v) {
    if (v is int) return v < 0 ? 0 : v;
    if (v is num) return v.toInt().clamp(0, 1 << 30);
    return 0;
  }
}
