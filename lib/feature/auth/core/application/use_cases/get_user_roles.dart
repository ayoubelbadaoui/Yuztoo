import '../../domain/repositories/user_repository.dart';
import '../../../../../core/domain/core/result.dart';

/// Use case for getting user roles map from Firestore
class GetUserRoles {
  const GetUserRoles(this._repository);

  final UserRepository _repository;

  Future<Result<Map<String, bool>?>> call(String uid) =>
      _repository.getUserRoles(uid);
}

