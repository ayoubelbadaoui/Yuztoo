import '../../../../../../core/domain/core/result.dart';
import '../../domain/repositories/user_repository.dart';

/// Save the list of connected cities to Firestore.
class SetConnectedCities {
  const SetConnectedCities(this._repository);

  final UserRepository _repository;

  Future<Result<Unit>> call({
    required String uid,
    required List<String> cities,
  }) =>
      _repository.setConnectedCities(uid: uid, cities: cities);
}
