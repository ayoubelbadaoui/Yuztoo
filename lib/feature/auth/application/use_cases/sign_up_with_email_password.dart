import '../../domain/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/value_objects/email_address.dart';
import '../../domain/value_objects/password.dart';
import '../../../../core/domain/core/result.dart';
import '../../domain/entities/auth_user.dart';
import '../../../../core/domain/core/either.dart';

class SignUpWithEmailPassword {
  const SignUpWithEmailPassword(this._repository);

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

    return _repository.signUpWithEmailAndPassword(
      email: EmailAddress(email),
      password: Password(password),
    );
  }
}

