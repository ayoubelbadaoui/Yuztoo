import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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
        expect(req.url.queryParameters['fields'], 'nom');
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
      expect(result,
          ['Châtellerault', 'Saint-Étienne', 'L\'Haÿ-les-Roses']);
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
    test('returns empty list for empty string without hitting HTTP',
        () async {
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
      final repo = repoWith(
          (_) async => throw const SocketException('No network'));
      final result = await repo.search('paris');
      expect(result, isEmpty,
          reason:
              'silent fallback so onboarding never blocks when the user '
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
}
