import '../../domain/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/domain/core/either.dart';

class SendPhoneVerification {
  const SendPhoneVerification(this._repository);

  final AuthRepository _repository;

  Future<Result<String>> call({
    required String phoneNumber,
  }) {
    if (phoneNumber.isEmpty) {
      return Future<Result<String>>.value(
        const Left<AuthFailure, String>(
          AuthUnexpectedFailure(message: 'Phone number is required.'),
        ),
      );
    }

    return _repository.sendPhoneVerification(phoneNumber: phoneNumber);
  }
}

