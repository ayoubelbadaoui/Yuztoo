import '../../domain/entities/user_profile_basics.dart';
import '../../domain/repositories/user_repository.dart';
import '../../../../../core/domain/core/result.dart';

/// Use case for getting user's email/phone/city from Firestore.
class GetUserProfileBasics {
  const GetUserProfileBasics(this._repository);

  final UserRepository _repository;

  Future<Result<UserProfileBasics?>> call(String uid) =>
      _repository.getUserProfileBasics(uid);
}


