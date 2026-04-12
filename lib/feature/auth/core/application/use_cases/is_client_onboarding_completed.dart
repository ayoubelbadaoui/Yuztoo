import '../../domain/repositories/user_repository.dart';
import '../../../../../core/domain/core/result.dart';

/// Use case for checking if client profile onboarding is completed.
class IsClientOnboardingCompleted {
  const IsClientOnboardingCompleted(this._repository);

  final UserRepository _repository;

  Future<Result<bool?>> call(String uid) =>
      _repository.isClientOnboardingCompleted(uid);
}
