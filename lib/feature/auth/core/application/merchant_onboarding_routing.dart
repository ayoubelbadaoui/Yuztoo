import '../domain/repositories/user_repository.dart';
import 'onboarding_completion_cache.dart';
import 'use_cases/is_merchant_onboarding_completed.dart';

/// Firestore `users/{uid}.onboarding.merchant` based completion check.
/// Returns [false] if onboarding is incomplete.
///
/// When Firestore gives no answer (error / timeout, retried once), falls back
/// to [OnboardingCompletionCache] so an established merchant is not routed
/// into the creation wizard by a network blip.
Future<bool> merchantOnboardingCompletedFromFirestore(
  UserRepository repository,
  String uid, {
  Duration timeout = const Duration(seconds: 8),
  int attempts = 2,
}) async {
  final uc = IsMerchantOnboardingCompleted(repository);
  for (var attempt = 0; attempt < attempts; attempt++) {
    try {
      final result = await uc.call(uid).timeout(timeout);
      final completed = result.fold<bool?>((_) => null, (c) => c ?? false);
      if (completed != null) {
        if (completed) {
          await OnboardingCompletionCache.markCompleted('merchant', uid);
        }
        return completed;
      }
    } catch (_) {
      // Timeout / unexpected error: inconclusive, retry then fall back.
    }
  }
  return OnboardingCompletionCache.wasCompleted('merchant', uid);
}
