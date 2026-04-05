import '../../domain/repositories/user_repository.dart';
import '../../../../../core/domain/core/result.dart';

/// Persists merchant acquisition onboarding completion on the user document.
class MarkMerchantOnboardingCompleted {
  const MarkMerchantOnboardingCompleted(this._repository);

  final UserRepository _repository;

  Future<Result<Unit>> call(String uid) =>
      _repository.markMerchantOnboardingCompleted(uid);
}
