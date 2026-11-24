import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/entities/french_commune.dart';
import 'package:flutter_yuztoo/core/infrastructure/city_catalog_repository.dart';
import 'package:flutter_yuztoo/feature/discovery/domain/city_agglomeration_expander.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  CityCatalogRepository catalogWith(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    return CityCatalogRepository(
      httpClient: MockClient((req) async => handler(req)),
    );
  }

  group('CityAgglomerationExpander.expandCityFilters', () {
    test('Giromagny expands to Belfort + department peers', () async {
      final catalog = catalogWith((req) async {
        final path = req.url.path;
        final params = req.url.queryParameters;
        if (params['nom'] == 'Giromagny') {
          return http.Response(
            '''[{"nom":"Giromagny","code":"90052","codeDepartement":"90","codeEpci":"200069060","population":2907}]''',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (path == '/departements/90/communes') {
          return http.Response(
            '''[{"nom":"Giromagny"},{"nom":"Belfort"},{"nom":"Petit-Croix"},{"nom":"Delle"}]''',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('[]', 200);
      });

      final expander = CityAgglomerationExpander(catalog: catalog);
      final expanded = await expander.expandCityFilters(['Giromagny']);

      expect(expanded.first, 'Giromagny');
      expect(expanded, containsAll(['Belfort', 'Petit-Croix', 'Delle']));
    });

    test('Petit-Croix expands to Belfort + department peers', () async {
      final catalog = catalogWith((req) async {
        final path = req.url.path;
        final params = req.url.queryParameters;
        if (params['nom'] == 'Petit-Croix') {
          return http.Response(
            '''[{"nom":"Petit-Croix","code":"90077","codeDepartement":"90","codeEpci":"200069052","population":308}]''',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (path == '/departements/90/communes') {
          return http.Response(
            '''[{"nom":"Petit-Croix"},{"nom":"Belfort"},{"nom":"Bavilliers"},{"nom":"Giromagny"}]''',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('[]', 200);
      });

      final expander = CityAgglomerationExpander(catalog: catalog);
      final expanded = await expander.expandCityFilters(['Petit-Croix']);

      expect(expanded.first, 'Petit-Croix');
      expect(expanded, containsAll(['Belfort', 'Bavilliers', 'Giromagny']));
    });

    test('Belfort expands to include Petit-Croix, not Belfort-du-Quercy',
        () async {
      final catalog = catalogWith((req) async {
        final path = req.url.path;
        final params = req.url.queryParameters;
        if (params['nom'] == 'Belfort') {
          return http.Response(
            '''[
              {"nom":"Belfort","code":"90010","codeDepartement":"90","codeEpci":"200069052","population":46000},
              {"nom":"Belfort-du-Quercy","code":"46023","codeDepartement":"46","codeEpci":"244600532","population":500}
            ]''',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (path == '/departements/90/communes') {
          return http.Response(
            '''[{"nom":"Belfort"},{"nom":"Petit-Croix"}]''',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('[]', 200);
      });

      final expander = CityAgglomerationExpander(catalog: catalog);
      final expanded = await expander.expandCityFilters(['Belfort']);

      expect(expanded, contains('Petit-Croix'));
      expect(expanded, isNot(contains('Belfort-du-Quercy')));
    });

    test('unresolvable city stays exact-only', () async {
      final catalog = catalogWith((_) async => http.Response('[]', 200));
      final expander = CityAgglomerationExpander(catalog: catalog);
      final expanded = await expander.expandCityFilters(['VilleInconnueXYZ']);
      expect(expanded, ['VilleInconnueXYZ']);
    });

    test('multi-city unions both départements', () async {
      final catalog = catalogWith((req) async {
        final path = req.url.path;
        final params = req.url.queryParameters;
        if (params['nom'] == 'Petit-Croix') {
          return http.Response(
            '''[{"nom":"Petit-Croix","code":"90077","codeEpci":"200069052","codeDepartement":"90"}]''',
            200,
          );
        }
        if (params['nom'] == 'Lyon') {
          return http.Response(
            '''[{"nom":"Lyon","code":"69123","codeEpci":"200046977","codeDepartement":"69"}]''',
            200,
          );
        }
        if (path == '/departements/90/communes') {
          return http.Response(
            '''[{"nom":"Petit-Croix"},{"nom":"Belfort"}]''',
            200,
          );
        }
        if (params['codeEpci'] == '200046977' && params['offset'] == '0') {
          return http.Response(
            '''[{"nom":"Lyon"},{"nom":"Villeurbanne"}]''',
            200,
          );
        }
        return http.Response('[]', 200);
      });

      final expander = CityAgglomerationExpander(catalog: catalog);
      final expanded =
          await expander.expandCityFilters(['Petit-Croix', 'Lyon']);

      expect(
        expanded,
        containsAll(['Petit-Croix', 'Lyon', 'Belfort', 'Villeurbanne']),
      );
    });

    test('Héricourt and Montbéliard: own EPCI only, never Belfort or each other',
        () async {
      final catalog = catalogWith((req) async {
        final params = req.url.queryParameters;
        if (params['nom'] == 'Héricourt') {
          return http.Response(
            '''[{"nom":"Héricourt","code":"70285","codeEpci":"247000623","codeDepartement":"70","population":10500}]''',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (params['nom'] == 'Montbéliard') {
          return http.Response(
            '''[{"nom":"Montbéliard","code":"25388","codeEpci":"200065647","codeDepartement":"25","population":25000}]''',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (params['offset'] == '0' && params['codeEpci'] == '247000623') {
          return http.Response(
            '''[{"nom":"Héricourt"},{"nom":"Brevilliers"},{"nom":"Chenebier"}]''',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (params['offset'] == '0' && params['codeEpci'] == '200065647') {
          return http.Response(
            '''[{"nom":"Montbéliard"},{"nom":"Audincourt"},{"nom":"Sochaux"}]''',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        // Département lists (70 / 25) must not be used.
        if (req.url.path.startsWith('/departements/')) {
          return http.Response(
            '''[{"nom":"Belfort"},{"nom":"Besançon"},{"nom":"Vesoul"}]''',
            200,
          );
        }
        return http.Response('[]', 200);
      });

      final expander = CityAgglomerationExpander(catalog: catalog);
      final hericourt = await expander.expandCityFilters(['Héricourt']);
      expect(hericourt, ['Héricourt', 'Brevilliers', 'Chenebier']);

      final montbeliard = await expander.expandCityFilters(['Montbéliard']);
      expect(montbeliard, ['Montbéliard', 'Audincourt', 'Sochaux']);
    });

    test('uses knownMetadata department without re-resolving name', () async {
      var nameLookups = 0;
      final catalog = catalogWith((req) async {
        final path = req.url.path;
        final params = req.url.queryParameters;
        if (params.containsKey('nom')) {
          nameLookups++;
          return http.Response('[]', 200);
        }
        if (path == '/departements/90/communes') {
          return http.Response(
            '''[{"nom":"Petit-Croix"},{"nom":"Belfort"},{"nom":"Giromagny"}]''',
            200,
          );
        }
        return http.Response('[]', 200);
      });

      final expander = CityAgglomerationExpander(catalog: catalog);
      final expanded = await expander.expandCityFilters(
        ['Petit-Croix'],
        knownMetadata: {
          'Petit-Croix': const FrenchCommune(
            name: 'Petit-Croix',
            inseeCode: '90077',
            departmentCode: '90',
            epciCode: '200069052',
          ),
        },
      );

      expect(nameLookups, 0);
      expect(expanded, containsAll(['Belfort', 'Giromagny']));
    });
  });

  group('CityAgglomerationExpander robustness', () {
    http.Response json(String body) => http.Response(
          body,
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );

    test('legacy "Belfort/ andelnans" label expands like Belfort', () async {
      final catalog = catalogWith((req) async {
        final params = req.url.queryParameters;
        if (params['nom'] == 'Belfort') {
          return json(
              '[{"nom":"Belfort","code":"90010","codeDepartement":"90"}]');
        }
        if (req.url.path == '/departements/90/communes') {
          return json(
              '[{"nom":"Belfort"},{"nom":"Andelnans"},{"nom":"Delle"}]');
        }
        return json('[]');
      });
      final expanded = await CityAgglomerationExpander(catalog: catalog)
          .expandCityFilters(['Belfort/ andelnans']);
      expect(expanded, containsAll(['Belfort', 'andelnans', 'Delle']));
    });

    test('uses stored department code without a search call', () async {
      var searches = 0;
      final catalog = catalogWith((req) async {
        if (req.url.queryParameters.containsKey('nom')) searches++;
        if (req.url.path == '/departements/90/communes') {
          return json('[{"nom":"Giromagny"},{"nom":"Belfort"}]');
        }
        return json('[]');
      });
      final expanded =
          await CityAgglomerationExpander(catalog: catalog).expandCityFilters([
        'Giromagny'
      ], knownMetadata: {
        'Giromagny':
            const FrenchCommune(name: 'Giromagny', departmentCode: '90'),
      });
      expect(expanded, contains('Belfort'));
      expect(searches, 0);
    });

    test('hanging geo API falls back to bundled département communes', () async {
      final catalog = catalogWith((req) => Completer<http.Response>().future);
      final sw = Stopwatch()..start();
      final expanded = await CityAgglomerationExpander(catalog: catalog)
          .expandCityFilters(['Belfort', 'Giromagny']);
      sw.stop();
      // Connected cities first, then the bundled Territoire de Belfort list.
      expect(expanded.take(2), ['Belfort', 'Giromagny']);
      expect(expanded, containsAll(['Delle', 'Danjoutin', 'Petit-Croix']));
      // Parallel + bounded: well under 2 × per-city timeout.
      expect(
          sw.elapsed, lessThan(CityAgglomerationExpander.perCityTimeout * 1.5));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('offline Héricourt expands via bundled Pays d\'Héricourt EPCI',
        () async {
      final catalog = catalogWith((req) => Completer<http.Response>().future);
      final expanded = await CityAgglomerationExpander(catalog: catalog)
          .expandCityFilters(['Héricourt']);
      expect(expanded.first, 'Héricourt');
      expect(expanded, containsAll(['Brevilliers', 'Chenebier', 'Couthenans']));
      expect(expanded, isNot(contains('Belfort')));
      expect(expanded, isNot(contains('Montbéliard')));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('offline Montbéliard expands via bundled PMA EPCI', () async {
      final catalog = catalogWith((req) => Completer<http.Response>().future);
      final expanded = await CityAgglomerationExpander(catalog: catalog)
          .expandCityFilters(['Montbéliard']);
      expect(expanded.first, 'Montbéliard');
      expect(expanded, containsAll(['Audincourt', 'Sochaux', 'Valentigney']));
      expect(expanded, isNot(contains('Belfort')));
      expect(expanded, isNot(contains('Héricourt')));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('saved department list is used when the API is down', () async {
      SharedPreferences.setMockInitialValues({});
      final online = CityCatalogRepository(
        persistDepartmentLists: true,
        httpClient: MockClient(
            (req) async => json('[{"nom":"Belfort"},{"nom":"Giromagny"}]')),
      );
      expect(await online.communeNamesForDepartment('25'),
          ['Belfort', 'Giromagny']);
      await Future<void>.delayed(Duration.zero);

      final offline = CityCatalogRepository(
        persistDepartmentLists: true,
        httpClient:
            MockClient((req) async => throw http.ClientException('off')),
      );
      expect(await offline.communeNamesForDepartment('25'),
          ['Belfort', 'Giromagny']);
    });
  });
}
