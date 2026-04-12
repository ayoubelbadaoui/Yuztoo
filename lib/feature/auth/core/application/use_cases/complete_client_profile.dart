import '../../domain/repositories/user_repository.dart';
import '../../../../../core/domain/core/result.dart';

class CompleteClientProfile {
  const CompleteClientProfile(this._repository);

  final UserRepository _repository;

  Future<Result<Unit>> call({
    required String uid,
    required String displayName,
    String? photoUrl,
  }) =>
      _repository.completeClientProfile(
        uid: uid,
        displayName: displayName,
        photoUrl: photoUrl,
      );
}
