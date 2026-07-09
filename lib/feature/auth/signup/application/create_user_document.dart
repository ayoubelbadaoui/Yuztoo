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
    String? firstName,
    String? lastName,
    String? displayName,
    String? photoUrl,
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

    return _repository.createUserDocument(
      uid: uid,
      email: email,
      phone: phone,
      roles: roles,
      firstName: firstName,
      lastName: lastName,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }
}

