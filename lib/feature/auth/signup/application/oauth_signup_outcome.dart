import '../../core/domain/entities/auth_user.dart';
import '../../../../core/domain/core/failure.dart';

/// Pure-domain outcome of [StartOAuthSignup] — the use case that runs the
/// Google / Apple credential exchange + profile resolution.
///
/// Has no UI state: the controller maps these into [OAuthSignupState] for
/// the presentation layer.
sealed class OAuthSignupOutcome {
  const OAuthSignupOutcome();
}

/// Existing user — Firestore profile exists. Shell should refresh + route.
class OAuthSignupOutcomeExistingUser extends OAuthSignupOutcome {
  const OAuthSignupOutcomeExistingUser();
}

/// Brand-new OAuth user — `/users/{uid}` does not exist. Caller must
/// collect the phone (and optionally the name when [needsName] is true)
/// and call [CompleteOAuthSignup].
class OAuthSignupOutcomeNeedsCompletion extends OAuthSignupOutcome {
  const OAuthSignupOutcomeNeedsCompletion({
    required this.authUser,
    required this.needsName,
  });

  final AuthUser authUser;
  final bool needsName;
}

/// Recoverable failure during OAuth exchange or profile resolution. The
/// user is **not** signed out automatically — the controller can choose
/// to call [CancelOAuthSignup] if appropriate, but the default is to
/// surface the error and let the user retry.
class OAuthSignupOutcomeFailure extends OAuthSignupOutcome {
  const OAuthSignupOutcomeFailure({
    required this.failure,
    this.cancelled = false,
  });

  final AppFailure failure;

  /// `true` when the user dismissed the provider sheet — the caller
  /// should silently return to idle, not show an error.
  final bool cancelled;
}
