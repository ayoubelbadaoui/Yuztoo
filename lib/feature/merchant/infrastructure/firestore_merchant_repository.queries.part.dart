part of 'firestore_merchant_repository.dart';

mixin _FirestoreMerchantRepositoryQueries on _FirestoreMerchantRepositoryBase {
  Future<Result<List<Merchant>>> listMerchants({
    int limit = 20,
    String? cityFilter,
    List<String>? cityFilters,
    int cityFetchCap = 500,
  }) async {
    try {
      // Multi-city list takes precedence over the single-city convenience
      // parameter. Keys are accent / case / hyphen-insensitive ([CityMatch])
      // so legacy free-text cities still match official commune names.
      final Set<String> normalizedCities = <String>{
        if (cityFilters != null)
          ...cityFilters.map(CityMatch.key).where((c) => c.isNotEmpty),
        if ((cityFilters == null || cityFilters.isEmpty) &&
            cityFilter != null &&
            cityFilter.trim().isNotEmpty)
          CityMatch.key(cityFilter),
      };
      final useCityFilter = normalizedCities.isNotEmpty;

      // City-scoped: Firestore returns only the matching shops (city_keys
      // array-contains-any), so a small town's shops are never cut off by the
      // newest-N slice of the whole base, and reads ≈ matching shops.
      if (useCityFilter) {
        try {
          final byCity = await _activeMerchantsByCityKeys(
            normalizedCities.toList(),
            limit: limit,
          );
          if (byCity.isNotEmpty) {
            LoggerService.logInfo(
              'List merchants by city keys',
              context: {
                'count': byCity.length,
                'keys': normalizedCities.length,
              },
            );
            return Right<MerchantFailure, List<Merchant>>(byCity);
          }
          // Empty city_keys index (pre-backfill) → legacy scan below.
        } on FirebaseException catch (e, st) {
          // Missing index / rules must not blank Découvrir — fall through.
          LoggerService.logError(
            'city_keys query failed; legacy city scan',
            error: e,
            stackTrace: st,
            context: {'code': e.code, 'keys': normalizedCities.length},
          );
        }
      }
      final fetchLimit =
          useCityFilter ? cityFetchCap.clamp(limit, 1000) : limit;

      // Only return merchants that are online (status == 'active').
      // The composite index [status ASC, updated_at DESC] in firestore.indexes.json
      // covers this query.
      final querySnapshot = await _firestore
          .collection('merchants')
          .where('status', isEqualTo: 'active')
          .orderBy('updated_at', descending: true)
          .limit(fetchLimit)
          .get();

      var merchants = querySnapshot.docs.mapSkippingInvalid(
        (doc) => MerchantDto.fromFirestore(doc).toDomain(),
        label: 'merchant',
      );

      // Safety: keep only active merchants in case Firestore index is not yet
      // deployed or there is a replication lag.
      merchants = merchants.where((m) => m.status == 'active').toList();

      if (useCityFilter) {
        merchants = merchants
            .where((m) =>
                CityMatch.candidateKeys(m.city).any(normalizedCities.contains))
            .take(limit)
            .toList();
      }

      LoggerService.logInfo(
        'List merchants for client home',
        context: {
          'count': merchants.length,
          'limit': limit,
          'cityFilter': useCityFilter ? normalizedCities.join(',') : null,
        },
      );
      return Right<MerchantFailure, List<Merchant>>(merchants);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Firebase error listing merchants',
        error: e,
        stackTrace: st,
        context: {'code': e.code},
      );
      if (e.code == 'permission-denied') {
        return const Left<MerchantFailure, List<Merchant>>(
          MerchantUnexpectedFailure(
            message: 'Permission refusée lors de la lecture des commerces.',
          ),
        );
      }
      return Left<MerchantFailure, List<Merchant>>(
        MerchantNetworkFailure(cause: e, stackTrace: st),
      );
    } catch (e, st) {
      LoggerService.logError(
        'Unexpected error listing merchants',
        error: e,
        stackTrace: st,
      );
      return Left<MerchantFailure, List<Merchant>>(
        MerchantUnexpectedFailure(
          message: 'Impossible de charger les commerces',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Firestore cap on `array-contains-any` values per query.
  static const int _arrayContainsAnyLimit = 30;

  /// Active shops whose `city_keys` hold one of [keys], newest first.
  /// Index: merchants [status ASC, city_keys CONTAINS, updated_at DESC].
  /// One query per 30 keys (the whole Territoire de Belfort = 4 queries),
  /// each capped at [limit], so reads stay bounded by the matching shops.
  Future<List<Merchant>> _activeMerchantsByCityKeys(
    List<String> keys, {
    required int limit,
  }) async {
    final chunks = <List<String>>[
      for (var i = 0; i < keys.length; i += _arrayContainsAnyLimit)
        keys.sublist(
          i,
          i + _arrayContainsAnyLimit > keys.length
              ? keys.length
              : i + _arrayContainsAnyLimit,
        ),
    ];
    final snapshots = await Future.wait(
      chunks.map(
        (chunk) => _firestore
            .collection('merchants')
            .where('status', isEqualTo: 'active')
            .where('city_keys', arrayContainsAny: chunk)
            .orderBy('updated_at', descending: true)
            .limit(limit)
            .get(),
      ),
    );
    final byId = <String, Merchant>{};
    for (final snap in snapshots) {
      for (final m in snap.docs.mapSkippingInvalid(
        (doc) => MerchantDto.fromFirestore(doc).toDomain(),
        label: 'merchant',
      )) {
        if (m.status == 'active') byId.putIfAbsent(m.id, () => m);
      }
    }
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    final merged = byId.values.toList()
      ..sort((a, b) =>
          (b.updatedAt ?? epoch).compareTo(a.updatedAt ?? epoch));
    return merged.take(limit).toList();
  }

  static const int _whereInLimit = 10;

  Future<Result<List<Merchant>>> getMerchantsByIds(List<String> ids) async {
    if (ids.isEmpty) {
      return const Right<MerchantFailure, List<Merchant>>([]);
    }
    final distinctIds = ids.toSet().toList();
    try {
      final all = <Merchant>[];
      for (var i = 0; i < distinctIds.length; i += _whereInLimit) {
        final chunk = distinctIds.skip(i).take(_whereInLimit).toList();
        final snapshot = await _firestore
            .collection('merchants')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        final merchants = snapshot.docs.mapSkippingInvalid(
          (doc) => MerchantDto.fromFirestore(doc).toDomain(),
          label: 'merchant',
        );
        all.addAll(merchants);
      }
      // Preserve order of [ids] where possible
      final byId = {for (final m in all) m.id: m};
      final ordered = <Merchant>[];
      for (final id in ids) {
        final m = byId[id];
        if (m != null && !ordered.any((e) => e.id == m.id)) {
          ordered.add(m);
        }
      }
      for (final m in all) {
        if (!ordered.any((e) => e.id == m.id)) ordered.add(m);
      }
      LoggerService.logInfo(
        'getMerchantsByIds',
        context: {'requested': ids.length, 'found': ordered.length},
      );
      return Right<MerchantFailure, List<Merchant>>(ordered);
    } on FirebaseException catch (e, st) {
      // /merchants is publicly readable per firestore.rules, so a real
      // permission-denied here is unusual and points at a project-config
      // issue — return it as Left so the UI can surface a retry instead of
      // showing an empty carnet to the user.
      LoggerService.logError(
        'Firebase error getMerchantsByIds',
        error: e,
        stackTrace: st,
        context: {'code': e.code, 'requested': ids.length},
      );
      return Left<MerchantFailure, List<Merchant>>(
        MerchantNetworkFailure(cause: e, stackTrace: st),
      );
    } catch (e, st) {
      LoggerService.logError('Error getMerchantsByIds',
          error: e, stackTrace: st);
      return Left<MerchantFailure, List<Merchant>>(
        MerchantUnexpectedFailure(
          message: 'Impossible de charger les commerces',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
