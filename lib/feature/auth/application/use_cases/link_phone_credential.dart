import '../../domain/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/domain/core/either.dart';

class LinkPhoneCredential {
  const LinkPhoneCredential(this._repository);

  final AuthRepository _repository;

  Future<Result<Unit>> call({
    required String verificationId,
    required String smsCode,
  }) {
    if (verificationId.isEmpty || smsCode.isEmpty) {
      return Future<Result<Unit>>.value(
        const Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(message: 'Verification ID and SMS code are required.'),
        ),
      );
    }

    return _repository.linkPhoneCredential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }
}

