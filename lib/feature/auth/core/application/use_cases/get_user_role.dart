import '../../domain/repositories/user_repository.dart';
import '../../../../../core/domain/core/result.dart';
import '../../../../../types.dart';

/// Use case for getting user role from Firestore
class GetUserRole {
  const GetUserRole(this._repository);

  final UserRepository _repository;

  Future<Result<UserRole?>> call(String uid) => _repository.getUserRole(uid);
}
