import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/french_commune.dart';
import '../utils/city_match.dart';
import '../utils/launch_area_basins.dart';
import '../utils/local_area_cities.dart';

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
///       ?nom=<query>&boost=population&limit=<limit>
///       &fields=nom,code,codesPostaux,population,codeDepartement,
///               codeRegion,codeEpci,centre
class CityCatalogRepository {
  CityCatalogRepository({
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 5),
    bool persistDepartmentLists = false,
  })  : _httpClient = httpClient ?? http.Client(),
        _timeout = timeout,
        _persistDepartmentLists = persistDepartmentLists;

  final http.Client _httpClient;
  final Duration _timeout;

  /// When true, département commune lists are saved on device so Découvrir
  /// keeps its village ↔ ville linking offline / when the geo API is down,
  /// and opens without a network round-trip while the copy is fresh.
  final bool _persistDepartmentLists;
  static const Duration _departmentListMaxAge = Duration(days: 14);
  static String _departmentPrefsKey(String code) =>
      'geo_dept_communes_v1_$code';

  static final Uri _baseUri = Uri.https('geo.api.gouv.fr', '/communes');
  final Map<String, String?> _epciNameCache = <String, String?>{};
  final Map<String, FrenchCommune?> _resolveByNameCache =
      <String, FrenchCommune?>{};
  final Map<String, List<String>> _epciCommunesCache = <String, List<String>>{};
  final Map<String, List<String>> _departmentCommunesCache =
      <String, List<String>>{};

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
    final communes = await searchCommunes(query, limit: limit);
    return communes.map((commune) => commune.name).toList(growable: false);
  }

  /// Returns full official commune records. Same-name communes are preserved
  /// and disambiguated by their INSEE, postal and department data.
  Future<List<FrenchCommune>> searchCommunes(
    String query, {
    int limit = 20,
  }) async {
    try {
      return await searchCommunesOrThrow(query, limit: limit);
    } on _CityCatalogException {
      return const <FrenchCommune>[];
    } on SocketException {
      return const <FrenchCommune>[];
    } on TimeoutException {
      return const <FrenchCommune>[];
    } on http.ClientException {
      return const <FrenchCommune>[];
    } on FormatException {
      return const <FrenchCommune>[];
    }
  }

  /// Variant of [search] that surfaces network / parsing errors so tests
  /// (and any future telemetry) can distinguish them. Production UI uses
  /// the silent [search].
  Future<List<String>> searchOrThrow(
    String query, {
    int limit = 20,
  }) async {
    final communes = await searchCommunesOrThrow(query, limit: limit);
    return communes.map((commune) => commune.name).toList(growable: false);
  }

  Future<List<FrenchCommune>> searchCommunesOrThrow(
    String query, {
    int limit = 20,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const <FrenchCommune>[];
    if (limit <= 0) return const <FrenchCommune>[];

    final uri = _baseUri.replace(queryParameters: <String, String>{
      'nom': trimmed,
      'boost': 'population',
      'limit': '$limit',
      'fields': 'nom,code,codesPostaux,population,codeDepartement,'
          'codeRegion,codeEpci,centre',
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

    // Preserve API order (population-boosted). Deduplicate only by official
    // INSEE code: different communes legitimately share the same name.
    final seen = <String>{};
    final result = <FrenchCommune>[];
    for (final entry in decoded) {
      if (entry is! Map<String, dynamic>) continue;
      final commune = _communeFromJson(entry);
      if (commune == null) continue;
      final identity = commune.inseeCode ??
          '${commune.name.toLowerCase()}|${commune.postalCodes.join(',')}';
      if (seen.add(identity)) result.add(commune);
    }
    return result;
  }

  /// Resolves a free-text city label to the best official commune record.
  ///
  /// Prefers an exact name match; when [preferDepartment] is set, prefer a
  /// hit in that department (disambiguates e.g. Belfort vs Belfort-du-Quercy).
  /// Returns null when the API is unreachable or no usable match exists.
  Future<FrenchCommune?> resolveByName(
    String name, {
    String? preferDepartment,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final deptKey = preferDepartment?.trim() ?? '';
    final cacheKey = '${trimmed.toLowerCase()}|$deptKey';
    if (_resolveByNameCache.containsKey(cacheKey)) {
      return _resolveByNameCache[cacheKey];
    }

    final matches = await searchCommunes(trimmed, limit: 10);
    if (matches.isEmpty) {
      // Offline / slow API: bundled launch-area communes (not cached, so the
      // API is tried again next time).
      final bundled = bundledMatches(trimmed);
      if (bundled.isEmpty) return null;
      return bundled.firstWhere(
        (c) => deptKey.isNotEmpty && c.departmentCode == deptKey,
        orElse: () => bundled.first,
      );
    }

    FrenchCommune? exact;
    FrenchCommune? exactInDept;
    for (final match in matches) {
      if (match.name.toLowerCase() != trimmed.toLowerCase()) continue;
      exact ??= match;
      if (deptKey.isNotEmpty && match.departmentCode == deptKey) {
        exactInDept = match;
        break;
      }
    }

    var chosen = exactInDept ?? exact ?? matches.first;
    if (chosen.epciCode != null &&
        chosen.epciCode!.isNotEmpty &&
        (chosen.epciName == null || chosen.epciName!.isEmpty)) {
      final base = chosen;
      // EPCI name is cosmetic metadata — never let it stall a lookup.
      chosen = await resolveDetails(base).timeout(
        const Duration(seconds: 2),
        onTimeout: () => base,
      );
    }

    _resolveByNameCache[cacheKey] = chosen;
    return chosen;
  }

  final Map<String, List<FrenchCommune>> _exactMatchCache =
      <String, List<FrenchCommune>>{};

  /// Every official commune whose name matches [name] exactly (accent / case
  /// / hyphen-insensitive), with its centre coordinates. Several departments
  /// can share a name (Héricourt 70 / 62, Saint-Louis 68 / 974…): callers
  /// pick the relevant one (e.g. the nearest).
  ///
  /// Cached in memory, and on device when [persistDepartmentLists] is set —
  /// commune centres never move, so the saved copy never expires.
  /// Returns an empty list when offline and nothing is cached.
  Future<List<FrenchCommune>> exactMatches(String name) async {
    final key = CityMatch.key(name);
    if (key.isEmpty) return const <FrenchCommune>[];
    final cached = _exactMatchCache[key];
    if (cached != null) return cached;

    final stored = await _readStoredExact(key);
    if (stored != null) {
      _exactMatchCache[key] = stored;
      return stored;
    }

    final inFlight = _exactInFlight[key];
    if (inFlight != null) return inFlight;
    final future = _fetchExact(name.trim(), key);
    _exactInFlight[key] = future;
    try {
      return await future;
    } finally {
      _exactInFlight.remove(key);
    }
  }

  final Map<String, Future<List<FrenchCommune>>> _exactInFlight =
      <String, Future<List<FrenchCommune>>>{};

  Future<List<FrenchCommune>> _fetchExact(String name, String key) async {
    // One retry for fast failures, all within 5 s so callers' 6 s budgets
    // always leave room for the bundled fallback below.
    Future<List<FrenchCommune>> attempts() async {
      var r = const <FrenchCommune>[];
      for (var attempt = 0; attempt < 2 && r.isEmpty; attempt++) {
        r = await searchCommunes(name, limit: 20);
      }
      return r;
    }

    final results = await attempts().timeout(
      const Duration(seconds: 5),
      onTimeout: () => const <FrenchCommune>[],
    );
    var exact = results
        .where((c) =>
            CityMatch.key(c.name) == key &&
            c.latitude != null &&
            c.longitude != null)
        .toList(growable: false);
    if (exact.isEmpty) {
      // API down / too slow: launch-area communes are bundled.
      final bundled = bundledMatches(name);
      if (bundled.isNotEmpty) return bundled; // not persisted: retry API later
    }
    if (exact.isNotEmpty) {
      _exactMatchCache[key] = exact;
      unawaited(_storeExact(key, exact));
    }
    return exact;
  }

  static String _exactPrefsKey(String key) => 'geo_exact_v1_$key';

  Future<List<FrenchCommune>?> _readStoredExact(String key) async {
    if (!_persistDepartmentLists) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_exactPrefsKey(key));
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! List || decoded.isEmpty) return null;
      return decoded
          .whereType<Map>()
          .map((m) => FrenchCommune.fromFirestore(Map<String, dynamic>.from(m)))
          .where((c) => c.latitude != null && c.longitude != null)
          .toList(growable: false);
    } on Object {
      return null;
    }
  }

  Future<void> _storeExact(String key, List<FrenchCommune> communes) async {
    if (!_persistDepartmentLists) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _exactPrefsKey(key),
        jsonEncode(communes.map((c) => c.toFirestore()).toList()),
      );
    } on Object {
      // Best effort.
    }
  }

  /// All commune display names belonging to [epciCode] (official EPCI).
  ///
  /// Live geo.api.gouv.fr first; on failure / empty, falls back to the
  /// bundled launch-area EPCI lists so Découvrir never collapses to
  /// exact-match-only for Héricourt / Montbéliard. Results are cached
  /// in-memory for the lifetime of this repository instance.
  Future<List<String>> communeNamesForEpci(String epciCode) async {
    final code = epciCode.trim();
    if (code.isEmpty) return const <String>[];
    if (_epciCommunesCache.containsKey(code)) {
      return _epciCommunesCache[code]!;
    }

    try {
      final names = await _fetchAllCommuneNamesForEpci(code);
      if (names.isNotEmpty) {
        _epciCommunesCache[code] = names;
        return names;
      }
    } on _CityCatalogException {
      // Fall through to bundled.
    } on SocketException {
      // Fall through to bundled.
    } on TimeoutException {
      // Fall through to bundled.
    } on http.ClientException {
      // Fall through to bundled.
    } on FormatException {
      // Fall through to bundled.
    }

    final bundled = bundledCommunesForEpci(code);
    if (bundled.isNotEmpty) {
      _epciCommunesCache[code] = bundled;
      return bundled;
    }
    return const <String>[];
  }

  /// All commune display names in [departmentCode] (e.g. `"90"`).
  ///
  /// Returns an empty list on network / parsing errors. Results are cached
  /// in-memory for the lifetime of this repository instance.
  Future<List<String>> communeNamesForDepartment(String departmentCode) async {
    final code = departmentCode.trim();
    if (code.isEmpty) return const <String>[];
    if (_departmentCommunesCache.containsKey(code)) {
      return _departmentCommunesCache[code]!;
    }

    // Territoire de Belfort is bundled in full (101 communes): no network.
    if (_completeBundledDepartments.contains(code)) {
      final bundled = bundledDepartment(code);
      _departmentCommunesCache[code] = bundled;
      return bundled;
    }

    final stored = await _readStoredDepartment(code);
    if (stored != null && stored.fresh) {
      _departmentCommunesCache[code] = stored.names;
      return stored.names;
    }

    try {
      final names = await _fetchAllCommuneNamesForDepartment(code);
      if (names.isNotEmpty) {
        _departmentCommunesCache[code] = names;
        unawaited(_storeDepartment(code, names));
      }
      return names;
    } on Object catch (e) {
      if (e is! _CityCatalogException &&
          e is! SocketException &&
          e is! TimeoutException &&
          e is! http.ClientException &&
          e is! FormatException) {
        rethrow;
      }
      // Offline / API down: a stale saved list beats exact-match only.
      if (stored != null) {
        _departmentCommunesCache[code] = stored.names;
        return stored.names;
      }
      // Never fetched on this device: bundled launch-area list (complete for
      // Territoire de Belfort 90; the 35 km ring for 25 / 70 / 68).
      return bundledDepartment(code);
    }
  }

  /// Départements whose commune list is bundled completely.
  static const Set<String> _completeBundledDepartments = <String>{'90'};

  /// Bundled communes matching [name] exactly (accent-insensitive).
  /// Attaches launch-area [epciCode] when known so offline expand can still
  /// resolve Pays d'Héricourt / PMA peers.
  static List<FrenchCommune> bundledMatches(String name) {
    final key = CityMatch.key(name);
    if (key.isEmpty) return const <FrenchCommune>[];
    return [
      for (final c in localAreaCommunes)
        if (CityMatch.key(c.$1) == key)
          FrenchCommune(
            name: c.$1,
            departmentCode: c.$2,
            epciCode: bundledCommuneEpciCode[CityMatch.key(c.$1)],
            latitude: c.$3,
            longitude: c.$4,
          ),
    ];
  }

  /// Bundled commune names of département [code].
  static List<String> bundledDepartment(String code) =>
      List<String>.unmodifiable([
        for (final c in localAreaCommunes)
          if (c.$2 == code) c.$1,
      ]);

  Future<({List<String> names, bool fresh})?> _readStoredDepartment(
    String code,
  ) async {
    if (!_persistDepartmentLists) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_departmentPrefsKey(code));
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final names = decoded['names'];
      final savedAt = decoded['saved_at'];
      if (names is! List || savedAt is! int) return null;
      final list = List<String>.unmodifiable(names.whereType<String>());
      if (list.isEmpty) return null;
      final age = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(savedAt));
      return (names: list, fresh: age < _departmentListMaxAge);
    } on Object {
      return null;
    }
  }

  Future<void> _storeDepartment(String code, List<String> names) async {
    if (!_persistDepartmentLists) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _departmentPrefsKey(code),
        jsonEncode(<String, Object>{
          'names': names,
          'saved_at': DateTime.now().millisecondsSinceEpoch,
        }),
      );
    } on Object {
      // Best effort — in-memory cache still serves this session.
    }
  }

  Future<List<String>> _fetchAllCommuneNamesForEpci(String epciCode) async {
    // geo.api.gouv.fr paginates with limit/offset; Grand Belfort ≈ 52,
    // Métropole du Grand Paris is larger — page until exhausted.
    const pageSize = 100;
    final names = <String>[];
    final seen = <String>{};
    var offset = 0;

    while (true) {
      final uri = _baseUri.replace(queryParameters: <String, String>{
        'codeEpci': epciCode,
        'fields': 'nom',
        'limit': '$pageSize',
        'offset': '$offset',
      });
      final response = await _httpClient.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        throw _CityCatalogException('API returned ${response.statusCode}');
      }
      final body = utf8.decode(response.bodyBytes, allowMalformed: true);
      final decoded = jsonDecode(body);
      if (decoded is! List) {
        throw const _CityCatalogException('Unexpected JSON shape');
      }
      if (decoded.isEmpty) break;

      for (final entry in decoded) {
        if (entry is! Map) continue;
        final nom = entry['nom'];
        if (nom is! String || nom.trim().isEmpty) continue;
        final clean = nom.trim();
        if (seen.add(clean.toLowerCase())) names.add(clean);
      }

      if (decoded.length < pageSize) break;
      offset += pageSize;
      // Safety bound so a buggy API cannot loop forever.
      if (offset >= 5000) break;
    }

    return List<String>.unmodifiable(names);
  }

  Future<List<String>> _fetchAllCommuneNamesForDepartment(
    String departmentCode,
  ) async {
    // /departements/{code}/communes returns the full list in one response
    // (e.g. Nord ≈ 647). No client-side pagination needed.
    final uri = Uri.https(
      'geo.api.gouv.fr',
      '/departements/$departmentCode/communes',
      <String, String>{'fields': 'nom'},
    );
    final response = await _httpClient.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw _CityCatalogException('API returned ${response.statusCode}');
    }
    final body = utf8.decode(response.bodyBytes, allowMalformed: true);
    final decoded = jsonDecode(body);
    if (decoded is! List) {
      throw const _CityCatalogException('Unexpected JSON shape');
    }

    final names = <String>[];
    final seen = <String>{};
    for (final entry in decoded) {
      if (entry is! Map) continue;
      final nom = entry['nom'];
      if (nom is! String || nom.trim().isEmpty) continue;
      final clean = nom.trim();
      if (seen.add(clean.toLowerCase())) names.add(clean);
    }

    return List<String>.unmodifiable(names);
  }

  /// Resolves a fallback display name to an official record, then adds the
  /// official EPCI name. Failures return the original record so onboarding
  /// remains usable offline.
  Future<FrenchCommune> resolveDetails(FrenchCommune commune) async {
    var resolved = commune;
    if (resolved.inseeCode == null) {
      final matches = await searchCommunes(commune.name, limit: 10);
      for (final match in matches) {
        if (match.name.toLowerCase() == commune.name.toLowerCase()) {
          resolved = match;
          break;
        }
      }
    }

    final epciCode = resolved.epciCode;
    if (epciCode == null || epciCode.isEmpty) return resolved;
    if (_epciNameCache.containsKey(epciCode)) {
      return resolved.copyWith(epciName: _epciNameCache[epciCode]);
    }

    try {
      final uri = Uri.https('geo.api.gouv.fr', '/epcis/$epciCode');
      final response = await _httpClient.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return resolved;
      final body = utf8.decode(response.bodyBytes, allowMalformed: true);
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return resolved;
      final name = decoded['nom'];
      final cleanName =
          name is String && name.trim().isNotEmpty ? name.trim() : null;
      _epciNameCache[epciCode] = cleanName;
      return resolved.copyWith(epciName: cleanName);
    } on Object {
      return resolved;
    }
  }

  static FrenchCommune? _communeFromJson(Map<String, dynamic> json) {
    final rawName = json['nom'];
    if (rawName is! String || rawName.trim().isEmpty) return null;

    final rawPostalCodes = json['codesPostaux'];
    final postalCodes = rawPostalCodes is List
        ? rawPostalCodes.whereType<String>().toList(growable: false)
        : const <String>[];
    final rawPopulation = json['population'];
    final population = rawPopulation is num ? rawPopulation.toInt() : null;

    double? longitude;
    double? latitude;
    final centre = json['centre'];
    if (centre is Map) {
      final coordinates = centre['coordinates'];
      if (coordinates is List && coordinates.length >= 2) {
        final rawLongitude = coordinates[0];
        final rawLatitude = coordinates[1];
        if (rawLongitude is num && rawLatitude is num) {
          longitude = rawLongitude.toDouble();
          latitude = rawLatitude.toDouble();
        }
      }
    }

    String? optionalString(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) return null;
      return value.trim();
    }

    return FrenchCommune(
      name: rawName.trim(),
      inseeCode: optionalString('code'),
      postalCodes: postalCodes,
      population: population,
      departmentCode: optionalString('codeDepartement'),
      regionCode: optionalString('codeRegion'),
      epciCode: optionalString('codeEpci'),
      longitude: longitude,
      latitude: latitude,
    );
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
