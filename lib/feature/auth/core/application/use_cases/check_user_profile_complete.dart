import '../../domain/repositories/user_repository.dart';
import '../../../../../core/domain/core/result.dart';

/// Use case for checking if user profile is complete with all required fields
class CheckUserProfileComplete {
  const CheckUserProfileComplete(this._repository);

  final UserRepository _repository;

  Future<Result<bool>> call(String uid) => _repository.checkUserProfileComplete(uid);
}

