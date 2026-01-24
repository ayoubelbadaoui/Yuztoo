import '../../core/domain/auth_failure.dart';
import '../../core/domain/repositories/auth_repository.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/domain/core/either.dart';

/// Use case for verifying OTP code and linking phone to user
class VerifyAndLinkPhone {
  const VerifyAndLinkPhone(this._repository);

  final AuthRepository _repository;

  Future<Result<Unit>> call({
    required String verificationId,
    required String smsCode,
  }) {
    if (verificationId.isEmpty) {
      return Future<Result<Unit>>.value(
        const Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(message: 'ID de vérification manquant'),
        ),
      );
    }

    if (smsCode.isEmpty || smsCode.length != 6) {
      return Future<Result<Unit>>.value(
        const Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(message: 'Code de vérification invalide'),
        ),
      );
    }

    return _repository.verifyAndLinkPhone(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }
}

