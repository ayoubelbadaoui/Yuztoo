import '../../domain/repositories/user_repository.dart';
import '../../../../../core/domain/core/result.dart';
import '../../../../../core/domain/entities/french_commune.dart';

class CompleteClientProfile {
  const CompleteClientProfile(this._repository);

  final UserRepository _repository;

  Future<Result<Unit>> call({
    required String uid,
    required String displayName,
    String? city,
    FrenchCommune? commune,
    String? photoUrl,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
  }) =>
      _repository.completeClientProfile(
        uid: uid,
        displayName: displayName,
        city: city,
        commune: commune,
        photoUrl: photoUrl,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
      );
}
