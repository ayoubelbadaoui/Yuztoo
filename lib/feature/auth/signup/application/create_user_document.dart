import '../../core/domain/auth_failure.dart';
import '../../core/domain/repositories/user_repository.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/domain/core/either.dart';

class CreateUserDocument {
  const CreateUserDocument(this._repository);

  final UserRepository _repository;

  Future<Result<Unit>> call({
    required String uid,
    required String email,
    required String phone,
    required Map<String, bool> roles,
    required String city,
  }) {
    if (uid.isEmpty) {
      return Future<Result<Unit>>.value(
        const Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(message: 'User ID is required.'),
        ),
      );
    }

    if (email.isEmpty) {
      return Future<Result<Unit>>.value(
        const Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(message: 'Email is required.'),
        ),
      );
    }

    if (phone.isEmpty) {
      return Future<Result<Unit>>.value(
        const Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(message: 'Phone number is required.'),
        ),
      );
    }

    if (city.isEmpty) {
      return Future<Result<Unit>>.value(
        const Left<AuthFailure, Unit>(
          AuthUnexpectedFailure(message: 'City is required.'),
        ),
      );
    }

    return _repository.createUserDocument(
      uid: uid,
      email: email,
      phone: phone,
      roles: roles,
      city: city,
    );
  }
}

