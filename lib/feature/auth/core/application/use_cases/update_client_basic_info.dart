import '../../../../../core/domain/core/result.dart';
import '../../domain/repositories/user_repository.dart';

/// Updates a client's editable profile fields (name, DOB) without touching
/// onboarding status, roles, or auth identity fields (email / phone).
class UpdateClientBasicInfo {
  const UpdateClientBasicInfo(this._repository);

  final UserRepository _repository;

  Future<Result<Unit>> call({
    required String uid,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? ownerEmail,
  }) =>
      _repository.updateClientBasicInfo(
        uid: uid,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        ownerEmail: ownerEmail,
      );
}
