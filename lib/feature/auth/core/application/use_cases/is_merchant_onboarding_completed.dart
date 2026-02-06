import '../../domain/repositories/user_repository.dart';
import '../../../../../core/domain/core/result.dart';

/// Use case for checking if merchant onboarding is completed
class IsMerchantOnboardingCompleted {
  const IsMerchantOnboardingCompleted(this._repository);

  final UserRepository _repository;

  Future<Result<bool?>> call(String uid) =>
      _repository.isMerchantOnboardingCompleted(uid);
}

