import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/auth_failure.dart';
import '../domain/entities/user_profile_basics.dart';
import '../domain/repositories/user_repository.dart';
import '../../../../../core/domain/core/either.dart';
import '../../../../../core/domain/core/result.dart';
import '../../../../../core/infrastructure/firestore_user_rules_patch.dart';
import '../../../../../core/utils/city_input.dart';
import '../../../../../core/infrastructure/logger_service.dart';
import '../../../../../types.dart';

part 'firebase_user_repository.create.part.dart';
part 'firebase_user_repository.reads.part.dart';
part 'firebase_user_repository.writes.part.dart';

/// Thrown inside [createUserDocument] transaction when phone is taken by another uid.
class DuplicatePhoneIndexException implements Exception {
  const DuplicatePhoneIndexException();
}

/// Thrown inside [createUserDocument] transaction when email is taken by another uid.
class DuplicateEmailIndexException implements Exception {
  const DuplicateEmailIndexException();
}

abstract class _FirebaseUserRepositoryBase {
  _FirebaseUserRepositoryBase(this._firestore);

  final FirebaseFirestore _firestore;
}

/// Firebase implementation of UserRepository
class FirebaseUserRepository extends _FirebaseUserRepositoryBase
    with
        _FirebaseUserRepositoryCreate,
        _FirebaseUserRepositoryReads,
        _FirebaseUserRepositoryWrites
    implements UserRepository {
  FirebaseUserRepository({required FirebaseFirestore firestore}) : super(firestore);
}
