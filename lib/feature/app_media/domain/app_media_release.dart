enum AppMediaReleaseStatus { draft, preview, live }

/// Publication gate for remote app images (Firestore `app_config/app_media_release`).
class AppMediaRelease {
  const AppMediaRelease({
    required this.status,
    this.testAccountId,
    this.testAccountKind,
    this.testAccountLabel,
    this.previewActivatedAt,
    this.liveAt,
  });

  final AppMediaReleaseStatus status;
  final String? testAccountId;
  final String? testAccountKind;
  final String? testAccountLabel;
  final DateTime? previewActivatedAt;
  final DateTime? liveAt;

  static const draft = AppMediaRelease(status: AppMediaReleaseStatus.draft);

  /// Whether [uid] may load catalog URLs / Storage objects.
  bool allowsUser(String? uid) {
    switch (status) {
      case AppMediaReleaseStatus.draft:
        return false;
      case AppMediaReleaseStatus.preview:
        return uid != null && uid == testAccountId;
      case AppMediaReleaseStatus.live:
        return true;
    }
  }
}
