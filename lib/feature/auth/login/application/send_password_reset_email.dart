import '../../core/domain/auth_failure.dart';
import '../../core/domain/repositories/auth_repository.dart';
import '../../core/domain/value_objects/email_address.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/domain/core/either.dart';

class SendPasswordResetEmail {
  const SendPasswordResetEmail(this._repository);

  final AuthRepository _repository;

  Future<Result<Unit>> call({required String email}) {
    if (!EmailAddress.isValid(email)) {
      return Future<Result<Unit>>.value(
        const Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(message: 'Adresse email invalide.'),
        ),
      );
    }

    return _repository.sendPasswordResetEmail(
      email: EmailAddress(email),
    );
  }
}

