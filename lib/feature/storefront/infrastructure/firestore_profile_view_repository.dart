import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/infrastructure/logger_service.dart';
import '../domain/entities/profile_view_stats.dart';
import '../domain/repositories/profile_view_repository.dart';

/// Firestore-backed [ProfileViewRepository].
///
/// Storage layout:
///
/// ```
/// merchants/{merchantId}/profile_views/{YYYY-MM-DD}_{viewerUid}
///   - date:        'YYYY-MM-DD'  (string, UTC anchor — keeps day buckets
///                                 stable across timezones)
///   - viewer_uid:  string         (denormalised for Firestore queries
///                                 since path segments aren't queryable)
///   - updated_at:  serverTimestamp
/// ```
///
/// One document per (merchant, viewer, UTC day). Idempotent `set` with
/// `merge: true`: repeated opens by the same viewer on the same UTC day
/// just bump `updated_at` and never inflate the count.
///
/// Reads use Firestore `count()` aggregation: the dashboard pays for one
/// aggregate read per window regardless of how many docs match — cheap
/// even for popular storefronts.
class FirestoreProfileViewRepository implements ProfileViewRepository {
  FirestoreProfileViewRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String merchantId) =>
      _firestore.collection('merchants/$merchantId/profile_views');

  /// `YYYY-MM-DD` formatter for [dateUtc]. Sortable as a string, which is
  /// why we use it for both the document id prefix and the `date` field
  /// — Firestore range queries on this string match calendar days.
  static String formatDateKey(DateTime dateUtc) {
    final y = dateUtc.year.toString().padLeft(4, '0');
    final m = dateUtc.month.toString().padLeft(2, '0');
    final d = dateUtc.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Stable doc id for a (date, viewer) pair. The exact format is mirrored
  /// in the Firestore security rule so the rule can derive the expected
  /// uid from the path segment alone.
  static String docIdFor({required String dateKey, required String viewerId}) =>
      '${dateKey}_$viewerId';

  @override
  Future<void> recordView({
    required String merchantId,
    required String viewerId,
    required DateTime nowUtc,
  }) async {
    if (merchantId.isEmpty || viewerId.isEmpty) return;
    // A merchant previewing their own storefront must not inflate their
    // own metrics — silently skip. Mirrored in the dashboard wiring as a
    // defence in depth (see [profileViewProviders]).
    if (merchantId == viewerId) return;

    final utcMidnight = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
    final dateKey = formatDateKey(utcMidnight);

    try {
      await _collection(merchantId)
          .doc(docIdFor(dateKey: dateKey, viewerId: viewerId))
          .set(
        {
          'date': dateKey,
          'viewer_uid': viewerId,
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e, st) {
      // Best-effort analytics: never propagate.
      LoggerService.logError(
        'Failed to record profile view for merchant=$merchantId',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<ProfileViewStats> getWeeklyStats({
    required String merchantId,
    required DateTime nowUtc,
  }) async {
    if (merchantId.isEmpty) return ProfileViewStats.empty;

    final today = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
    // 7-day window is inclusive of today, so we look back 6 days and
    // include today → 7 distinct days.
    final last7Start = today.subtract(const Duration(days: 6));
    final prev7Start = today.subtract(const Duration(days: 13));
    final prev7End = today.subtract(const Duration(days: 7));

    try {
      final last7 = await _collection(merchantId)
          .where('date', isGreaterThanOrEqualTo: formatDateKey(last7Start))
          .where('date', isLessThanOrEqualTo: formatDateKey(today))
          .count()
          .get();

      final prev7 = await _collection(merchantId)
          .where('date', isGreaterThanOrEqualTo: formatDateKey(prev7Start))
          .where('date', isLessThanOrEqualTo: formatDateKey(prev7End))
          .count()
          .get();

      return ProfileViewStats(
        weeklyViews: last7.count ?? 0,
        previousWeeklyViews: prev7.count ?? 0,
      );
    } catch (e, st) {
      LoggerService.logError(
        'Failed to read profile view stats for merchant=$merchantId',
        error: e,
        stackTrace: st,
      );
      return ProfileViewStats.empty;
    }
  }
}
