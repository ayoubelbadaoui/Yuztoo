import '../../core/domain/auth_failure.dart';
import '../../core/domain/repositories/auth_repository.dart';
import '../../core/domain/value_objects/email_address.dart';
import '../../core/domain/value_objects/password.dart';
import '../../../../core/domain/core/result.dart';
import '../../core/domain/entities/auth_user.dart';
import '../../../../core/domain/core/either.dart';

/// Sign in with email and password.
///
/// Only the email format is validated locally (so we do not waste a network
/// round-trip on obviously bad input) and the password is checked for
/// emptiness. We deliberately do **not** apply the signup password policy
/// (≥ 8 chars, complexity rules) here: that policy describes how new
/// passwords must be formed, not what existing passwords look like. Gating
/// sign-in on it would lock out legacy / externally-provisioned accounts
/// and surface a misleading "Identifiants incorrects" instead of letting
/// Firebase Auth respond with the real reason.
class SignInWithEmailPassword {
  const SignInWithEmailPassword(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthUser>> call({
    required String email,
    required String password,
  }) {
    if (!EmailAddress.isValid(email) || password.isEmpty) {
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
