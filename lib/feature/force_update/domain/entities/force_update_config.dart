import 'package:equatable/equatable.dart';

/// Remote gate for mandatory app upgrades.
///
/// Authored only from the Sales CRM CMS (Admin callables →
/// `app_config/force_update`). Clients read it; they never write it.
class ForceUpdateConfig extends Equatable {
  const ForceUpdateConfig({
    required this.force,
    required this.androidMinBuild,
    required this.iosMinBuild,
    this.messageFr,
    this.androidStoreUrl,
    this.iosStoreUrl,
  });

  /// When false the gate is off regardless of min builds.
  final bool force;

  /// Inclusive floor for Android `versionCode` / pubspec `+build`.
  final int androidMinBuild;

  /// Inclusive floor for iOS build number / pubspec `+build`.
  final int iosMinBuild;

  /// Optional French copy on the blocking screen.
  final String? messageFr;

  /// Play Store listing; falls back to the default Yuztoo package URL.
  final String? androidStoreUrl;

  /// App Store listing; falls back to a searchable App Store URL when unset.
  final String? iosStoreUrl;

  static const ForceUpdateConfig disabled = ForceUpdateConfig(
    force: false,
    androidMinBuild: 0,
    iosMinBuild: 0,
  );

  static const String defaultAndroidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.yuztoo.app';

  /// No numeric App Store id is baked into the repo yet — CRM should set
  /// [iosStoreUrl] once the listing exists. This search URL is a last resort.
  static const String defaultIosStoreUrl =
      'https://apps.apple.com/search?term=Yuztoo';

  String resolveStoreUrl({required bool isIos}) {
    if (isIos) {
      final custom = iosStoreUrl?.trim();
      if (custom != null && custom.isNotEmpty) return custom;
      return defaultIosStoreUrl;
    }
    final custom = androidStoreUrl?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    return defaultAndroidStoreUrl;
  }

  @override
  List<Object?> get props => [
        force,
        androidMinBuild,
        iosMinBuild,
        messageFr,
        androidStoreUrl,
        iosStoreUrl,
      ];
}
