import '../../core/domain/auth_failure.dart';
import '../../core/domain/entities/auth_user.dart';
import '../../core/domain/repositories/auth_repository.dart';
import '../../core/domain/value_objects/email_address.dart';
import '../../core/domain/value_objects/password.dart';
import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/result.dart';

/// Creates a Firebase Auth user with email/password when signup omits phone.
class SignupWithEmail {
  const SignupWithEmail(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthUser>> call({
    required String email,
    required String password,
  }) {
    if (!EmailAddress.isValid(email)) {
      return Future<Result<AuthUser>>.value(
        const Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(message: 'Adresse e-mail non valide.'),
        ),
      );
    }
    if (!Password.isValid(password)) {
      return Future<Result<AuthUser>>.value(
        const Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(
            message: 'Le mot de passe doit contenir au minimum 8 caractères.',
          ),
        ),
      );
    }

    return _repository.createUserWithEmailAndPassword(
      email: EmailAddress(email),
      password: Password(password),
    );
  }
}
