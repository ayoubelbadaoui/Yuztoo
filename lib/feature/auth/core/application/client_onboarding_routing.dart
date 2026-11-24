import '../domain/repositories/user_repository.dart';
import 'onboarding_completion_cache.dart';
import 'use_cases/is_client_onboarding_completed.dart';

/// Firestore `users/{uid}.onboarding.client` based completion check.
///
/// Returns [true] when onboarding is completed, legacy (no `client` key), or the
/// user is not a client ([Result] value `null` from [UserRepository]).
/// Returns [false] when onboarding is still pending or the user doc is not
/// ready yet.
///
/// When Firestore gives no answer (error / timeout, retried once), falls back
/// to [OnboardingCompletionCache]: a client who already finished onboarding
/// on this device is not sent back to it just because the network is down.
/// Without that memory it still fails closed into onboarding.
Future<bool> clientOnboardingCompletedFromFirestore(
  UserRepository repository,
  String uid, {
  Duration timeout = const Duration(seconds: 8),
  int attempts = 2,
}) async {
  final uc = IsClientOnboardingCompleted(repository);
  for (var attempt = 0; attempt < attempts; attempt++) {
    try {
      final result = await uc.call(uid).timeout(timeout);
      final completed = result.fold<bool?>((_) => null, (c) => c ?? true);
      if (completed != null) {
        if (completed) {
          await OnboardingCompletionCache.markCompleted('client', uid);
        }
        return completed;
      }
    } catch (_) {
      // Timeout / unexpected error: inconclusive, retry then fall back.
    }
  }
  return OnboardingCompletionCache.wasCompleted('client', uid);
}
