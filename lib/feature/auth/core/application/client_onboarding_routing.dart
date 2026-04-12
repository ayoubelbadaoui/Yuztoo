import '../domain/repositories/user_repository.dart';
import 'use_cases/is_client_onboarding_completed.dart';

/// Firestore `users/{uid}.onboarding.client` based completion check.
///
/// Returns [true] when onboarding is completed, legacy (no `client` key), or the
/// user is not a client ([Result] value `null` from [UserRepository]).
/// Returns [false] when onboarding is still pending, the user doc is not ready yet,
/// or the read failed (fail-closed into onboarding).
Future<bool> clientOnboardingCompletedFromFirestore(
  UserRepository repository,
  String uid,
) async {
  try {
    final uc = IsClientOnboardingCompleted(repository);
    final result = await uc.call(uid);
    return result.fold((_) => false, (c) {
      if (c == null) return true;
      return c;
    });
  } catch (_) {
    return false;
  }
}
