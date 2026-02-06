import '../../core/domain/auth_failure.dart';
import '../../core/domain/repositories/auth_repository.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/domain/core/either.dart';

/// Use case for sending phone verification OTP
class SendPhoneVerification {
  const SendPhoneVerification(this._repository);

  final AuthRepository _repository;

  Future<Result<String>> call({
    required String phoneNumber,
  }) {
    if (phoneNumber.isEmpty) {
      return Future<Result<String>>.value(
        const Left<AuthFailure, String>(
          AuthUnexpectedFailure(message: 'Le numéro de téléphone est requis.'),
        ),
      );
    }

    return _repository.sendPhoneVerification(phoneNumber: phoneNumber);
  }
}

