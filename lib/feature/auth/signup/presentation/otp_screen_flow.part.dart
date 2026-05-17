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
      final getUserRole = ref.read(auth_core.getUserRoleProvider);

      final email = widget.email;
      final password = widget.password;
      final phone = widget.phone;
      final signupRole = widget.role;

      final emailCheck = await verifyEmail.call(email: email);
      var emailBlocked = false;
      final emailError = emailCheck.fold<String?>(
        (failure) {
          emailBlocked = true;
          return AuthErrorMapper.getFrenchMessage(failure) ?? failure.message;
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

      final phoneCheck = await verifyPhone.call(phoneNumber: phone);
      var phoneBlocked = false;
      final phoneError = phoneCheck.fold<String?>(
        (failure) {
          phoneBlocked = true;
          return AuthErrorMapper.getFrenchMessage(failure) ?? failure.message;
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
      ref
          .read(auth_core.oauthFirestoreProfilePendingProvider.notifier)
          .state = true;

      final verifyResult = await verifyPhoneAndCreateUserUseCase.call(
        verificationId: widget.verificationId!,
        smsCode: smsCode,
        email: email,
        password: password,
      );

      await verifyResult.fold<Future<void>>(
        (failure) async {
          if (mounted) {
            final frenchMessage = AuthErrorMapper.getFrenchMessage(failure);
            if (frenchMessage != null) {
              showErrorSnackbar(context, frenchMessage);
            }
            for (final controller in _controllers) {
              controller.clear();
            }
            _focusNodes[0].requestFocus();
          }
        },
        (authUser) async {
          await _createFirestoreProfile(
            authUser.id,
            createUserDocUseCase: createUserDocUseCase,
            roleCache: roleCache,
            getUserRole: getUserRole,
            email: email,
            phone: phone,
            signupRole: signupRole,
          );
        },
      );
    } finally {
      // Always clear the signup-in-progress guard so the shell is not stuck.
      try {
        ref
            .read(auth_core.oauthFirestoreProfilePendingProvider.notifier)
            .state = false;
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
    required GetUserRole getUserRole,
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
        if (mounted) {
          final frenchMessage = AuthErrorMapper.getFrenchMessage(failure);
          if (frenchMessage != null) {
            showErrorSnackbar(context, frenchMessage);
          }
        }
      },
      (_) async {
        try {
          await roleCache.saveLastSelectedRole(signupRole);
        } catch (_) {}

        UserRole? verifiedRole;
        for (var attempt = 0; attempt < 2 && verifiedRole == null; attempt++) {
          if (attempt > 0) {
            await Future<void>.delayed(const Duration(milliseconds: 200));
          }
          try {
            final roleResult = await getUserRole.call(userId).timeout(
              const Duration(seconds: 3),
            );
            verifiedRole = roleResult.fold(
              (_) => null,
              (r) => r,
            );
            if (verifiedRole != null) break;
          } catch (_) {
            continue;
          }
        }

        if (mounted) {
          showSuccessSnackbar(context, 'Inscription réussie!');
        }

        // Clear the guard BEFORE refreshAuthState so the shell can now
        // handle the auth-state change and route to onboarding.
        try {
          ref
              .read(auth_core.oauthFirestoreProfilePendingProvider.notifier)
              .state = false;
        } catch (_) {}

        // Defer the auth refresh to the next frame so the OTP screen
        // has time to finish the current build/setState cycle before
        // the shell yanks it out of the tree. Awaiting it inline races
        // with the `finally` block's `_setVerifying(false)` setState —
        // the shell navigates first, the OTP element starts unmounting,
        // then setState dirties dependents on the disposing inherited
        // element → 'package:flutter/src/widgets/framework.dart:6171
        // _dependents.isEmpty: is not true'. Deferring + not awaiting
        // keeps the unmount serialized after the OTP rebuild.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(
            ref
                .read(auth_core.authControllerProvider.notifier)
                .refreshAuthState(),
          );
        });
      },
    );
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
          final frenchMessage = AuthErrorMapper.getFrenchMessage(failure);
          // Only show error if it's a specific Firebase error (not generic)
          if (frenchMessage != null) {
            showErrorSnackbar(context, frenchMessage);
          }
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
