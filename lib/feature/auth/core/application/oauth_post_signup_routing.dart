import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/core/result.dart';
import '../../../../types.dart';
import '../domain/entities/user_profile_basics.dart';

/// Role the user chose on role selection / signup before Google or Apple
/// sign-in started. Captured by the shell when OAuth begins.
final oauthSignupIntendedRoleProvider = StateProvider<UserRole?>(
  (ref) => null,
);

/// Set immediately after `/users/{uid}` is written during OAuth completion.
/// While non-null, the shell must not sign the user out when Firestore reads
/// lag — it retries longer and falls back to this role.
final oauthSignupFreshProfileRoleProvider = StateProvider<UserRole?>(
  (ref) => null,
);

/// Clears OAuth routing hints after navigation completes or the flow aborts.
void clearOAuthSignupRoutingHints(Ref ref) {
  ref.read(oauthSignupIntendedRoleProvider.notifier).state = null;
  ref.read(oauthSignupFreshProfileRoleProvider.notifier).state = null;
}

/// Same as [clearOAuthSignupRoutingHints] for [WidgetRef] in the shell.
void clearOAuthSignupRoutingHintsFromWidget(WidgetRef ref) {
  ref.read(oauthSignupIntendedRoleProvider.notifier).state = null;
  ref.read(oauthSignupFreshProfileRoleProvider.notifier).state = null;
}

/// Resolves the role for the OAuth completion form: explicit shell role wins,
/// then the role captured at OAuth start, then client default.
UserRole resolveOAuthCompletionRole({
  required UserRole shellRole,
  UserRole? intendedRole,
}) {
  if (shellRole == UserRole.merchant) return UserRole.merchant;
  return intendedRole ?? shellRole;
}

/// Waits for Firestore to expose the role after a fresh OAuth profile write.
Future<UserRole?> resolveRoleAfterFreshOAuthSignup({
  required Future<Result<UserRole?>> Function() fetchRole,
  required UserRole intendedRole,
  int maxAttempts = 10,
}) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    if (attempt > 0) {
      await Future.delayed(Duration(milliseconds: 150 * attempt));
    }
    try {
      final result =
          await fetchRole().timeout(const Duration(seconds: 3));
      final role = result.fold<UserRole?>(
        (_) => null,
        (UserRole? r) => r,
      );
      if (role != null) return role;
    } catch (_) {
      // Retry on timeout / transient errors.
    }
  }
  return intendedRole;
}

/// Waits until `/users/{uid}` basics exist (post OAuth write).
Future<bool> waitForFirestoreProfileBasics({
  required Future<Result<UserProfileBasics?>> Function() fetchBasics,
  int maxAttempts = 10,
}) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    if (attempt > 0) {
      await Future.delayed(Duration(milliseconds: 150 * attempt));
    }
    try {
      final result =
          await fetchBasics().timeout(const Duration(seconds: 3));
      final found = result.fold<bool>(
        (_) => false,
        (UserProfileBasics? basics) => basics != null,
      );
      if (found) return true;
    } catch (_) {
      // Retry.
    }
  }
  return false;
}
