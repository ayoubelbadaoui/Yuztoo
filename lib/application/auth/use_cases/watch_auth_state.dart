import '../../../domain/auth/entities/auth_user.dart';
import '../../../domain/auth/repositories/auth_repository.dart';
import '../../../domain/core/result.dart';

class WatchAuthState {
  const WatchAuthState(this._repository);

  final AuthRepository _repository;

  Stream<Result<AuthUser?>> call() => _repository.watchAuthState();
}
