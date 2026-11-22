import '../entities/yuztoo_news.dart';

abstract class IYuztooNewsRepository {
  /// Latest active entries visible to [viewerUid], newest
  /// [YuztooNews.publishOn] first.
  ///
  /// Uses dual Firestore queries (live + own preview) so other users'
  /// previews never cause permission failures on the live listener.
  ///
  /// Deliberately returns a small window instead of a single document: the
  /// "is it due yet?" decision is made client-side, so the banner can switch
  /// to the next day's entry without a new query.
  Stream<List<YuztooNews>> watchLatest({int limit, String? viewerUid});
}
