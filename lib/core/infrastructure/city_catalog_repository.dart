import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Hybrid city catalog: the public French government commune API
/// ([geo.api.gouv.fr]) for live, population-boosted results, with the
/// bundled `frenchCities` list as the offline fallback.
///
/// Why an API rather than a bundled dataset:
///   - Real coverage is ~35 000 communes — far too large to ship as a
///     static Dart list.
///   - The free API is public, no auth, no rate limit on small queries,
///     and supports a `boost=population` flag so the most useful results
///     come first.
///   - When the network fails (or the API is down), we silently fall
///     back to the bundled list so onboarding never blocks.
///
/// Query semantics (one network call per typed query):
///   GET https://geo.api.gouv.fr/communes
///       ?nom=<query>&boost=population&limit=<limit>&fields=nom
///   → JSON array of `{"nom": "..."}`.
///
/// Returns names only — postal-code / INSEE-code lookups are out of scope
/// for v1 (the merchant doc only stores the display name today).
class CityCatalogRepository {
  CityCatalogRepository({
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 5),
  })  : _httpClient = httpClient ?? http.Client(),
        _timeout = timeout;

  final http.Client _httpClient;
  final Duration _timeout;

  static final Uri _baseUri = Uri.https('geo.api.gouv.fr', '/communes');

  /// Returns up to [limit] commune names matching [query], ordered with
  /// the most populous first. Empty / whitespace queries return an empty
  /// list (the caller is expected to render the static fallback).
  ///
  /// Returns an empty list (rather than throwing) on network / parsing
  /// errors — the caller distinguishes "no API result" from "API
  /// unreachable" via [searchOrThrow] when it needs to.
  Future<List<String>> search(
    String query, {
    int limit = 20,
  }) async {
    try {
      return await searchOrThrow(query, limit: limit);
    } on _CityCatalogException {
      return const <String>[];
    } on SocketException {
      return const <String>[];
    } on TimeoutException {
      return const <String>[];
    } on http.ClientException {
      return const <String>[];
    } on FormatException {
      return const <String>[];
    }
  }

  /// Variant of [search] that surfaces network / parsing errors so tests
  /// (and any future telemetry) can distinguish them. Production UI uses
  /// the silent [search].
  Future<List<String>> searchOrThrow(
    String query, {
    int limit = 20,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const <String>[];
    if (limit <= 0) return const <String>[];

    final uri = _baseUri.replace(queryParameters: <String, String>{
      'nom': trimmed,
      'boost': 'population',
      'limit': '$limit',
      'fields': 'nom',
    });

    final response = await _httpClient.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw _CityCatalogException(
        'API returned ${response.statusCode}',
      );
    }

    // Decode UTF-8 explicitly — the API returns French accents and the
    // default `response.body` getter may use Latin-1 if no charset header
    // is present.
    final body = utf8.decode(response.bodyBytes, allowMalformed: true);
    final decoded = jsonDecode(body);
    if (decoded is! List) {
      throw const _CityCatalogException('Unexpected JSON shape');
    }

    // Preserve API order (population-boosted) but dedupe — the API can
    // return the same `nom` for arrondissements (Paris 1er, Paris 2e, …)
    // collapsed to "Paris" depending on flags.
    final seen = <String>{};
    final result = <String>[];
    for (final entry in decoded) {
      if (entry is! Map<String, dynamic>) continue;
      final nom = entry['nom'];
      if (nom is! String) continue;
      final clean = nom.trim();
      if (clean.isEmpty) continue;
      if (seen.add(clean.toLowerCase())) {
        result.add(clean);
      }
    }
    return result;
  }

  /// Best-effort cleanup for tests / hot reload.
  void close() => _httpClient.close();
}

/// Internal exception so we don't leak HTTP types up the public API.
class _CityCatalogException implements Exception {
  const _CityCatalogException(this.message);
  final String message;
  @override
  String toString() => 'CityCatalogException: $message';
}
