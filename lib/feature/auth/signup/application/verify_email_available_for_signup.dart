import '../../../../../core/domain/core/failure.dart';
import '../../core/domain/auth_failure.dart';
import '../../core/domain/repositories/user_repository.dart';
import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/result.dart';

/// Blocks signup when the email is already registered ([email_index]).
class VerifyEmailAvailableForSignup {
  const VerifyEmailAvailableForSignup(this._userRepository);

  final UserRepository _userRepository;

  static const AppFailure _duplicateEmail = AuthUnexpectedFailure(
    message:
        'Cette adresse email est déjà utilisée. Connectez-vous ou utilisez une autre adresse.',
  );

  Future<Result<Unit>> call({required String email}) {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) {
      return Future<Result<Unit>>.value(
        const Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(message: 'L\'adresse email est requise.'),
        ),
      );
    }

    return _userRepository.isEmailRegistered(normalized).then(
          (Result<bool> result) => result.fold<Result<Unit>>(
            (AppFailure f) => Left<AppFailure, Unit>(f),
            (bool registered) => registered
                ? const Left<AppFailure, Unit>(_duplicateEmail)
                : const Right<AppFailure, Unit>(unit),
          ),
        );
  }
}
