import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/core/failure.dart';
import '../../../../core/infrastructure/logger_service.dart';
import '../../core/application/providers.dart' as auth_core;
import '../../core/domain/auth_failure.dart';
import '../../core/domain/repositories/auth_repository.dart';
import '../../core/infrastructure/auth_repository_provider.dart';
import '../../core/infrastructure/user_repository_provider.dart';
import '../../login/application/providers.dart' as login_providers;
import 'delete_account_exception.dart';
import 'finalize_oauth_signup.dart';
import 'oauth_signup_controller.dart';
import 'send_phone_verification.dart';
import 'start_oauth_signup.dart';
import 'state/oauth_signup_state.dart';
import 'verify_phone_available_for_signup.dart';
import 'verify_email_available_for_signup.dart';
import 'verify_and_link_phone.dart';
import 'verify_phone_and_create_user.dart';
import 'create_user_document.dart';

final sendPhoneVerificationProvider =
    Provider<SendPhoneVerification>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SendPhoneVerification(repository);
});

final verifyPhoneAvailableForSignupProvider =
    Provider<VerifyPhoneAvailableForSignup>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return VerifyPhoneAvailableForSignup(userRepository);
});

final verifyEmailAvailableForSignupProvider =
    Provider<VerifyEmailAvailableForSignup>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return VerifyEmailAvailableForSignup(userRepository);
});

final verifyAndLinkPhoneProvider = Provider<VerifyAndLinkPhone>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return VerifyAndLinkPhone(repository);
});

final verifyPhoneAndCreateUserProvider = Provider<VerifyPhoneAndCreateUser>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return VerifyPhoneAndCreateUser(repository);
});

final createUserDocumentProvider = Provider<CreateUserDocument>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return CreateUserDocument(repository);
});

/// Use case provider for starting the Google / Apple signup flow.
///
/// Returns a pure-domain [OAuthSignupOutcome] for the controller to
/// translate into UI state — no Riverpod / Flutter dependencies.
final startOAuthSignupProvider = Provider<StartOAuthSignup>((ref) {
  return StartOAuthSignup(
    signInWithGoogle: ref.watch(login_providers.signInWithGoogleProvider),
    signInWithApple: ref.watch(login_providers.signInWithAppleProvider),
    userRepository: ref.watch(userRepositoryProvider),
  );
});

/// Use case provider for finalising a brand-new OAuth signup
/// (phone availability + `/users/{uid}` write).
final finalizeOAuthSignupProvider = Provider<FinalizeOAuthSignup>((ref) {
  return FinalizeOAuthSignup(
    verifyEmail: ref.watch(verifyEmailAvailableForSignupProvider),
    verifyPhone: ref.watch(verifyPhoneAvailableForSignupProvider),
    createUserDocument: ref.watch(createUserDocumentProvider),
  );
});

/// Controller for the Google / Apple signup flow. Replaces the inline
/// orchestration in `signup_screen.part.dart` (which had silent signOut
/// paths and an `AlertDialog` for phone collection).
final oauthSignupControllerProvider =
    StateNotifierProvider<OAuthSignupController, OAuthSignupState>((ref) {
  final controller = OAuthSignupController(
    startOAuthSignup: ref.watch(startOAuthSignupProvider),
    finalizeOAuthSignup: ref.watch(finalizeOAuthSignupProvider),
    signOut: ref.watch(auth_core.signOutProvider),
    updateLastLoginAt: ref.watch(auth_core.updateLastLoginAtProvider),
    patchUserDocument: ref.watch(auth_core.patchUserDocumentProvider),
    authController: ref.watch(auth_core.authControllerProvider.notifier),
    setOAuthFirestorePending: (pending) {
      ref
          .read(auth_core.oauthFirestoreProfilePendingProvider.notifier)
          .state = pending;
    },
  );
  return controller;
});

final deleteCurrentUserProvider = Provider<DeleteCurrentUser>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return DeleteCurrentUser(
    repository,
    onSignedOut: () =>
        ref.read(auth_core.authControllerProvider.notifier).signOut(),
  );
});

/// GDPR right-to-erasure entry point. Production calls the `purgeAccount`
/// Cloud Function which:
///   1. Cascades Firestore data (loyalty footprint at every followed
///      merchant, push tokens, notifications, blocked merchants, AND the
///      merchant document itself for dual-profile users).
///   2. Frees email_index / phone_index entries so the same identifier
///      can be reused at re-signup.
///   3. Deletes the Firebase Auth user.
///
/// The legacy auth-only delete (`AuthRepository.deleteCurrentUser`) is
/// kept as a fallback for environments where Cloud Functions aren't
/// reachable (CI, the Firebase emulator without functions emulator, etc).
/// In production we ALWAYS prefer the Cloud Function because the auth-only
/// path leaves a Firestore footprint that violates GDPR Art. 17.
class DeleteCurrentUser {
  const DeleteCurrentUser(
    this._repository, {
    required Future<void> Function() onSignedOut,
  }) : _onSignedOut = onSignedOut;

  final AuthRepository _repository;
  final Future<void> Function() _onSignedOut;

  /// Auth-only delete succeeded, or user is already gone (e.g. CF removed auth).
  Future<void> _applyAuthDeleteResult() async {
    final result = await _repository.deleteCurrentUser();
    result.fold(
      (AppFailure failure) {
        if (_authDeleteMeansAlreadySignedOut(failure)) {
          return;
        }
        throw DeleteAccountException(
          _userMessageForDeleteAuthFailure(failure),
        );
      },
      (_) {},
    );
  }

  Future<void> call() async {
    try {
      // Region must match the Cloud Function's deployment region. The
      // current `functions/src/index.ts` pins europe-west1; if that ever
      // moves, this constructor argument needs to follow.
      //
      // `purgeAccount` is deployed with timeoutSeconds: 540 and may recurse
      // large Firestore trees, collection-group deletes, and Storage cleanup.
      // The callable client default is only 60s — hitting that aborts the HTTP
      // call while the function may still be running, then the auth-only
      // fallback often fails (requires-recent-login), leaving the Auth user
      // intact. Match the server budget here.
      final functions = FirebaseFunctions.instanceFor(
        app: Firebase.app(),
        region: 'europe-west1',
      );
      await functions
          .httpsCallable(
            'purgeAccount',
            options: HttpsCallableOptions(
              timeout: const Duration(seconds: 540),
            ),
          )
          .call(<String, dynamic>{});
      // Admin SDK already removed the Auth user — still run the normal app
      // sign-out so [AuthController] → [Unauthenticated] and the shell routes
      // to role selection (push cleanup, FCM token, cached drafts).
      await _signOutSession();
      return;
    } on FirebaseFunctionsException catch (e, st) {
      LoggerService.logError(
        'purgeAccount callable failed',
        error: e,
        stackTrace: st,
        context: {'code': e.code, 'message': e.message, 'details': e.details},
      );
      if (e.code == 'unauthenticated') {
        throw DeleteAccountException(
          'Session expirée. Déconnectez-vous et reconnectez-vous, puis réessayez.',
        );
      }
      if (e.code == 'deadline-exceeded') {
        throw DeleteAccountException(
          'La suppression côté serveur a dépassé le délai. Attendez une minute '
          'puis réessayez (l\'opération peut encore se terminer). Si le problème '
          'persiste, contactez le support.',
        );
      }
      if (e.code == 'unavailable' || e.code == 'resource-exhausted') {
        throw DeleteAccountException(
          'Service momentanément indisponible. Vérifiez votre connexion et réessayez.',
        );
      }
      if (e.code == 'internal') {
        final detail = (e.message ?? '').trim();
        throw DeleteAccountException(
          detail.isNotEmpty
              ? 'Suppression impossible : $detail'
              : 'Suppression impossible côté serveur. Réessayez dans quelques minutes '
                  'ou contactez le support.',
        );
      }
      if (e.code == 'permission-denied' || e.code == 'failed-precondition') {
        throw DeleteAccountException(
          'Suppression refusée par le serveur. Réessayez après vous être reconnecté(e), '
          'ou contactez le support.',
        );
      }
      if (e.code == 'not-found') {
        throw DeleteAccountException(
          'Service de suppression indisponible. Mettez l\'application à jour et '
          'réessayez, ou contactez le support.',
        );
      }
      // Emulator / offline: auth-only delete (requires a fresh login session).
      if (kReleaseMode) {
        throw DeleteAccountException(
          'Suppression impossible pour le moment. Vérifiez votre connexion et réessayez.',
        );
      }
      await _applyAuthDeleteResult();
      await _signOutSession();
      return;
    } catch (e, st) {
      LoggerService.logError(
        'purgeAccount unexpected error before auth fallback',
        error: e,
        stackTrace: st,
      );
      await _applyAuthDeleteResult();
      await _signOutSession();
    }
  }

  Future<void> _signOutSession() async {
    try {
      await _onSignedOut();
    } catch (e, st) {
      LoggerService.logError(
        'signOut after account deletion (controller)',
        error: e,
        stackTrace: st,
      );
    }
    // Ensure the local Firebase session is cleared even if the controller
    // path failed (e.g. push-token cleanup error) or Auth was already removed
    // server-side by purgeAccount.
    try {
      (await _repository.signOut()).fold((_) {}, (_) {});
    } catch (e, st) {
      LoggerService.logError(
        'signOut after account deletion (repository)',
        error: e,
        stackTrace: st,
      );
    }
  }
}

bool _authDeleteMeansAlreadySignedOut(AppFailure failure) {
  return failure is AuthUnexpectedFailure &&
      failure.message == 'Aucun utilisateur connecté';
}

bool _isRecentLoginAuthFailure(AppFailure failure) {
  return failure is AuthUnexpectedFailure &&
      failure.message == 'Erreur de session.';
}

String _userMessageForDeleteAuthFailure(AppFailure failure) {
  if (_isRecentLoginAuthFailure(failure)) {
    return 'Pour des raisons de sécurité, déconnectez-vous puis reconnectez-vous '
        'et réessayez la suppression du compte.';
  }
  return failure.message;
}

