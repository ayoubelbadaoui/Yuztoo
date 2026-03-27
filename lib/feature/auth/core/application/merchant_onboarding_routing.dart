import '../domain/repositories/user_repository.dart';
import 'use_cases/is_merchant_onboarding_completed.dart';

/// Firestore `users/{uid}.merchant_id` based completion check.
/// Returns [false] if read fails or onboarding is incomplete.
Future<bool> merchantOnboardingCompletedFromFirestore(
  UserRepository repository,
  String uid,
) async {
  try {
    final uc = IsMerchantOnboardingCompleted(repository);
    final result = await uc.call(uid);
    return result.fold((_) => false, (c) => c ?? false);
  } catch (_) {
    return false;
  }
}
