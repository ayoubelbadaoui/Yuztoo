import '../../core/domain/auth_failure.dart';
import '../../core/domain/repositories/auth_repository.dart';
import '../../core/domain/value_objects/email_address.dart';
import '../../core/domain/value_objects/password.dart';
import '../../../../core/domain/core/result.dart';
import '../../core/domain/entities/auth_user.dart';
import '../../../../core/domain/core/either.dart';

class SignInWithEmailPassword {
  const SignInWithEmailPassword(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthUser>> call({
    required String email,
    required String password,
  }) {
    if (!EmailAddress.isValid(email) || !Password.isValid(password)) {
      return Future<Result<AuthUser>>.value(
        const Left<AuthFailure, AuthUser>(InvalidCredentialsFailure()),
      );
    }

    return _repository.signInWithEmailAndPassword(
      email: EmailAddress(email),
      password: Password(password),
    );
  }
}
