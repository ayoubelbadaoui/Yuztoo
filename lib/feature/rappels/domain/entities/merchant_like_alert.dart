import 'package:equatable/equatable.dart';

/// Where a merchant-facing like alert came from.
enum MerchantLikeSource {
  promotion,
  newsPhoto,
}

/// A single unseen like surfaced on Vos clients › Aperçu.
class MerchantLikeAlert extends Equatable {
  const MerchantLikeAlert({
    required this.markerId,
    required this.source,
    required this.viewerUid,
    required this.targetId,
    required this.createdAt,
    this.displayName,
    this.targetLabel,
  });

  final String markerId;
  final MerchantLikeSource source;
  final String viewerUid;
  final String targetId;
  final DateTime createdAt;
  final String? displayName;

  /// Promo title when [source] is [MerchantLikeSource.promotion]; unused for news.
  final String? targetLabel;

  String get displayLabel {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final uid = viewerUid;
    final tail = uid.length > 8 ? uid.substring(uid.length - 8) : uid;
    return '…$tail';
  }

  /// French subtitle under the liker name.
  String get actionLabel {
    switch (source) {
      case MerchantLikeSource.promotion:
        final title = targetLabel?.trim();
        if (title != null && title.isNotEmpty) {
          return 'a aimé votre promo $title';
        }
        return 'a aimé une promo';
      case MerchantLikeSource.newsPhoto:
        return 'a aimé une actualité';
    }
  }

  @override
  List<Object?> get props => <Object?>[
        markerId,
        source,
        viewerUid,
        targetId,
        createdAt,
        displayName,
        targetLabel,
      ];
}

/// Pure unseen filter + newest-first cap (shared by repo + unit tests).
List<MerchantLikeAlert> filterUnseenMerchantLikeAlerts(
  List<MerchantLikeAlert> all, {
  DateTime? seenAt,
  int limit = 30,
}) {
  final filtered = seenAt == null
      ? List<MerchantLikeAlert>.from(all)
      : all.where((a) => a.createdAt.isAfter(seenAt)).toList();
  filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  if (filtered.length <= limit) return filtered;
  return filtered.sublist(0, limit);
}
