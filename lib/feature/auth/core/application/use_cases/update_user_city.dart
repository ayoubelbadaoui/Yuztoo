import '../../domain/repositories/user_repository.dart';
import '../../../../../core/domain/core/result.dart';

/// Use case for updating user's city in Firestore
class UpdateUserCity {
  const UpdateUserCity(this._repository);

  final UserRepository _repository;

  Future<Result<Unit>> call({required String uid, required String city}) =>
      _repository.updateUserCity(uid: uid, city: city);
}

