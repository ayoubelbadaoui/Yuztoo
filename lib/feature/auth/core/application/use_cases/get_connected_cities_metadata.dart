import '../../../../../../core/domain/core/result.dart';
import '../../../../../../core/domain/entities/french_commune.dart';
import '../../domain/repositories/user_repository.dart';

/// Load `cities_metadata` for agglomeration-aware Découvrir filtering.
class GetConnectedCitiesMetadata {
  const GetConnectedCitiesMetadata(this._repository);

  final UserRepository _repository;

  Future<Result<Map<String, FrenchCommune>>> call(String uid) =>
      _repository.getConnectedCitiesMetadata(uid);
}
