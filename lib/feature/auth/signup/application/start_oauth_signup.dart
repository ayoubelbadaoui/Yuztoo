import 'dart:async';

import '../../core/domain/auth_failure.dart';
import '../../core/domain/entities/auth_user.dart';
import '../../core/domain/repositories/user_repository.dart';
import '../../login/application/sign_in_with_social.dart';
import '../../../../core/domain/core/result.dart';
import 'oauth_signup_outcome.dart';
import 'state/oauth_signup_state.dart';

/// Drives the credential-exchange + profile-resolution part of an OAuth
/// signup attempt.
///
/// Sequence:
///   1. Run Google or Apple credential exchange via [SignInWithGoogle] /
///      [SignInWithApple] — these wrap [AuthRepository] and return a
///      Firebase-authenticated [AuthUser].
///   2. Read `/users/{uid}` (with one retry, 600 ms backoff) to decide
///      whether this is an existing user or a new signup.
///   3. Return an [OAuthSignupOutcome] for the controller to translate
///      into [OAuthSignupState] for the UI.
///
/// **Never signs the user out.** The previous inline orchestration in
/// `signup_screen.part.dart` had six different paths that called
/// `signOut()` silently — that is what produced the "screen looks frozen
/// after OAuth, no error, no dialog" symptom: any transient Firestore
/// read error during profile resolution silently signed the user out and
/// left the signup screen un-rebuilt because `inAuthFlow == true` skipped
/// shell routing.
class StartOAuthSignup {
  const StartOAuthSignup({
    required SignInWithGoogle signInWithGoogle,
    required SignInWithApple signInWithApple,
    required UserRepository userRepository,
  })  : _signInWithGoogle = signInWithGoogle,
        _signInWithApple = signInWithApple,
        _userRepository = userRepository;

  final SignInWithGoogle _signInWithGoogle;
  final SignInWithApple _signInWithApple;
  final UserRepository _userRepository;

  Future<OAuthSignupOutcome> google() =>
      _run(_signInWithGoogle.call, OAuthSignupProvider.google);

  Future<OAuthSignupOutcome> apple() =>
      _run(_signInWithApple.call, OAuthSignupProvider.apple);

  Future<OAuthSignupOutcome> _run(
    Future<Result<AuthUser>> Function() signIn,
    OAuthSignupProvider provider,
  ) async {
    final Result<AuthUser> credentialResult;
    try {
      credentialResult = await signIn();
    } catch (e, st) {
      return OAuthSignupOutcomeFailure(
        failure: AuthUnexpectedFailure(cause: e, stackTrace: st),
      );
    }

    final failure = credentialResult.leftOrNull;
    if (failure != null) {
      return OAuthSignupOutcomeFailure(
        failure: failure,
        cancelled: failure is UserCancelledFailure,
      );
    }

    final authUser = credentialResult.rightOrNull;
    if (authUser == null) {
      return const OAuthSignupOutcomeFailure(
        failure: AuthUnexpectedFailure(
          message:
              'Connexion impossible : aucun utilisateur retourné par le fournisseur.',
        ),
      );
    }

    final hasProfile = await _resolveHasProfile(authUser.id);

    if (hasProfile == null) {
      // Two consecutive Firestore reads errored. Surface the failure so
      // the caller can decide whether to retry. The previous inline path
      // signed the user out here, which is what produced the
      // "first-time only, no feedback" symptom — the user landed back on
      // the signup screen with the error snackbar hidden by the keyboard.
      return const OAuthSignupOutcomeFailure(
        failure: AuthUnexpectedFailure(
          message:
              'Impossible de vérifier votre compte. Vérifiez votre connexion et réessayez.',
        ),
      );
    }

    if (hasProfile) {
      return const OAuthSignupOutcomeExistingUser();
    }

    final email = authUser.email?.trim();
    if (email == null || email.isEmpty) {
      return const OAuthSignupOutcomeFailure(
        failure: AuthUnexpectedFailure(
          message:
              'Aucune adresse e-mail n’est associée à ce compte. Utilisez l’inscription par e-mail.',
        ),
      );
    }

    final needsName = provider != OAuthSignupProvider.apple &&
        _hasNoUsableName(authUser);
    return OAuthSignupOutcomeNeedsCompletion(
      authUser: authUser,
      needsName: needsName,
      provider: provider,
    );
  }

  /// Two-attempt profile lookup with a 600 ms backoff between tries.
  ///
  /// Returns:
  ///   - `true`  — `/users/{uid}` exists (existing user).
  ///   - `false` — definitively does not exist (new OAuth signup).
  ///   - `null`  — both attempts errored; caller MUST treat as
  ///                "cannot decide" rather than as "new user".
  Future<bool?> _resolveHasProfile(String uid) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
      }
      final result = await _userRepository.getUserProfileBasics(uid);
      final settled = result.fold<bool?>(
        (_) => null,
        (basics) => basics != null,
      );
      if (settled != null) return settled;
    }
    return null;
  }

  /// `true` when the OAuth provider gave us no usable name to write to
  /// Firestore. Apple's `givenName` / `familyName` are populated only on
  /// the **first** authorization per Apple-ID per app — every subsequent
  /// attempt returns blanks, so we must ask the user to type them.
  static bool _hasNoUsableName(AuthUser user) {
    if ((user.firstName?.trim().isNotEmpty ?? false) ||
        (user.lastName?.trim().isNotEmpty ?? false)) {
      return false;
    }
    final dn = user.displayName?.trim() ?? '';
    return dn.isEmpty;
  }
}
