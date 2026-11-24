import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/domain/core/either.dart';
import '../../../core/domain/core/failure.dart';
import '../../../core/domain/core/result.dart';
import '../../../core/infrastructure/logger_service.dart';
import '../domain/entities/merchant_like_alert.dart';
import '../domain/repositories/i_merchant_like_alerts_repository.dart';

/// Firestore implementation for merchant like alerts on Aperçu.
class FirestoreMerchantLikeAlertsRepository
    implements IMerchantLikeAlertsRepository {
  FirestoreMerchantLikeAlertsRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const int _fetchPerSource = 30;
  static const int _unseenCap = 30;
  static const String _seenAtField = 'likes_alerts_seen_at';

  CollectionReference<Map<String, dynamic>> _promoLikes(String merchantId) =>
      _firestore.collection('merchants/$merchantId/promotion_likes');

  CollectionReference<Map<String, dynamic>> _newsLikes(String merchantId) =>
      _firestore.collection('merchants/$merchantId/news_photo_likes');

  DocumentReference<Map<String, dynamic>> _merchant(String merchantId) =>
      _firestore.collection('merchants').doc(merchantId);

  @override
  Stream<List<MerchantLikeAlert>> watchUnseenLikeAlerts(String merchantId) {
    if (merchantId.isEmpty) {
      return Stream<List<MerchantLikeAlert>>.value(<MerchantLikeAlert>[]);
    }

    final controller = StreamController<List<MerchantLikeAlert>>();
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? promoDocs;
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? newsDocs;
    DateTime? seenAt;
    var merchantReady = false;
    var emitting = false;
    var pending = false;

    Future<void> emit() async {
      if (!merchantReady || promoDocs == null || newsDocs == null) return;
      if (emitting) {
        pending = true;
        return;
      }
      emitting = true;
      try {
        do {
          pending = false;
          final raw = <MerchantLikeAlert>[
            ..._mapPromoDocs(promoDocs!),
            ..._mapNewsDocs(newsDocs!),
          ];
          final filtered = filterUnseenMerchantLikeAlerts(
            raw,
            seenAt: seenAt,
            limit: _unseenCap,
          );
          final enriched = await _enrich(merchantId, filtered);
          if (!controller.isClosed) {
            controller.add(enriched);
          }
        } while (pending && !controller.isClosed);
      } catch (e, st) {
        LoggerService.logError(
          'Failed to emit merchant like alerts merchant=$merchantId',
          error: e,
          stackTrace: st,
        );
        if (!controller.isClosed) {
          controller.add(<MerchantLikeAlert>[]);
        }
      } finally {
        emitting = false;
      }
    }

    final subs = <StreamSubscription<dynamic>>[
      _merchant(merchantId).snapshots().listen((snap) {
        final ts = snap.data()?[_seenAtField];
        seenAt = ts is Timestamp ? ts.toDate() : null;
        merchantReady = true;
        unawaited(emit());
      }),
      _promoLikes(merchantId)
          .orderBy('created_at', descending: true)
          .limit(_fetchPerSource)
          .snapshots()
          .listen((snap) {
        promoDocs = snap.docs;
        unawaited(emit());
      }),
      _newsLikes(merchantId)
          .orderBy('created_at', descending: true)
          .limit(_fetchPerSource)
          .snapshots()
          .listen((snap) {
        newsDocs = snap.docs;
        unawaited(emit());
      }),
    ];

    controller.onCancel = () async {
      for (final sub in subs) {
        await sub.cancel();
      }
    };

    return controller.stream;
  }

  @override
  Future<Result<Unit>> markAllSeen(String merchantId) async {
    if (merchantId.isEmpty) {
      return const Left<AppFailure, Unit>(
        UnexpectedFailure(message: 'Merchant id requis'),
      );
    }
    try {
      await _merchant(merchantId).set(
        <String, dynamic>{
          _seenAtField: FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return const Right<AppFailure, Unit>(unit);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Failed to mark like alerts seen merchant=$merchantId',
        error: e,
        stackTrace: st,
      );
      return Left<AppFailure, Unit>(
        UnexpectedFailure(
          message: 'Impossible de marquer les likes comme vus',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      LoggerService.logError(
        'Failed to mark like alerts seen merchant=$merchantId',
        error: e,
        stackTrace: st,
      );
      return Left<AppFailure, Unit>(
        UnexpectedFailure(
          message: 'Impossible de marquer les likes comme vus',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  List<MerchantLikeAlert> _mapPromoDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final out = <MerchantLikeAlert>[];
    for (final doc in docs) {
      final data = doc.data();
      final created = _readCreatedAt(data['created_at']);
      if (created == null) continue;
      final viewerUid = (data['viewer_uid'] as String?)?.trim() ?? '';
      final targetId = (data['promotion_id'] as String?)?.trim() ?? '';
      if (viewerUid.isEmpty || targetId.isEmpty) continue;
      out.add(
        MerchantLikeAlert(
          markerId: doc.id,
          source: MerchantLikeSource.promotion,
          viewerUid: viewerUid,
          targetId: targetId,
          createdAt: created,
        ),
      );
    }
    return out;
  }

  List<MerchantLikeAlert> _mapNewsDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final out = <MerchantLikeAlert>[];
    for (final doc in docs) {
      final data = doc.data();
      final created = _readCreatedAt(data['created_at']);
      if (created == null) continue;
      final viewerUid = (data['viewer_uid'] as String?)?.trim() ?? '';
      final targetId = (data['photo_id'] as String?)?.trim() ?? '';
      if (viewerUid.isEmpty || targetId.isEmpty) continue;
      out.add(
        MerchantLikeAlert(
          markerId: doc.id,
          source: MerchantLikeSource.newsPhoto,
          viewerUid: viewerUid,
          targetId: targetId,
          createdAt: created,
        ),
      );
    }
    return out;
  }

  Future<List<MerchantLikeAlert>> _enrich(
    String merchantId,
    List<MerchantLikeAlert> alerts,
  ) async {
    if (alerts.isEmpty) return alerts;

    final viewerIds = alerts.map((a) => a.viewerUid).toSet();
    final promoIds = alerts
        .where((a) => a.source == MerchantLikeSource.promotion)
        .map((a) => a.targetId)
        .toSet();

    final names = <String, String?>{};
    await Future.wait(viewerIds.map((uid) async {
      try {
        final snap = await _firestore.collection('users').doc(uid).get();
        names[uid] = snap.data()?['displayName'] as String?;
      } catch (_) {
        names[uid] = null;
      }
    }));

    final titles = <String, String?>{};
    await Future.wait(promoIds.map((promoId) async {
      try {
        final snap = await _firestore
            .collection('merchants/$merchantId/promotions')
            .doc(promoId)
            .get();
        titles[promoId] = snap.data()?['title'] as String?;
      } catch (_) {
        titles[promoId] = null;
      }
    }));

    return alerts
        .map(
          (a) => MerchantLikeAlert(
            markerId: a.markerId,
            source: a.source,
            viewerUid: a.viewerUid,
            targetId: a.targetId,
            createdAt: a.createdAt,
            displayName: names[a.viewerUid],
            targetLabel: a.source == MerchantLikeSource.promotion
                ? titles[a.targetId]
                : null,
          ),
        )
        .toList();
  }

  static DateTime? _readCreatedAt(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
