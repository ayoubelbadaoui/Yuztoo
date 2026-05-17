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
      // parameter. Both are trimmed + lower-cased once here so the per-doc
      // comparison stays O(n) without re-allocating strings.
      final Set<String> normalizedCities = <String>{
        if (cityFilters != null)
          ...cityFilters
              .map((c) => c.trim().toLowerCase())
              .where((c) => c.isNotEmpty),
        if ((cityFilters == null || cityFilters.isEmpty) &&
            cityFilter != null &&
            cityFilter.trim().isNotEmpty)
          cityFilter.trim().toLowerCase(),
      };
      final useCityFilter = normalizedCities.isNotEmpty;
      final fetchLimit =
          useCityFilter ? cityFetchCap.clamp(limit, 1000) : limit;

      // Only return merchants that are online (status == 'active').
      // The composite index [status ASC, updated_at DESC] in firestore.indexes.json
      // covers this query. When filtering by city, scan a wider slice so a
      // commerce that just set its city is not excluded by the global top-N limit.
      final querySnapshot = await _firestore
          .collection('merchants')
          .where('status', isEqualTo: 'active')
          .orderBy('updated_at', descending: true)
          .limit(fetchLimit)
          .get();

      var merchants = querySnapshot.docs
          .map((doc) => MerchantDto.fromFirestore(doc).toDomain())
          .toList();

      // Safety: keep only active merchants in case Firestore index is not yet
      // deployed or there is a replication lag.
      merchants = merchants.where((m) => m.status == 'active').toList();

      if (useCityFilter) {
        merchants = merchants
            .where((m) =>
                normalizedCities.contains(m.city.trim().toLowerCase()))
            .take(limit)
            .toList();
      }

      LoggerService.logInfo(
        'List merchants for client home',
        context: {
          'count': merchants.length,
          'limit': limit,
          'cityFilter':
              useCityFilter ? normalizedCities.join(',') : null,
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
        final merchants = snapshot.docs
            .map((doc) => MerchantDto.fromFirestore(doc).toDomain())
            .toList();
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
      LoggerService.logError('Error getMerchantsByIds', error: e, stackTrace: st);
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
