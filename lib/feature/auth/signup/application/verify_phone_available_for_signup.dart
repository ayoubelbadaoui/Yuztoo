import '../../../../../core/domain/core/failure.dart';
import '../../core/domain/auth_failure.dart';
import '../../core/domain/repositories/user_repository.dart';
import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/result.dart';

/// Blocks signup OTP when the phone is already registered ([phone_index]).
class VerifyPhoneAvailableForSignup {
  const VerifyPhoneAvailableForSignup(this._userRepository);

  final UserRepository _userRepository;

  static const AppFailure _duplicatePhone = AuthUnexpectedFailure(
    message:
        'Vous avez déjà un compte avec ce numéro — nous ne créons pas deux comptes pour le même numéro. Connectez-vous.',
  );

  Future<Result<Unit>> call({required String phoneNumber}) {
    final normalized = phoneNumber.trim();
    if (normalized.isEmpty) {
      return Future<Result<Unit>>.value(
        const Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(message: 'Le numéro de téléphone est requis.'),
        ),
      );
    }

    return _userRepository.isPhoneNumberRegistered(normalized).then(
          (Result<bool> result) => result.fold<Result<Unit>>(
            (AppFailure f) => Left<AppFailure, Unit>(f),
            (bool registered) => registered
                ? const Left<AppFailure, Unit>(_duplicatePhone)
                : const Right<AppFailure, Unit>(unit),
          ),
        );
  }
}
