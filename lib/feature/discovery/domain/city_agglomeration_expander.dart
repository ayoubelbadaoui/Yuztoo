import '../../../core/domain/entities/french_commune.dart';
import '../../../core/infrastructure/city_catalog_repository.dart';
import '../../../core/utils/city_input.dart';
import '../../../core/utils/city_match.dart';

/// Expands client connected-city labels into the commune names whose shops
/// they see in Découvrir.
///
/// Product contract: `docs/product/DISCOVERY_BASINS.md`
///
/// * Territoire de Belfort (90): the whole département — Giromagny /
///   Petit-Croix / Belfort → all 101 communes (Grand Belfort + Vosges du Sud
///   + Sud Territoire).
/// * Any other département: only the city's own intercommunalité (EPCI) —
///   Héricourt → Pays d'Héricourt villages, Montbéliard → Pays de
///   Montbéliard Agglomération. Héricourt, Montbéliard and Belfort are never
///   linked to each other.
///
/// When the API is offline, bundled launch-area EPCI / département lists keep
/// expansion working; the original label is always kept as a minimum.
class CityAgglomerationExpander {
  CityAgglomerationExpander({required CityCatalogRepository catalog})
      : _catalog = catalog;

  final CityCatalogRepository _catalog;

  /// Upper bound for one city's département lookup (and one peer-list fetch).
  static const Duration perCityTimeout = Duration(seconds: 6);

  /// Départements grouped as a whole (product decision: the Territoire de
  /// Belfort is one local area).
  static const Set<String> wholeDepartments = {'90'};

  Future<({String? department, String? epci})> _codesFor(
    String city,
    Map<String, FrenchCommune>? knownMetadata,
  ) async {
    FrenchCommune? meta;
    if (knownMetadata != null) {
      meta = knownMetadata[city];
      if (meta == null) {
        final key = normalizeCityKey(city);
        for (final entry in knownMetadata.entries) {
          if (normalizeCityKey(entry.key) == key) {
            meta = entry.value;
            break;
          }
        }
      }
    }
    final knownDept = meta?.departmentCode?.trim();
    final knownEpci = meta?.epciCode?.trim();
    if (knownDept != null &&
        knownDept.isNotEmpty &&
        (wholeDepartments.contains(knownDept) ||
            (knownEpci != null && knownEpci.isNotEmpty))) {
      return (department: knownDept, epci: knownEpci);
    }

    final resolved = await _catalog.resolveByName(
      city,
      preferDepartment: knownDept,
    );
    return (
      department: resolved?.departmentCode?.trim() ?? knownDept,
      epci: resolved?.epciCode?.trim() ?? knownEpci,
    );
  }

  static String? _storedDepartment(
    String city,
    Map<String, FrenchCommune>? knownMetadata,
  ) {
    if (knownMetadata == null) return null;
    var meta = knownMetadata[city];
    if (meta == null) {
      final key = normalizeCityKey(city);
      for (final e in knownMetadata.entries) {
        if (normalizeCityKey(e.key) == key) {
          meta = e.value;
          break;
        }
      }
    }
    final dept = meta?.departmentCode?.trim();
    return (dept == null || dept.isEmpty) ? null : dept;
  }

  /// Returns originals ∪ peer commune names (département 90 / EPCI) (deduped, stable
  /// order: originals first, then peers in API order).
  Future<List<String>> expandCityFilters(
    Iterable<String> cities, {
    Map<String, FrenchCommune>? knownMetadata,
  }) async =>
      (await expandArea(cities, knownMetadata: knownMetadata)).names;

  /// [expandCityFilters] plus, per commune name, the département(s) it was
  /// resolved in — so a same-name commune elsewhere (Héricourt 70 vs 62,
  /// Chaux 90 vs 21, Saint-Louis 68 vs 974) can be told apart.
  Future<CityArea> expandArea(
    Iterable<String> cities, {
    Map<String, FrenchCommune>? knownMetadata,
  }) async {
    final originals = <String>[];
    final seen = <String>{};

    for (final raw in cities) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty || CityInput.isPlaceholder(trimmed)) continue;
      // Legacy multi-city labels (`Belfort/ andelnans`) count as each city.
      final labels = <String>[
        trimmed,
        if (_listSeparators.hasMatch(trimmed))
          ...trimmed.split(_listSeparators).map((p) => p.trim()),
      ];
      for (final label in labels) {
        if (label.isEmpty || CityInput.isPlaceholder(label)) continue;
        if (seen.add(normalizeCityKey(label))) originals.add(label);
      }
    }

    if (originals.isEmpty) return const CityArea(names: <String>[]);

    final out = <String>[...originals];
    // name key → départements it is allowed in; null = unknown (any).
    final depts = <String, Set<String>?>{};
    void allow(String name, String? dept) {
      final key = normalizeCityKey(name);
      if (key.isEmpty) return;
      if (dept == null || dept.isEmpty) {
        depts[key] = null; // unknown wins: never hide on missing data
        return;
      }
      if (depts.containsKey(key) && depts[key] == null) return;
      (depts[key] ??= <String>{}).add(dept);
    }

    // Resolve every connected city's codes in parallel, each bounded by
    // [perCityTimeout]: a slow / offline geo API must never leave Découvrir
    // spinning — that city then falls back to exact match.
    const none = (department: null, epci: null);
    final codes = await Future.wait(
      originals.map(
        (city) => _codesFor(city, knownMetadata)
            .timeout(perCityTimeout, onTimeout: () => none)
            .catchError((Object _) => none),
      ),
    );
    // Only a département the client actually stored (picked in the city
    // sheet) is trusted for homonyms. One guessed by name through the API
    // picks the most populous homonym (Saint-Louis → 974, not 68) and would
    // hide the client's own town.
    final certainDepts = <String>{};
    for (final original in originals) {
      final stored = _storedDepartment(original, knownMetadata);
      allow(original, stored);
      if (stored != null) certainDepts.add(stored);
    }
    final departments = <String>{};
    final epcis = <String>{};
    for (final c in codes) {
      final dept = c.department;
      final epci = c.epci;
      if (dept != null && wholeDepartments.contains(dept)) {
        departments.add(dept);
      } else if (epci != null && epci.isNotEmpty) {
        epcis.add(epci);
      }
    }

    final deptList = departments.toList();
    final peerLists = await Future.wait([
      ...deptList.map(
        (department) => _catalog
            .communeNamesForDepartment(department)
            .timeout(perCityTimeout, onTimeout: () => const <String>[])
            .catchError((Object _) => const <String>[]),
      ),
      ...epcis.map(
        (epci) => _catalog
            .communeNamesForEpci(epci)
            .timeout(perCityTimeout, onTimeout: () => const <String>[])
            .catchError((Object _) => const <String>[]),
      ),
    ]);
    for (var l = 0; l < peerLists.length; l++) {
      // Département lists come first; EPCI lists carry no département (an
      // EPCI can straddle two) → unknown.
      final listDept = l < deptList.length ? deptList[l] : null;
      final dept =
          (listDept != null && certainDepts.contains(listDept)) ? listDept : null;
      for (final peer in peerLists[l]) {
        // An EPCI list repeats the client's own commune without a
        // département: don't let that erase the one already known.
        if (dept != null || !depts.containsKey(normalizeCityKey(peer))) {
          allow(peer, dept);
        }
        final key = normalizeCityKey(peer);
        if (key.isEmpty || !seen.add(key)) continue;
        out.add(peer);
      }
    }

    return CityArea(names: out, departmentsByCityKey: depts);
  }

  static final RegExp _listSeparators = RegExp(r'[/,;&+|]');

  static String normalizeCityKey(String raw) => CityMatch.key(raw);
}

/// A client's Découvrir area: commune names, and where known the
/// département(s) each name belongs to.
class CityArea {
  const CityArea({
    required this.names,
    this.departmentsByCityKey = const <String, Set<String>?>{},
  });

  final List<String> names;
  final Map<String, Set<String>?> departmentsByCityKey;

  /// False only for a proven homonym: the shop's stored commune is in a
  /// département the client's area does not include for that name. Missing
  /// data on either side keeps the shop (same as before).
  bool allowsShop({required String city, FrenchCommune? commune}) {
    final key = CityMatch.key(city);
    final allowed = departmentsByCityKey[key];
    if (allowed == null || allowed.isEmpty) return true;
    final dept = commune?.departmentCode?.trim();
    if (dept == null || dept.isEmpty) return true;
    // Only trust metadata describing the shop's current city.
    if (CityMatch.key(commune!.name) != key) return true;
    return allowed.contains(dept);
  }
}
