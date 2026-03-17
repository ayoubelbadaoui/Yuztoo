import '../../../../../../core/domain/core/result.dart';
import '../../domain/repositories/user_repository.dart';

/// Get the list of connected cities for the user from Firestore.
class GetConnectedCities {
  const GetConnectedCities(this._repository);

  final UserRepository _repository;

  Future<Result<List<String>>> call(String uid) =>
      _repository.getConnectedCities(uid);
}
