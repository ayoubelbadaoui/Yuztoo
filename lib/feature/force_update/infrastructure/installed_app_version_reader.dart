import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../domain/force_update_decision.dart';

/// Reads the installed build via [PackageInfo] — automatic detection of
/// whether the binary is below the CRM-published floor.
class InstalledAppVersionReader {
  const InstalledAppVersionReader();

  Future<InstalledAppVersion> read() async {
    final info = await PackageInfo.fromPlatform();
    final build = int.tryParse(info.buildNumber.trim()) ?? 0;
    final isIos = !kIsWeb && Platform.isIOS;
    return InstalledAppVersion(
      buildNumber: build,
      versionName: info.version,
      isIos: isIos,
    );
  }
}
