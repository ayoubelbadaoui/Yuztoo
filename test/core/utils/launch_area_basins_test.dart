import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/infrastructure/city_catalog_repository.dart';
import 'package:flutter_yuztoo/core/utils/city_match.dart';
import 'package:flutter_yuztoo/core/utils/launch_area_basins.dart';

void main() {
  group('launch_area_basins', () {
    test('Pays d\'Héricourt EPCI is bundled', () {
      final peers = bundledCommunesForEpci('247000722');
      expect(peers, contains('Héricourt'));
      expect(peers.length, 23);
      expect(bundledCommuneEpciCode[CityMatch.key('Héricourt')], '247000722');
      expect(bundledCommuneEpciCode[CityMatch.key('Brevilliers')], '247000722');
    });

    test('PMA EPCI is bundled', () {
      final peers = bundledCommunesForEpci('200065647');
      expect(peers, contains('Montbéliard'));
      expect(peers.length, 73);
      expect(
        bundledCommuneEpciCode[CityMatch.key('Audincourt')],
        '200065647',
      );
    });

    test('bundledMatches attaches epciCode for Héricourt', () {
      final matches = CityCatalogRepository.bundledMatches('Héricourt');
      expect(matches, isNotEmpty);
      expect(matches.first.departmentCode, '70');
      expect(matches.first.epciCode, '247000722');
    });
  });
}
