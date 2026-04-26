import '../../core/domain/repositories/auth_repository.dart';
import '../../../../core/domain/core/result.dart';
import '../../core/domain/entities/auth_user.dart';

class SignInWithGoogle {
  const SignInWithGoogle(this._repository);
  final AuthRepository _repository;
  Future<Result<AuthUser>> call() => _repository.signInWithGoogle();
}

class SignInWithApple {
  const SignInWithApple(this._repository);
  final AuthRepository _repository;
  Future<Result<AuthUser>> call() => _repository.signInWithApple();
}
