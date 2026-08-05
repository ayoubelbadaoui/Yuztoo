import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/application/auth_controller.dart';
import '../../core/application/auth_error_mapper.dart';
import '../../core/application/use_cases/sign_out.dart';
import '../../core/application/use_cases/update_last_login_at.dart';
import '../../core/application/use_cases/patch_user_document.dart';
import '../../core/domain/entities/auth_user.dart';
import '../../../../types.dart';
import 'finalize_oauth_signup.dart';
import 'oauth_signup_outcome.dart';
import 'start_oauth_signup.dart';
import 'state/oauth_signup_state.dart';

/// Drives the Google / Apple signup flow in a Riverpod-friendly way.
///
/// The previous inline orchestration in `signup_screen.part.dart`:
///   - showed an `AlertDialog` for phone collection (any dismiss = silent
///     signOut),
///   - had six separate paths that called `signOut()` silently,
///   - relied on snackbars that the on-screen keyboard could hide,
///   - kept the "social loading" spinner stuck on success because
///     clearing it raced with the shell unmounting the screen.
///
/// This controller centralises all of that behaviour so:
///   - the user is never signed out without an explicit cancel,
///   - error messages live on a state field (rendered inline by the UI,
///     never as a snackbar that can be hidden by the keyboard),
///   - the OAuth Firebase session is preserved across retries on the
///     completion screen so the user does not have to re-OAuth after a
///     failed phone-availability check.
class OAuthSignupController extends StateNotifier<OAuthSignupState> {
  OAuthSignupController({
    required StartOAuthSignup startOAuthSignup,
    required FinalizeOAuthSignup finalizeOAuthSignup,
    required SignOut signOut,
    required UpdateLastLoginAt updateLastLoginAt,
    required PatchUserDocument patchUserDocument,
    required AuthController authController,
    required void Function(bool pending) setOAuthFirestorePending,
    required void Function(UserRole role) setFreshProfileRole,
    required void Function() clearRoutingHints,
    required UserRole Function() getOAuthCompletionRole,
  })  : _startOAuthSignup = startOAuthSignup,
        _finalizeOAuthSignup = finalizeOAuthSignup,
        _signOut = signOut,
        _updateLastLoginAt = updateLastLoginAt,
        _patchUserDocument = patchUserDocument,
        _authController = authController,
        _setOAuthFirestorePending = setOAuthFirestorePending,
        _setFreshProfileRole = setFreshProfileRole,
        _clearRoutingHints = clearRoutingHints,
        _getOAuthCompletionRole = getOAuthCompletionRole,
        super(const OAuthSignupIdle());

  final StartOAuthSignup _startOAuthSignup;
  final FinalizeOAuthSignup _finalizeOAuthSignup;
  final SignOut _signOut;
  final UpdateLastLoginAt _updateLastLoginAt;
  final PatchUserDocument _patchUserDocument;
  final AuthController _authController;
  final void Function(bool pending) _setOAuthFirestorePending;
  final void Function(UserRole role) _setFreshProfileRole;
  final void Function() _clearRoutingHints;
  final UserRole Function() _getOAuthCompletionRole;

  /// Guard against double-tap on the Google / Apple buttons.
  bool get isBusy =>
      state is OAuthSignupAuthenticating ||
      state is OAuthSignupResolvingProfile ||
      state is OAuthSignupSubmitting;

  /// Kicks off Google sign-in for signup (or returns to the existing-user
  /// flow if `/users/{uid}` already exists).
  Future<void> startGoogle() => _start(OAuthSignupProvider.google);

  /// Kicks off Apple sign-in for signup. iOS-only at the call site
  /// (`Platform.isIOS` check) — this controller does not gate by platform.
  Future<void> startApple() => _start(OAuthSignupProvider.apple);

  Future<void> _start(OAuthSignupProvider provider) async {
    if (isBusy) return;
    _setOAuthFirestorePending(true);
    state = OAuthSignupAuthenticating(provider);

    final OAuthSignupOutcome outcome;
    switch (provider) {
      case OAuthSignupProvider.google:
        outcome = await _startOAuthSignup.google();
        break;
      case OAuthSignupProvider.apple:
        outcome = await _startOAuthSignup.apple();
        break;
    }

    if (outcome is OAuthSignupOutcomeFailure) {
      _setOAuthFirestorePending(false);
      _clearRoutingHints();
      if (outcome.cancelled) {
        // Sheet dismissed — silently return to the signup form. No error
        // banner: cancellation is not a failure.
        state = const OAuthSignupIdle();
        return;
      }
      state = OAuthSignupError(
        message: AuthErrorMapper.displayMessage(outcome.failure),
      );
      return;
    }

    if (outcome is OAuthSignupOutcomeExistingUser) {
      // Existing user — let the shell drive routing. Keep the spinner
      // visible until the auth stream re-emits and the shell unmounts
      // the signup screen. Clearing the pending flag IS what unblocks
      // the shell, so it must come BEFORE the refresh.
      _setOAuthFirestorePending(false);
      state = const OAuthSignupExistingUser();
      unawaited(_authController.refreshAuthState());
      return;
    }

    if (outcome is OAuthSignupOutcomeNeedsCompletion) {
      if (outcome.provider == OAuthSignupProvider.apple) {
        // App Store Guideline 4: never prompt for name/email after Sign in
        // with Apple — finalize immediately using Authentication Services data.
        await _finalizeNewOAuthUser(
          authUser: outcome.authUser,
          needsName: false,
          provider: OAuthSignupProvider.apple,
          role: _getOAuthCompletionRole(),
          phoneE164: '',
        );
        return;
      }
      state = OAuthSignupNeedsCompletion(
        authUser: outcome.authUser,
        needsName: outcome.needsName,
        provider: outcome.provider,
      );
      return;
    }
  }

  Future<void> _finalizeNewOAuthUser({
    required AuthUser authUser,
    required bool needsName,
    required OAuthSignupProvider provider,
    required UserRole role,
    required String phoneE164,
    String? firstName,
    String? lastName,
  }) async {
    state = OAuthSignupSubmitting(
      authUser: authUser,
      needsName: needsName,
      provider: provider,
    );

    final result = await _finalizeOAuthSignup.call(
      authUser: authUser,
      role: role,
      phoneNumber: phoneE164,
      firstNameOverride: firstName,
      lastNameOverride: lastName,
    );

    if (result.isLeft) {
      if (provider == OAuthSignupProvider.apple) {
        state = OAuthSignupError(
          message: AuthErrorMapper.displayMessage(result.leftOrNull!),
          authUser: authUser,
          needsName: false,
          provider: provider,
        );
        return;
      }
      state = OAuthSignupError(
        message: AuthErrorMapper.displayMessage(result.leftOrNull!),
        authUser: authUser,
        needsName: needsName,
        provider: provider,
      );
      return;
    }

    try {
      await _patchUserDocument.call(authUser.id);
    } catch (_) {}
    try {
      await _updateLastLoginAt.call(
        authUser.id,
        displayName: authUser.displayName,
        photoUrl: authUser.photoUrl,
      );
    } catch (_) {}

    _setFreshProfileRole(role);
    _setOAuthFirestorePending(false);
    state = const OAuthSignupCompleted();
    unawaited(_authController.refreshAuthState());
  }

  /// Submits the completion form (phone + optional first/last name) for a
  /// new OAuth user. Verifies phone availability and writes
  /// `/users/{uid}`. On any failure, restores the form so the user can
  /// fix the value and retry **without** re-running OAuth.
  Future<void> submitCompletion({
    required UserRole role,
    required String phoneE164,
    String? firstName,
    String? lastName,
  }) async {
    final current = state;
    final AuthUser authUser;
    final bool needsName;
    final OAuthSignupProvider provider;
    if (current is OAuthSignupNeedsCompletion) {
      authUser = current.authUser;
      needsName = current.needsName;
      provider = current.provider;
    } else if (current is OAuthSignupError && current.authUser != null) {
      authUser = current.authUser!;
      needsName = current.needsName;
      provider = current.provider;
    } else {
      state = const OAuthSignupError(
        message: 'État inattendu. Réessayez la connexion via Google ou Apple.',
      );
      return;
    }

    await _finalizeNewOAuthUser(
      authUser: authUser,
      needsName: needsName,
      provider: provider,
      role: role,
      phoneE164: phoneE164,
      firstName: firstName,
      lastName: lastName,
    );
  }

  /// User explicitly tapped "Annuler" on the completion screen, or
  /// pressed the system back button. Sign the OAuth Firebase session out
  /// so the orphan auth user does not block a future signup attempt with
  /// the same email/password provider.
  Future<void> cancelCompletion() async {
    _setOAuthFirestorePending(false);
    _clearRoutingHints();
    state = const OAuthSignupIdle();
    try {
      await _signOut.call();
    } catch (_) {
      // Best-effort — `_signOut` errors are surfaced through the auth
      // controller's stream; not worth blocking the UI on.
    }
  }

  /// Clears a transient error so the signup screen renders the normal
  /// form again (used after the user reads / dismisses the error).
  void dismissError() {
    if (state is OAuthSignupError) {
      final err = state as OAuthSignupError;
      if (err.authUser != null) {
        state = OAuthSignupNeedsCompletion(
          authUser: err.authUser!,
          needsName: err.needsName,
          provider: err.provider,
        );
      } else {
        state = const OAuthSignupIdle();
      }
    }
  }

  /// Resets to idle. Called on logout / account deletion so a stale
  /// terminal state does not bleed into the next login or signup mount.
  void reset() {
    _setOAuthFirestorePending(false);
    _clearRoutingHints();
    state = const OAuthSignupIdle();
  }

  /// Clears only the terminal UI states ([OAuthSignupExistingUser] /
  /// [OAuthSignupCompleted]) after the shell has started home routing.
  ///
  /// Unlike [reset], this does **not** clear [oauthSignupFreshProfileRoleProvider]
  /// — `_handleAuthenticatedUser` may still need that hint while Firestore
  /// catches up after a brand-new OAuth profile write.
  void acknowledgeShellRouted() {
    if (state is OAuthSignupExistingUser || state is OAuthSignupCompleted) {
      state = const OAuthSignupIdle();
    }
  }
}
