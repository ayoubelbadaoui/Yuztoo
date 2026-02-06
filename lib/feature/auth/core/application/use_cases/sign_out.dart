import '../../domain/repositories/auth_repository.dart';
import '../../../../../core/domain/core/result.dart';

class SignOut {
  const SignOut(this._repository);

  final AuthRepository _repository;

  Future<Result<Unit>> call() => _repository.signOut();
}
