import '../../domain/repositories/user_repository.dart';
import '../../../../../core/domain/core/result.dart';

/// Use case for updating last_login_at timestamp on successful sign-in
class UpdateLastLoginAt {
  const UpdateLastLoginAt(this._repository);

  final UserRepository _repository;

  Future<Result<Unit>> call(
    String uid, {
    String? displayName,
    String? photoUrl,
  }) =>
      _repository.updateLastLoginAt(
        uid,
        displayName: displayName,
        photoUrl: photoUrl,
      );
}

