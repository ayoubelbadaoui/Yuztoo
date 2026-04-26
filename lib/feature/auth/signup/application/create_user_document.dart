import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/result.dart';
import '../../core/domain/auth_failure.dart';
import '../../core/domain/repositories/user_repository.dart';

class CreateUserDocument {
  const CreateUserDocument(this._repository);

  final UserRepository _repository;

  Future<Result<Unit>> call({
    required String uid,
    required String email,
    required String phone,
    required Map<String, bool> roles,
  }) {
    if (uid.isEmpty) {
      return Future<Result<Unit>>.value(
        const Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(message: 'L\'identifiant utilisateur est requis.'),
        ),
      );
    }

    if (email.isEmpty) {
      return Future<Result<Unit>>.value(
        const Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(message: 'L\'adresse e-mail est requise.'),
        ),
      );
    }

    if (phone.isEmpty) {
      return Future<Result<Unit>>.value(
        const Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(message: 'Le numéro de téléphone est requis.'),
        ),
      );
    }

    return _repository.createUserDocument(
      uid: uid,
      email: email,
      phone: phone,
      roles: roles,
    );
  }
}

