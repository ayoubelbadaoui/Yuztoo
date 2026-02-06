import '../../domain/repositories/user_repository.dart';
import '../../../../../core/domain/core/result.dart';

/// Use case for patching missing fields in user document for legacy users
class PatchUserDocument {
  const PatchUserDocument(this._repository);

  final UserRepository _repository;

  Future<Result<Unit>> call(String uid) => _repository.patchUserDocument(uid);
}

