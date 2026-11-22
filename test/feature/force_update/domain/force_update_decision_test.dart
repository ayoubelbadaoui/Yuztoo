import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/force_update/domain/entities/force_update_config.dart';
import 'package:flutter_yuztoo/feature/force_update/domain/force_update_decision.dart';

void main() {
  const androidInstalled = InstalledAppVersion(
    buildNumber: 66,
    versionName: '1.0.8',
    isIos: false,
  );
  const iosInstalled = InstalledAppVersion(
    buildNumber: 66,
    versionName: '1.0.8',
    isIos: true,
  );

  group('evaluateForceUpdate', () {
    test('does not block when force is off even if build is old', () {
      const config = ForceUpdateConfig(
        force: false,
        androidMinBuild: 100,
        iosMinBuild: 100,
      );
      expect(
        evaluateForceUpdate(config: config, installed: androidInstalled)
            .required,
        isFalse,
      );
    });

    test('blocks Android when installed build is below min', () {
      const config = ForceUpdateConfig(
        force: true,
        androidMinBuild: 67,
        iosMinBuild: 1,
      );
      final d =
          evaluateForceUpdate(config: config, installed: androidInstalled);
      expect(d.required, isTrue);
      expect(d.platformMinBuild, 67);
      expect(d.storeUrl, ForceUpdateConfig.defaultAndroidStoreUrl);
    });

    test('allows Android when installed build equals min', () {
      const config = ForceUpdateConfig(
        force: true,
        androidMinBuild: 66,
        iosMinBuild: 999,
      );
      expect(
        evaluateForceUpdate(config: config, installed: androidInstalled)
            .required,
        isFalse,
      );
    });

    test('allows Android when installed build is above min', () {
      const config = ForceUpdateConfig(
        force: true,
        androidMinBuild: 50,
        iosMinBuild: 999,
      );
      expect(
        evaluateForceUpdate(config: config, installed: androidInstalled)
            .required,
        isFalse,
      );
    });

    test('uses ios_min_build on iOS and custom store URL', () {
      const config = ForceUpdateConfig(
        force: true,
        androidMinBuild: 1,
        iosMinBuild: 70,
        iosStoreUrl: 'https://apps.apple.com/app/id123',
      );
      final d = evaluateForceUpdate(config: config, installed: iosInstalled);
      expect(d.required, isTrue);
      expect(d.platformMinBuild, 70);
      expect(d.storeUrl, 'https://apps.apple.com/app/id123');
    });

    test('does not block when buildNumber is unreadable (0)', () {
      const broken = InstalledAppVersion(
        buildNumber: 0,
        versionName: '?',
        isIos: false,
      );
      const config = ForceUpdateConfig(
        force: true,
        androidMinBuild: 1,
        iosMinBuild: 1,
      );
      expect(
        evaluateForceUpdate(config: config, installed: broken).required,
        isFalse,
      );
    });

    test('uses custom French message when provided', () {
      const config = ForceUpdateConfig(
        force: true,
        androidMinBuild: 100,
        iosMinBuild: 100,
        messageFr: '  Mise à jour obligatoire.  ',
      );
      expect(
        evaluateForceUpdate(config: config, installed: androidInstalled)
            .messageFr,
        'Mise à jour obligatoire.',
      );
    });
  });

  group('ForceUpdateConfig.resolveStoreUrl', () {
    test('falls back to Play Store package URL', () {
      expect(
        ForceUpdateConfig.disabled.resolveStoreUrl(isIos: false),
        ForceUpdateConfig.defaultAndroidStoreUrl,
      );
    });
  });
}
