import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/force_update/infrastructure/firestore_force_update_repository.dart';

void main() {
  group('FirestoreForceUpdateRepository.configFromMap', () {
    test('maps a complete document', () {
      final config = FirestoreForceUpdateRepository.configFromMap({
        'force': true,
        'android_min_build': 70,
        'ios_min_build': 71,
        'message_fr': 'Update now',
        'android_store_url': 'https://play.google.com/store/apps/details?id=x',
        'ios_store_url': 'https://apps.apple.com/app/id1',
      });
      expect(config.force, isTrue);
      expect(config.androidMinBuild, 70);
      expect(config.iosMinBuild, 71);
      expect(config.messageFr, 'Update now');
      expect(config.androidStoreUrl, startsWith('https://play.google.com'));
      expect(config.iosStoreUrl, startsWith('https://apps.apple.com'));
    });

    test('treats missing / invalid fields as safe defaults', () {
      final config = FirestoreForceUpdateRepository.configFromMap({
        'force': 'yes',
        'android_min_build': '-3',
        'ios_min_build': 4.2,
      });
      expect(config.force, isFalse);
      expect(config.androidMinBuild, 0);
      expect(config.iosMinBuild, 4);
      expect(config.messageFr, isNull);
    });

    test('parses numeric strings for build floors', () {
      final config = FirestoreForceUpdateRepository.configFromMap({
        'force': true,
        'android_min_build': '88',
        'ios_min_build': '89',
      });
      expect(config.androidMinBuild, 88);
      expect(config.iosMinBuild, 89);
    });
  });
}
