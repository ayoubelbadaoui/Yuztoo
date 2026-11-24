import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/utils/city_match.dart';

void main() {
  group('CityMatch.key', () {
    test('ignores case, accents, hyphens and apostrophes', () {
      expect(CityMatch.key('Châtenois-les-Forges'),
          CityMatch.key('chatenois les forges'));
      expect(CityMatch.key("Fêche-l'Église"), CityMatch.key('FECHE L EGLISE'));
      expect(CityMatch.key('  Belfort '), 'belfort');
      expect(CityMatch.key('Héricourt'), 'hericourt');
    });

    test('expands St / Ste abbreviations', () {
      expect(CityMatch.key("St-Dizier-l'Évêque"),
          CityMatch.key("Saint-Dizier-l'Évêque"));
      expect(CityMatch.key('Ste Suzanne'), CityMatch.key('Sainte-Suzanne'));
    });

    test('keeps distinct communes distinct', () {
      expect(
          CityMatch.key('Belfort'), isNot(CityMatch.key('Belfort-du-Quercy')));
      expect(CityMatch.key('Lepuix'), isNot(CityMatch.key('Lepuix-Neuf')));
    });
  });

  group('CityMatch.candidateKeys', () {
    test('splits legacy multi-city labels', () {
      expect(CityMatch.candidateKeys('Belfort/ andelnans'),
          containsAll(<String>['belfort', 'andelnans']));
    });

    test('single city yields one key', () {
      expect(CityMatch.candidateKeys('Giromagny'), {'giromagny'});
    });
  });

  // Same cases as functions/src/__tests__/merchant_city_keys_core.test.ts:
  // the app and the sync trigger must store identical `city_keys`.
  group('merchantCityKeys', () {
    test('combines the city label and the official commune name', () {
      expect(merchantCityKeys('hericourt', communeName: 'Héricourt'),
          ['hericourt']);
      expect(merchantCityKeys('Belfort/ andelnans', communeName: 'Andelnans'),
          ['andelnans', 'belfort', 'belfort/ andelnans']);
    });

    test('empty city yields no keys', () {
      expect(merchantCityKeys(''), isEmpty);
    });
  });
}
