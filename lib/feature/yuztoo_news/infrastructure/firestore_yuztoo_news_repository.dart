import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/infrastructure/logger_service.dart';
import '../../../core/infrastructure/tolerant_mapping.dart';
import '../domain/entities/yuztoo_news.dart';
import '../domain/repositories/i_yuztoo_news_repository.dart';

/// Firestore layout — authored via Admin CRM callables:
///
/// ```
/// yuztoo_news/{newsId}
///   title / body / publish_on / active / image_url / cta_*
///   release_status     'draft' | 'preview' | 'live'  (missing ≡ live)
///   test_account_id    string?  preview audience UID
///   test_account_label string?
///   preview_activated_at / live_at
/// ```
///
/// Read path uses **two** queries so a foreign preview document cannot make
/// the live listener fail rules evaluation for everyone else.
class FirestoreYuztooNewsRepository implements IYuztooNewsRepository {
  FirestoreYuztooNewsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const String collection = 'yuztoo_news';

  @override
  Stream<List<YuztooNews>> watchLatest({
    int limit = 10,
    String? viewerUid,
  }) {
    final liveQuery = _firestore
        .collection(collection)
        .where('active', isEqualTo: true)
        .where('release_status', isEqualTo: 'live')
        .orderBy('publish_on', descending: true)
        .limit(limit)
        .snapshots();

    final uid = viewerUid?.trim();
    if (uid == null || uid.isEmpty) {
      return liveQuery
          .map(
            (snap) => snap.docs.mapSkippingInvalid(
              _newsFrom,
              label: collection,
            ),
          )
          .handleError(_logWatchError);
    }

    final previewQuery = _firestore
        .collection(collection)
        .where('active', isEqualTo: true)
        .where('release_status', isEqualTo: 'preview')
        .where('test_account_id', isEqualTo: uid)
        .orderBy('publish_on', descending: true)
        .limit(limit)
        .snapshots();

    return _combineLatestNews(liveQuery, previewQuery, limit: limit)
        .handleError(_logWatchError);
  }

  Stream<List<YuztooNews>> _combineLatestNews(
    Stream<QuerySnapshot<Map<String, dynamic>>> live,
    Stream<QuerySnapshot<Map<String, dynamic>>> preview, {
    required int limit,
  }) {
    late StreamController<List<YuztooNews>> controller;
    QuerySnapshot<Map<String, dynamic>>? latestLive;
    QuerySnapshot<Map<String, dynamic>>? latestPreview;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? liveSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? previewSub;

    void emit() {
      if (latestLive == null || latestPreview == null) return;
      final byId = <String, YuztooNews>{};
      for (final doc in [...latestLive!.docs, ...latestPreview!.docs]) {
        try {
          final news = _newsFrom(doc);
          byId[news.id] = news;
        } catch (error, stackTrace) {
          LoggerService.logError(
            'Skipping invalid $collection/${doc.id}',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }
      final merged = byId.values.toList()
        ..sort((a, b) => b.publishOn.compareTo(a.publishOn));
      if (!controller.isClosed) {
        controller.add(merged.take(limit).toList(growable: false));
      }
    }

    controller = StreamController<List<YuztooNews>>(
      onListen: () {
        liveSub = live.listen(
          (snap) {
            latestLive = snap;
            emit();
          },
          onError: controller.addError,
        );
        previewSub = preview.listen(
          (snap) {
            latestPreview = snap;
            emit();
          },
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await liveSub?.cancel();
        await previewSub?.cancel();
      },
    );

    return controller.stream;
  }

  void _logWatchError(Object e, StackTrace st) {
    LoggerService.logError(
      'Failed to watch Yuztoo news',
      error: e,
      stackTrace: st,
    );
  }

  YuztooNews _newsFrom(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final title = (data['title'] as String?)?.trim() ?? '';
    final body = (data['body'] as String?)?.trim() ?? '';
    final publishOn = _parseTimestamp(data['publish_on']);
    if (title.isEmpty || body.isEmpty || publishOn == null) {
      throw const FormatException(
        'yuztoo_news requires title, body and publish_on',
      );
    }
    return YuztooNews(
      id: doc.id,
      title: title,
      body: body,
      publishOn: publishOn,
      imageUrl: _nonEmpty(data['image_url']),
      ctaLabel: _nonEmpty(data['cta_label']),
      ctaUrl: _nonEmpty(data['cta_url']),
      ctaMerchantId: _nonEmpty(data['cta_merchant_id']),
      releaseStatus: _parseReleaseStatus(data['release_status']),
      testAccountId: _nonEmpty(data['test_account_id']),
    );
  }

  static YuztooNewsReleaseStatus _parseReleaseStatus(dynamic raw) {
    switch (raw) {
      case 'draft':
        return YuztooNewsReleaseStatus.draft;
      case 'preview':
        return YuztooNewsReleaseStatus.preview;
      case 'live':
        return YuztooNewsReleaseStatus.live;
      default:
        // Legacy docs without the field behave as live.
        return YuztooNewsReleaseStatus.live;
    }
  }

  static String? _nonEmpty(dynamic raw) {
    final value = raw is String ? raw.trim() : '';
    return value.isEmpty ? null : value;
  }

  static DateTime? _parseTimestamp(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}
