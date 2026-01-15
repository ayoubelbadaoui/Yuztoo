import '../../../domain/auth/auth_failure.dart';
import '../../../domain/auth/repositories/auth_repository.dart';
import '../../../domain/auth/value_objects/email_address.dart';
import '../../../domain/auth/value_objects/password.dart';
import '../../../domain/core/result.dart';
import '../../../domain/auth/entities/auth_user.dart';
import '../../../domain/core/either.dart';

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
