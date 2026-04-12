import '../../domain/repositories/auth_repository.dart';
import '../../../../../core/domain/core/result.dart';

/// Updates the signed-in auth user's display name and/or photo URL (Firebase Auth).
class UpdateAuthUserProfile {
  const UpdateAuthUserProfile(this._repository);

  final AuthRepository _repository;

  Future<Result<Unit>> call({
    String? displayName,
    String? photoUrl,
  }) =>
      _repository.updateUserProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      );
}
