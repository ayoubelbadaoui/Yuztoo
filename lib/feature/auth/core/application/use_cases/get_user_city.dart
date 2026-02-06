import '../../domain/repositories/user_repository.dart';
import '../../../../../core/domain/core/result.dart';

/// Use case for getting user's city from Firestore
class GetUserCity {
  const GetUserCity(this._repository);

  final UserRepository _repository;

  Future<Result<String?>> call(String uid) => _repository.getUserCity(uid);
}

