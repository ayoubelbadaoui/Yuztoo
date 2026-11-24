import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_yuztoo/core/domain/entities/french_commune.dart';
import 'package:flutter_yuztoo/core/infrastructure/city_catalog_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CityCatalogRepository — covers the parsing happy path and every defensive
// branch (HTTP failure, malformed JSON, network errors, dedup of repeated
// commune names, empty/whitespace queries, UTF-8 accents).
//
// We use http's `MockClient` so no actual network calls are made — tests
// stay fast and deterministic.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  /// Builds a repo whose HTTP client returns whatever [handler] computes.
  CityCatalogRepository repoWith(
    Future<http.Response> Function(http.Request request) handler, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    return CityCatalogRepository(
      httpClient: MockClient((req) async => handler(req)),
      timeout: timeout,
    );
  }

  group('search — happy path', () {
    test('parses commune names and preserves API order', () async {
      final repo = repoWith((req) async {
        // Sanity: query string must contain the user's input verbatim.
        expect(req.url.queryParameters['nom'], 'paris');
        expect(req.url.queryParameters['boost'], 'population');
        expect(
          req.url.queryParameters['fields'],
          'nom,code,codesPostaux,population,codeDepartement,'
          'codeRegion,codeEpci,centre',
        );
        return http.Response(
          jsonEncode([
            {'nom': 'Paris'},
            {'nom': 'Parisot'},
            {'nom': 'Parigny'},
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final result = await repo.search('paris');
      expect(result, ['Paris', 'Parisot', 'Parigny']);
    });

    test('decodes UTF-8 accents correctly', () async {
      final repo = repoWith((req) async {
        // Return the body as raw bytes encoded in UTF-8 so we exercise the
        // explicit utf8.decode path in the repo.
        final body = jsonEncode([
          {'nom': 'Châtellerault'},
          {'nom': 'Saint-Étienne'},
          {'nom': 'L\'Haÿ-les-Roses'},
        ]);
        return http.Response.bytes(
          utf8.encode(body),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await repo.search('saint');
      expect(result, ['Châtellerault', 'Saint-Étienne', 'L\'Haÿ-les-Roses']);
    });

    test('dedupes repeated commune names case-insensitively', () async {
      final repo = repoWith((_) async => http.Response(
            jsonEncode([
              {'nom': 'Paris'},
              {'nom': 'PARIS'},
              {'nom': 'paris'},
              {'nom': 'Parigny'},
            ]),
            200,
          ));
      final result = await repo.search('paris');
      // Keep the FIRST occurrence verbatim (canonical casing from API).
      expect(result, ['Paris', 'Parigny']);
    });

    test('preserves same-name communes with distinct INSEE codes', () async {
      final repo = repoWith((_) async => http.Response(
            jsonEncode([
              {
                'nom': 'Saint-Denis',
                'code': '93066',
                'codesPostaux': ['93200'],
                'population': 149077,
                'codeDepartement': '93',
                'codeRegion': '11',
                'codeEpci': '200054781',
                'centre': {
                  'coordinates': [2.3657, 48.9378],
                },
              },
              {
                'nom': 'Saint-Denis',
                'code': '97411',
                'codesPostaux': ['97400'],
                'population': 155634,
                'codeDepartement': '974',
              },
            ]),
            200,
          ));

      final result = await repo.searchCommunes('Saint-Denis');

      expect(result, hasLength(2));
      expect(result.map((item) => item.inseeCode), ['93066', '97411']);
      expect(result.first.postalCodes, ['93200']);
      expect(result.first.epciCode, '200054781');
      expect(result.first.longitude, 2.3657);
      expect(result.first.latitude, 48.9378);
      expect(result.first.size.label, 'Grande ville');
    });

    test('skips entries that lack a usable "nom"', () async {
      final repo = repoWith((_) async => http.Response(
            jsonEncode([
              {'nom': 'Lyon'},
              {'code': '69123'}, // no nom — drop
              {'nom': ''}, // empty — drop
              {'nom': '   '}, // whitespace — drop
              'not a map', // bad shape — drop
              {'nom': 'Lyon-2e-Arrondissement'},
            ]),
            200,
          ));
      final result = await repo.search('lyon');
      expect(result, ['Lyon', 'Lyon-2e-Arrondissement']);
    });
  });

  group('search — empty / no-op queries', () {
    test('returns empty list for empty string without hitting HTTP', () async {
      var called = false;
      final repo = repoWith((_) async {
        called = true;
        return http.Response('[]', 200);
      });
      final result = await repo.search('');
      expect(result, isEmpty);
      expect(called, isFalse,
          reason: 'must not waste a request on an empty query');
    });

    test('returns empty list for whitespace-only string', () async {
      var called = false;
      final repo = repoWith((_) async {
        called = true;
        return http.Response('[]', 200);
      });
      final result = await repo.search('   \t \n  ');
      expect(result, isEmpty);
      expect(called, isFalse);
    });

    test('returns empty list when limit is non-positive', () async {
      var called = false;
      final repo = repoWith((_) async {
        called = true;
        return http.Response('[]', 200);
      });
      final result = await repo.search('paris', limit: 0);
      expect(result, isEmpty);
      expect(called, isFalse);
    });
  });

  group('search — error handling', () {
    test('returns empty list when API responds 500', () async {
      final repo = repoWith((_) async => http.Response('boom', 500));
      final result = await repo.search('paris');
      expect(result, isEmpty);
    });

    test('returns empty list when JSON shape is unexpected', () async {
      final repo = repoWith((_) async => http.Response(
            jsonEncode({'not': 'an array'}),
            200,
          ));
      final result = await repo.search('paris');
      expect(result, isEmpty);
    });

    test('returns empty list on malformed JSON', () async {
      final repo = repoWith((_) async => http.Response('not-json', 200));
      final result = await repo.search('paris');
      expect(result, isEmpty);
    });

    test('returns empty list on SocketException (offline)', () async {
      final repo =
          repoWith((_) async => throw const SocketException('No network'));
      final result = await repo.search('paris');
      expect(result, isEmpty,
          reason: 'silent fallback so onboarding never blocks when the user '
              'is offline');
    });

    test('returns empty list on TimeoutException', () async {
      final repo = repoWith(
        (_) async {
          // Never completes within the (very short) timeout below.
          await Future<void>.delayed(const Duration(seconds: 5));
          return http.Response('[]', 200);
        },
        timeout: const Duration(milliseconds: 10),
      );
      final result = await repo.search('paris');
      expect(result, isEmpty);
    });
  });

  group('searchOrThrow — surfaces errors for telemetry', () {
    test('throws on non-200 response', () async {
      final repo = repoWith((_) async => http.Response('bad', 503));
      expect(repo.searchOrThrow('paris'), throwsA(isA<Exception>()));
    });

    test('returns empty list on empty query without throwing', () async {
      final repo = repoWith((_) async => http.Response('[]', 200));
      final result = await repo.searchOrThrow('');
      expect(result, isEmpty);
    });
  });

  test('commune size thresholds are derived from official population', () {
    expect(
      const FrenchCommune(name: 'A', population: 1999).size,
      FrenchCommuneSize.village,
    );
    expect(
      const FrenchCommune(name: 'B', population: 2000).size,
      FrenchCommuneSize.smallTown,
    );
    expect(
      const FrenchCommune(name: 'C', population: 20000).size,
      FrenchCommuneSize.city,
    );
    expect(
      const FrenchCommune(name: 'D', population: 100000).size,
      FrenchCommuneSize.largeCity,
    );
  });

  test('resolveDetails enriches and caches the official EPCI name', () async {
    var epciRequests = 0;
    final repo = repoWith((request) async {
      expect(request.url.path, '/epcis/200054781');
      epciRequests++;
      return http.Response.bytes(
        utf8.encode(jsonEncode({
          'nom': 'Métropole du Grand Paris',
          'code': '200054781',
        })),
        200,
      );
    });
    const commune = FrenchCommune(
      name: 'Saint-Denis',
      inseeCode: '93066',
      epciCode: '200054781',
    );

    final first = await repo.resolveDetails(commune);
    final second = await repo.resolveDetails(commune);

    expect(first.epciName, 'Métropole du Grand Paris');
    expect(second.epciName, 'Métropole du Grand Paris');
    expect(epciRequests, 1);
  });

  group('resolveByName', () {
    test('prefers exact match in preferred department', () async {
      final repo = repoWith((_) async => http.Response(
            jsonEncode([
              {
                'nom': 'Belfort',
                'code': '90010',
                'codeDepartement': '90',
                'codeEpci': '200069052',
                'population': 46000,
              },
              {
                'nom': 'Belfort-du-Quercy',
                'code': '46023',
                'codeDepartement': '46',
                'codeEpci': '244600532',
                'population': 500,
              },
            ]),
            200,
          ));

      final hit = await repo.resolveByName('Belfort', preferDepartment: '90');
      expect(hit?.inseeCode, '90010');
      expect(hit?.epciCode, '200069052');
    });

    test('returns null when API has no matches', () async {
      final repo = repoWith((_) async => http.Response('[]', 200));
      expect(await repo.resolveByName('Nowhere'), isNull);
    });
  });

  group('communeNamesForEpci', () {
    test('returns peer names and caches', () async {
      var calls = 0;
      final repo = repoWith((req) async {
        expect(req.url.queryParameters['codeEpci'], '200069052');
        calls++;
        return http.Response(
          jsonEncode([
            {'nom': 'Belfort'},
            {'nom': 'Petit-Croix'},
          ]),
          200,
        );
      });

      final first = await repo.communeNamesForEpci('200069052');
      final second = await repo.communeNamesForEpci('200069052');
      expect(first, ['Belfort', 'Petit-Croix']);
      expect(second, first);
      expect(calls, 1);
    });
  });

  group('communeNamesForDepartment', () {
    test('Territoire de Belfort (90) is served from the bundle, no network',
        () async {
      var calls = 0;
      final repo = repoWith((req) async {
        calls++;
        return http.Response('[]', 200);
      });
      final names = await repo.communeNamesForDepartment('90');
      expect(names.length, 101);
      expect(names, containsAll(['Belfort', 'Giromagny', 'Delle']));
      expect(calls, 0);
    });

    test('returns peer names and caches', () async {
      var calls = 0;
      final repo = repoWith((req) async {
        expect(req.url.path, '/departements/25/communes');
        calls++;
        return http.Response(
          jsonEncode([
            {'nom': 'Belfort'},
            {'nom': 'Giromagny'},
            {'nom': 'Petit-Croix'},
          ]),
          200,
        );
      });

      // 25: not bundled in full, so the API is used (90 is bundled).
      final first = await repo.communeNamesForDepartment('25');
      final second = await repo.communeNamesForDepartment('25');
      expect(first, ['Belfort', 'Giromagny', 'Petit-Croix']);
      expect(second, first);
      expect(calls, 1);
    });
  });
}
