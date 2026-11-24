import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import '../../../core/infrastructure/logger_service.dart';
import '../domain/entities/news_photo_engagement.dart';
import '../domain/repositories/news_photo_engagement_repository.dart';

/// Firestore layout:
///
/// ```
/// merchants/{merchantId}/news_photo_stats/{photoId}
///   image_url, likes_count, views_count, updated_at
///
/// merchants/{merchantId}/news_photo_views/{photoId}_{viewerUid}
///   photo_id, viewer_uid, updated_at
///
/// merchants/{merchantId}/news_photo_likes/{photoId}_{viewerUid}
///   photo_id, viewer_uid, created_at
/// ```
class FirestoreNewsPhotoEngagementRepository
    implements NewsPhotoEngagementRepository {
  FirestoreNewsPhotoEngagementRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _stats(String merchantId) =>
      _firestore.collection('merchants/$merchantId/news_photo_stats');

  CollectionReference<Map<String, dynamic>> _views(String merchantId) =>
      _firestore.collection('merchants/$merchantId/news_photo_views');

  CollectionReference<Map<String, dynamic>> _likes(String merchantId) =>
      _firestore.collection('merchants/$merchantId/news_photo_likes');

  @override
  String photoIdForUrl(String imageUrl) {
    final digest = sha256.convert(utf8.encode(imageUrl.trim()));
    return digest.toString().substring(0, 32);
  }

  String _markerId(String photoId, String viewerId) => '${photoId}_$viewerId';

  @override
  Future<Map<String, NewsPhotoEngagement>> getEngagementForUrls({
    required String merchantId,
    required List<String> imageUrls,
    String? viewerId,
  }) async {
    if (merchantId.isEmpty || imageUrls.isEmpty) {
      return const {};
    }

    final out = <String, NewsPhotoEngagement>{};
    try {
      for (final url in imageUrls) {
        if (url.trim().isEmpty) continue;
        final photoId = photoIdForUrl(url);
        final statsSnap = await _stats(merchantId).doc(photoId).get();
        final data = statsSnap.data();
        var likes = 0;
        var views = 0;
        if (data != null) {
          likes = _nonNeg(data['likes_count']);
          views = _nonNeg(data['views_count']);
        }

        var likedByMe = false;
        if (viewerId != null && viewerId.isNotEmpty) {
          final likeSnap =
              await _likes(merchantId).doc(_markerId(photoId, viewerId)).get();
          likedByMe = likeSnap.exists;
        }

        out[url] = NewsPhotoEngagement(
          imageUrl: url,
          likesCount: likes,
          viewsCount: views,
          likedByMe: likedByMe,
        );
      }
    } catch (e, st) {
      LoggerService.logError(
        'Failed to load news photo engagement for merchant=$merchantId',
        error: e,
        stackTrace: st,
      );
    }
    return out;
  }

  @override
  Future<void> recordView({
    required String merchantId,
    required String viewerId,
    required String imageUrl,
  }) async {
    if (merchantId.isEmpty ||
        viewerId.isEmpty ||
        imageUrl.trim().isEmpty ||
        merchantId == viewerId) {
      return;
    }

    final photoId = photoIdForUrl(imageUrl);
    final viewRef = _views(merchantId).doc(_markerId(photoId, viewerId));
    final statsRef = _stats(merchantId).doc(photoId);

    try {
      await _firestore.runTransaction((tx) async {
        final existing = await tx.get(viewRef);
        if (existing.exists) return;

        tx.set(viewRef, {
          'photo_id': photoId,
          'viewer_uid': viewerId,
          'updated_at': FieldValue.serverTimestamp(),
        });
        tx.set(
          statsRef,
          {
            'image_url': imageUrl,
            'views_count': FieldValue.increment(1),
            'likes_count': FieldValue.increment(0),
            'updated_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
    } catch (e, st) {
      LoggerService.logError(
        'Failed to record news photo view merchant=$merchantId',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<bool?> toggleLike({
    required String merchantId,
    required String viewerId,
    required String imageUrl,
  }) async {
    if (merchantId.isEmpty ||
        viewerId.isEmpty ||
        imageUrl.trim().isEmpty ||
        merchantId == viewerId) {
      return null;
    }

    final photoId = photoIdForUrl(imageUrl);
    final likeRef = _likes(merchantId).doc(_markerId(photoId, viewerId));
    final statsRef = _stats(merchantId).doc(photoId);

    try {
      return await _firestore.runTransaction((tx) async {
        final existing = await tx.get(likeRef);
        final statsSnap = await tx.get(statsRef);
        final currentCount = _nonNeg(statsSnap.data()?['likes_count']);

        if (existing.exists) {
          tx.delete(likeRef);
          if (currentCount > 0) {
            tx.set(
              statsRef,
              {
                'image_url': imageUrl,
                'likes_count': FieldValue.increment(-1),
                'updated_at': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
          } else if (!statsSnap.exists) {
            tx.set(
              statsRef,
              {
                'image_url': imageUrl,
                'likes_count': 0,
                'views_count': 0,
                'updated_at': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
          }
          return false;
        }

        tx.set(likeRef, {
          'photo_id': photoId,
          'viewer_uid': viewerId,
          'created_at': FieldValue.serverTimestamp(),
        });
        tx.set(
          statsRef,
          {
            'image_url': imageUrl,
            'likes_count': FieldValue.increment(1),
            'views_count': FieldValue.increment(0),
            'updated_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        return true;
      });
    } catch (e, st) {
      LoggerService.logError(
        'Failed to toggle news photo like merchant=$merchantId',
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
