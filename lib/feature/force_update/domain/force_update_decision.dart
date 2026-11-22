import 'entities/force_update_config.dart';

/// Installed app identity used for the force-update comparison.
class InstalledAppVersion {
  const InstalledAppVersion({
    required this.buildNumber,
    required this.versionName,
    required this.isIos,
  });

  /// Integer from PackageInfo.buildNumber (pubspec `+N`).
  final int buildNumber;

  /// Marketing version (pubspec before `+`), for display only.
  final String versionName;

  final bool isIos;
}

/// Outcome of comparing [ForceUpdateConfig] with the installed build.
class ForceUpdateDecision {
  const ForceUpdateDecision({
    required this.required,
    required this.config,
    required this.installed,
    required this.platformMinBuild,
    required this.storeUrl,
  });

  final bool required;
  final ForceUpdateConfig config;
  final InstalledAppVersion installed;
  final int platformMinBuild;
  final String storeUrl;

  String get messageFr {
    final custom = config.messageFr?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    return 'Une nouvelle version de Yuztoo est disponible. '
        'Merci de mettre à jour l\'application pour continuer.';
  }
}

/// Pure gate: CRM [force] flag + installed build vs platform min.
///
/// Detection is automatic on the device — CRM only publishes the floor
/// build numbers after a store release is approved.
ForceUpdateDecision evaluateForceUpdate({
  required ForceUpdateConfig config,
  required InstalledAppVersion installed,
}) {
  final min =
      installed.isIos ? config.iosMinBuild : config.androidMinBuild;
  final needs =
      config.force && installed.buildNumber > 0 && installed.buildNumber < min;
  return ForceUpdateDecision(
    required: needs,
    config: config,
    installed: installed,
    platformMinBuild: min,
    storeUrl: config.resolveStoreUrl(isIos: installed.isIos),
  );
}
