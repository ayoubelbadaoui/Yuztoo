import '../../core/domain/entities/auth_user.dart';
import '../../../../core/domain/core/failure.dart';
import 'state/oauth_signup_state.dart';

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
/// collect optional phone (Google only) and call [FinalizeOAuthSignup].
/// Apple sign-ups must auto-finalize without prompting for name/email.
class OAuthSignupOutcomeNeedsCompletion extends OAuthSignupOutcome {
  const OAuthSignupOutcomeNeedsCompletion({
    required this.authUser,
    required this.needsName,
    required this.provider,
  });

  final AuthUser authUser;
  final bool needsName;
  final OAuthSignupProvider provider;
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
