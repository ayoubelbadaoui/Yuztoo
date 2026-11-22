import 'package:equatable/equatable.dart';

/// Publication gate for one Actu — mirrors CMS / Admin CF `release_status`.
enum YuztooNewsReleaseStatus {
  draft,
  preview,
  live,
}

/// One "Actu YuzToo" entry, authored from the Sales CRM CMS (Admin callables).
///
/// A single Firestore document per day (or per announcement): the client app
/// shows the most recent entry whose [publishOn] date has been reached, so the
/// team can prepare a whole week ahead and let it roll over on its own.
class YuztooNews extends Equatable {
  const YuztooNews({
    required this.id,
    required this.title,
    required this.body,
    required this.publishOn,
    this.imageUrl,
    this.ctaLabel,
    this.ctaUrl,
    this.ctaMerchantId,
    this.releaseStatus = YuztooNewsReleaseStatus.live,
    this.testAccountId,
  });

  final String id;
  final String title;
  final String body;

  /// Date from which this entry becomes the current one.
  final DateTime publishOn;

  final String? imageUrl;

  /// Label of the optional action button; a default is used when absent.
  final String? ctaLabel;

  /// External link opened by the action button.
  final String? ctaUrl;

  /// `merchants/{id}` opened by the action button, when the actu points at a
  /// shop rather than a web page. Takes precedence over [ctaUrl].
  final String? ctaMerchantId;

  /// draft → preview (test UID) → live (everyone). Missing field ≡ live.
  final YuztooNewsReleaseStatus releaseStatus;

  /// When [releaseStatus] is preview, only this Firebase UID may see it.
  final String? testAccountId;

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  bool get opensMerchant => ctaMerchantId != null && ctaMerchantId!.isNotEmpty;

  bool get opensUrl => ctaUrl != null && ctaUrl!.isNotEmpty;

  bool get hasCta => opensMerchant || opensUrl;

  /// Already due at [now] — entries dated in the future stay hidden.
  bool isPublishedAt(DateTime now) => !publishOn.isAfter(now);

  /// Whether [viewerUid] is allowed to see this entry (release gate).
  bool isVisibleTo(String? viewerUid) {
    switch (releaseStatus) {
      case YuztooNewsReleaseStatus.draft:
        return false;
      case YuztooNewsReleaseStatus.live:
        return true;
      case YuztooNewsReleaseStatus.preview:
        return viewerUid != null &&
            viewerUid.isNotEmpty &&
            viewerUid == testAccountId;
    }
  }

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        publishOn,
        imageUrl,
        ctaLabel,
        ctaUrl,
        ctaMerchantId,
        releaseStatus,
        testAccountId,
      ];
}

/// The entry to display at [now]: the most recently published one visible to
/// [viewerUid].
///
/// [entries] is expected newest-first (that is how the repository orders
/// them); future-dated entries are skipped rather than trusted, so a document
/// scheduled for tomorrow never leaks out early.
YuztooNews? selectCurrentYuztooNews(
  List<YuztooNews> entries, {
  required DateTime now,
  String? viewerUid,
}) {
  YuztooNews? best;
  for (final entry in entries) {
    if (!entry.isVisibleTo(viewerUid)) continue;
    if (!entry.isPublishedAt(now)) continue;
    if (best == null || entry.publishOn.isAfter(best.publishOn)) {
      best = entry;
    }
  }
  return best;
}
