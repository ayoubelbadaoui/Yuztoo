import 'package:equatable/equatable.dart';

import '../../../core/domain/entities/auth_user.dart';

/// Identifier for the social provider currently driving the OAuth signup flow.
///
/// Kept in [OAuthSignupAuthenticating] so the loading overlay can show
/// provider-specific copy (`Connexion à Google…` / `Connexion à Apple…`)
/// without UI re-querying the controller.
enum OAuthSignupProvider { google, apple }

/// State machine for the OAuth (Google / Apple) signup flow.
///
/// Replaces the previous inline orchestration in `signup_screen.part.dart`
/// where every error path called `signOut()` silently. The new flow keeps
/// the user signed in until they explicitly cancel, and surfaces every
/// failure via a recoverable [OAuthSignupError] state — never via a
/// snackbar that the keyboard can hide on Android.
sealed class OAuthSignupState extends Equatable {
  const OAuthSignupState();

  @override
  List<Object?> get props => <Object?>[];
}

/// No OAuth flow is in progress. Default state.
class OAuthSignupIdle extends OAuthSignupState {
  const OAuthSignupIdle();
}

/// The Google / Apple credential exchange is in progress.
///
/// UI: full-page loading overlay on the signup screen while the
/// provider sheet is presented and the credential is exchanged with
/// Firebase Auth.
class OAuthSignupAuthenticating extends OAuthSignupState {
  const OAuthSignupAuthenticating(this.provider);

  final OAuthSignupProvider provider;

  @override
  List<Object?> get props => <Object?>[provider];
}

/// OAuth credential succeeded; we are now reading `/users/{uid}` to decide
/// whether this is an existing user or a brand-new signup.
///
/// UI: full-page loading overlay (`Vérification de votre compte…`).
class OAuthSignupResolvingProfile extends OAuthSignupState {
  const OAuthSignupResolvingProfile();
}

/// Existing user — Firestore profile already exists. The auth state will
/// refresh and the shell's normal routing takes over.
///
/// UI: full-page loading overlay (`Connexion…`) until the shell unmounts
/// the signup screen.
class OAuthSignupExistingUser extends OAuthSignupState {
  const OAuthSignupExistingUser();
}

/// Brand-new OAuth user — needs to provide phone (and optionally name when
/// Apple did not return one). The shell navigates to the OAuth completion
/// screen on this state.
///
/// While this state holds, [oauthFirestoreProfilePendingProvider] stays
/// `true` so the shell does not try to auto-route the half-formed account.
class OAuthSignupNeedsCompletion extends OAuthSignupState {
  const OAuthSignupNeedsCompletion({
    required this.authUser,
    required this.needsName,
    required this.provider,
  });

  /// Firebase Auth user just signed in via Google / Apple.
  final AuthUser authUser;

  /// `true` when the provider returned no name (Google with no Name scope).
  /// Never `true` for Apple — App Store requires using Authentication
  /// Services data instead of prompting for name/email after Sign in with Apple.
  final bool needsName;

  final OAuthSignupProvider provider;

  @override
  List<Object?> get props => <Object?>[authUser, needsName, provider];
}

/// The completion form was submitted — verifying phone availability and
/// writing `/users/{uid}`.
///
/// UI: completion screen shows submit-loading on its primary CTA. The
/// rest of the form is disabled.
class OAuthSignupSubmitting extends OAuthSignupState {
  const OAuthSignupSubmitting({
    required this.authUser,
    required this.needsName,
    this.provider = OAuthSignupProvider.google,
  });

  final AuthUser authUser;
  final bool needsName;
  final OAuthSignupProvider provider;

  @override
  List<Object?> get props => <Object?>[authUser, needsName, provider];
}

/// Profile created — auth state refreshed. Shell will now route to
/// onboarding or home based on role.
class OAuthSignupCompleted extends OAuthSignupState {
  const OAuthSignupCompleted();
}

/// Recoverable failure. The Firebase Auth session is **not** signed out;
/// the user can retry without re-running the whole OAuth dance.
///
/// When [authUser] is non-null the failure happened **after** OAuth
/// succeeded (e.g. phone availability or createUserDocument failed). The
/// completion screen stays mounted, restoring the form so the user can
/// fix the value and retry.
///
/// When [authUser] is null the failure happened during the OAuth
/// credential exchange or profile resolution — the signup screen is
/// shown again with the error message.
class OAuthSignupError extends OAuthSignupState {
  const OAuthSignupError({
    required this.message,
    this.authUser,
    this.needsName = false,
    this.provider = OAuthSignupProvider.google,
  });

  final String message;
  final AuthUser? authUser;
  final bool needsName;
  final OAuthSignupProvider provider;

  @override
  List<Object?> get props => <Object?>[message, authUser, needsName, provider];
}
