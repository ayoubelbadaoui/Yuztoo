import '../../../domain/auth/repositories/auth_repository.dart';
import '../../../domain/core/result.dart';

class SignOut {
  const SignOut(this._repository);

  final AuthRepository _repository;

  Future<Result<Unit>> call() => _repository.signOut();
}
