part of 'otp_screen.dart';

extension _OTPScreenFlow on _OTPScreenState {
  Future<void> _verifyOTP(String smsCode) async {
    if (widget.verificationId == null || widget.verificationId!.isEmpty) {
      if (mounted) {
        showErrorSnackbar(context, 'Erreur: ID de vérification manquant');
      }
      return;
    }

    _setVerifying(true);

    // Capture EVERYTHING we need from `ref` before the first await. While
    // sign-in / Firestore writes are in flight the shell can swap screens
    // (e.g. to the loading screen on an AuthLoading emission), which disposes
    // this widget — any later `ref` use then throws "Cannot use ref after the
    // widget was disposed", the pending flag stays stuck at `true`, and the
    // shell never routes the freshly created account (user stuck on OTP).
    final pendingNotifier =
        ref.read(auth_core.oauthFirestoreProfilePendingProvider.notifier);
    final authController = ref.read(auth_core.authControllerProvider.notifier);
    final authRepository = ref.read(auth_core.authRepositoryProvider);
    final signOutUseCase = ref.read(auth_core.signOutProvider);

    try {
      // Re-check duplicates here too. This prevents a transient Firebase Auth
      // sign-in for an existing account from bouncing the shell before we can
      // reject the signup attempt.
      final verifyEmail = ref.read(verifyEmailAvailableForSignupProvider);
      final verifyPhone = ref.read(verifyPhoneAvailableForSignupProvider);
      final verifyPhoneAndCreateUserUseCase =
          ref.read(verifyPhoneAndCreateUserProvider);
      final createUserDocUseCase = ref.read(createUserDocumentProvider);
      final roleCache = ref.read(auth_core.roleCacheServiceProvider);

      final email = widget.email;
      final password = widget.password;
      final phone = widget.phone;
      final signupRole = widget.role;

      // Both checks are independent Firestore reads — run them in parallel
      // instead of back-to-back to halve the pre-verification latency.
      final checks = await Future.wait([
        verifyEmail.call(email: email),
        verifyPhone.call(phoneNumber: phone),
      ]);
      final emailCheck = checks[0];
      final phoneCheck = checks[1];
      var emailBlocked = false;
      final emailError = emailCheck.fold<String?>(
        (failure) {
          emailBlocked = true;
          return AuthErrorMapper.displayMessage(failure);
        },
        (_) => null,
      );
      if (emailBlocked) {
        if (mounted) {
          showErrorSnackbar(
            context,
            (emailError == null || emailError.isEmpty)
                ? 'Impossible de vérifier l\'adresse e-mail.'
                : emailError,
          );
          for (final controller in _controllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        }
        return;
      }

      var phoneBlocked = false;
      final phoneError = phoneCheck.fold<String?>(
        (failure) {
          phoneBlocked = true;
          return AuthErrorMapper.displayMessage(failure);
        },
        (_) => null,
      );
      if (phoneBlocked) {
        if (mounted) {
          showErrorSnackbar(
            context,
            (phoneError == null || phoneError.isEmpty)
                ? 'Impossible de vérifier le numéro de téléphone.'
                : phoneError,
          );
          for (final controller in _controllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        }
        return;
      }

      // Set flag BEFORE signing in so the shell auth-state listener
      // does not interrupt us while Firestore doc creation is in flight.
      pendingNotifier.state = true;

      final verifyResult = await verifyPhoneAndCreateUserUseCase.call(
        verificationId: widget.verificationId!,
        smsCode: smsCode,
        email: email,
        password: password,
      );

      await verifyResult.fold<Future<void>>(
        (failure) async {
          if (mounted) {
            showErrorSnackbar(
              context,
              AuthErrorMapper.displayMessage(failure),
            );
            for (final controller in _controllers) {
              controller.clear();
            }
            _focusNodes[0].requestFocus();
          }
        },
        (authUser) async {
          // Code accepted — the Firebase Auth account exists. Swap the OTP
          // form for the full-screen loading view right away so profile
          // finalization doesn't look like a frozen screen.
          _setFinalizing(true);
          await _createFirestoreProfile(
            authUser.id,
            createUserDocUseCase: createUserDocUseCase,
            roleCache: roleCache,
            pendingNotifier: pendingNotifier,
            authController: authController,
            authRepository: authRepository,
            signOutUseCase: signOutUseCase,
            email: email,
            phone: phone,
            signupRole: signupRole,
          );
        },
      );
    } catch (e, st) {
      // Unexpected error mid-flow: restore the OTP form so the user is not
      // stranded on the finalizing view, then let the error propagate to
      // the crash reporter.
      _setFinalizing(false);
      if (mounted) {
        showErrorSnackbar(
          context,
          AuthErrorMapper.displayMessage(
            AuthUnexpectedFailure(cause: e, stackTrace: st),
          ),
        );
      }
      rethrow;
    } finally {
      // Always clear the signup-in-progress guard so the shell is not stuck.
      // Uses the captured notifier: it stays valid even if this widget was
      // disposed while the flow was in flight.
      try {
        pendingNotifier.state = false;
      } catch (_) {}
      if (mounted) {
        _setVerifying(false);
      }
    }
  }

  Future<void> _createFirestoreProfile(
    String userId, {
    required CreateUserDocument createUserDocUseCase,
    required auth_core.RoleCacheService roleCache,
    required StateController<bool> pendingNotifier,
    required AuthController authController,
    required AuthRepository authRepository,
    required SignOut signOutUseCase,
    required String email,
    required String phone,
    required UserRole signupRole,
  }) async {
    final Map<String, bool> roles = signupRolesMap(signupRole);

    final createResult = await createUserDocUseCase.call(
      uid: userId,
      email: email,
      phone: phone,
      roles: roles,
    );

    await createResult.fold<Future<void>>(
      (failure) async {
        // The Firebase Auth user we just created in `verifyPhoneAndCreateUser`
        // (phone + email + password) has no Firestore profile yet. If we leave
        // it as-is, the email and phone stay claimed in Firebase Auth and
        // any subsequent signup with the same email is blocked with
        // `email-already-in-use`. Roll it back so the user can retry cleanly
        // — this is the documented "state cleanup on failed verification"
        // requirement.
        await _rollbackOrphanFirebaseAuthUser(
          authRepository: authRepository,
          signOutUseCase: signOutUseCase,
        );

        _setFinalizing(false);
        if (mounted) {
          showErrorSnackbar(
            context,
            AuthErrorMapper.displayMessage(failure),
          );
        }
      },
      (_) async {
        try {
          await roleCache.saveLastSelectedRole(signupRole);
        } catch (_) {}

        // NOTE: no role-verification polling here. The doc write above was
        // awaited and the shell's routing already retries role lookups —
        // polling again from this screen only froze the OTP UI for seconds.

        try {
          pendingNotifier.state = false;
        } catch (_) {}

        // Reload profile from Firestore (roles, primary_role) — unlike
        // refreshAuthState(), this always pushes a new Authenticated state.
        // Uses the captured controller so this still runs when the shell has
        // already disposed this widget — the new Authenticated emission is
        // what lets the shell route the fresh account to onboarding/home.
        await authController.reloadProfile();

        if (!mounted) return;

        final authAfterReload = ref.read(auth_core.authControllerProvider);
        if (authAfterReload is! Authenticated) {
          _setFinalizing(false);
          showErrorSnackbar(
            context,
            'Compte créé. Relancez l\'application pour continuer.',
          );
          return;
        }

        showSuccessSnackbar(context, 'Inscription réussie!');

        // Fallback route — normally the reloadProfile() emission above already
        // drives the shell's routing; this only fires when the auth stream
        // didn't re-emit (the shell ignores it while navigation is in flight).
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.onSignupComplete?.call();
        });
      },
    );
  }

  /// Best-effort cleanup of the Firebase Auth user that
  /// `verifyPhoneAndCreateUser` just created (phone + email/password linked)
  /// when the Firestore profile write failed afterwards.
  ///
  /// Without this rollback, the email and phone stay claimed by an orphan
  /// Firebase Auth user and any retry with the same email yields
  /// `email-already-in-use`, which is the symptom we are fixing.
  ///
  /// This is the auth-only delete path — the Firestore profile does not
  /// exist yet, so there is no GDPR cascade to perform. We must NOT call
  /// the `purgeAccount` Cloud Function here because the user has no
  /// merchant doc, no loyalty footprint, etc. Calling it would only add
  /// latency and could fail in environments where CFs aren't reachable.
  ///
  /// Takes the repository and sign-out use case as parameters (captured
  /// before the first await in [_verifyOTP]) so the rollback still works
  /// when this widget was disposed mid-flow.
  Future<void> _rollbackOrphanFirebaseAuthUser({
    required AuthRepository authRepository,
    required SignOut signOutUseCase,
  }) async {
    try {
      // We do not act on the success/failure of the delete here — if it
      // worked, the user is gone and the email/phone are released; if it
      // didn't, the signOut below at least keeps the shell from booting
      // the orphan as a logged-in session. The auth-only delete leaks at
      // most one Firebase Auth row and surfaces in support logs as the
      // failed signup attempt the user already saw an error for.
      await authRepository.deleteCurrentUser();
    } catch (_) {
      // Best-effort — fall through to signOut below.
    }
    try {
      await signOutUseCase.call();
    } catch (_) {}
  }

  Future<void> _handleResend() async {
    if (_otpBlocked) {
      if (mounted && _otpUnavailableMessage != null) {
        showErrorSnackbar(context, _otpUnavailableMessage!);
      }
      return;
    }
    if (!_canResend) return;

    final sendOtpUseCase = ref.read(sendPhoneVerificationProvider);
    final otpResult = await sendOtpUseCase.call(phoneNumber: widget.phone);

    otpResult.fold(
      (failure) {
        if (mounted) {
          showErrorSnackbar(
            context,
            AuthErrorMapper.displayMessage(failure),
          );
        }
      },
      (verificationId) {
        if (mounted) {
          showSuccessSnackbar(context, 'Code de vérification renvoyé!');
          _startResendTimer();
          widget.onResend();
        }
      },
    );
  }
}
