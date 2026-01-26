import '../../core/domain/auth_failure.dart';
import '../../core/domain/repositories/auth_repository.dart';
import '../../core/domain/value_objects/email_address.dart';
import '../../core/domain/value_objects/password.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/domain/core/either.dart';
import '../../core/domain/entities/auth_user.dart';

/// Use case for verifying OTP code and creating user with phone + email/password
/// This ensures user is only created after OTP verification
class VerifyPhoneAndCreateUser {
  const VerifyPhoneAndCreateUser(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthUser>> call({
    required String verificationId,
    required String smsCode,
    required String email,
    required String password,
  }) {
    if (verificationId.isEmpty) {
      return Future<Result<AuthUser>>.value(
        const Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(message: 'ID de vérification manquant'),
        ),
      );
    }

    if (smsCode.isEmpty || smsCode.length != 6) {
      return Future<Result<AuthUser>>.value(
        const Left<AuthFailure, AuthUser>(
          AuthUnexpectedFailure(message: 'Code de vérification invalide'),
        ),
      );
    }

    final emailAddress = EmailAddress(email);
    final passwordObj = Password(password);

    return emailAddress.fold(
      (failure) => Future<Result<AuthUser>>.value(
        Left<AuthFailure, AuthUser>(failure),
      ),
      (validEmail) => passwordObj.fold(
        (failure) => Future<Result<AuthUser>>.value(
          Left<AuthFailure, AuthUser>(failure),
        ),
        (validPassword) => _repository.verifyPhoneAndCreateUser(
          verificationId: verificationId,
          smsCode: smsCode,
          email: validEmail,
          password: validPassword,
        ),
      ),
    );
  }
}

