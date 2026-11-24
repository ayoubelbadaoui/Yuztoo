import '../../../../../../core/domain/core/either.dart';
import '../../../../../../core/domain/core/failure.dart';
import '../../../../../../core/domain/core/result.dart';
import '../../../../../../core/domain/entities/french_commune.dart';
import '../../../../../../core/infrastructure/city_catalog_repository.dart';
import '../../domain/repositories/user_repository.dart';

/// Save the list of connected cities to Firestore.
///
/// Resolves each city name to official commune metadata (EPCI) when possible
/// so Découvrir can expand agglomerations without a live geo call every time.
class SetConnectedCities {
  const SetConnectedCities(
    this._repository, {
    CityCatalogRepository? catalog,
  }) : _catalog = catalog;

  final UserRepository _repository;

  static const Duration _resolveTimeout = Duration(seconds: 4);
  final CityCatalogRepository? _catalog;

  Future<Result<Unit>> call({
    required String uid,
    required List<String> cities,
    Map<String, FrenchCommune>? citiesMetadata,
  }) async {
    final metadata = Map<String, FrenchCommune>.from(citiesMetadata ?? {});
    final catalog = _catalog;
    if (catalog != null) {
      bool hasMeta(String name) => metadata.keys.any(
            (k) => k.trim().toLowerCase() == name.toLowerCase(),
          );

      // Keep what is already stored for the cities the user keeps, so adding
      // or removing one city never re-resolves (or loses) the others.
      if (cities.any((c) => c.trim().isNotEmpty && !hasMeta(c.trim()))) {
        final existing = await _repository
            .getConnectedCitiesMetadata(uid)
            .timeout(_resolveTimeout,
                onTimeout: () =>
                    const Right<AppFailure, Map<String, FrenchCommune>>(
                      <String, FrenchCommune>{},
                    ));
        existing.fold((_) {}, (stored) {
          for (final entry in stored.entries) {
            if (!hasMeta(entry.key)) metadata[entry.key] = entry.value;
          }
        });
      }

      // Resolve the remaining ones in parallel, each bounded: saving cities
      // must stay instant even when geo.api.gouv.fr is slow or unreachable.
      final missing = <String>{
        for (final raw in cities)
          if (raw.trim().isNotEmpty && !hasMeta(raw.trim())) raw.trim(),
      };
      final resolved = await Future.wait(
        missing.map(
          (name) => catalog
              .resolveByName(name)
              .timeout(_resolveTimeout, onTimeout: () => null)
              .catchError((Object _) => null),
        ),
      );
      var i = 0;
      for (final name in missing) {
        final commune = resolved[i++];
        if (commune != null) metadata[name] = commune;
      }
    }

    return _repository.setConnectedCities(
      uid: uid,
      cities: cities,
      citiesMetadata: metadata.isEmpty ? citiesMetadata : metadata,
    );
  }
}
