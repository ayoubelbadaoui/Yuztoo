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
      final city = widget.city;
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
                ? 'Impossible de vérifier l\'adresse email.'
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
          // Firestore profile write must run even if this route is disposed (shell → splash).
          await _createFirestoreProfile(
            authUser.id,
            createUserDocUseCase: createUserDocUseCase,
            roleCache: roleCache,
            getUserRole: getUserRole,
            email: email,
            phone: phone,
            city: city,
            signupRole: signupRole,
          );
        },
      );
    } finally {
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
    required String city,
    required UserRole signupRole,
  }) async {
    final Map<String, bool> roles = signupRolesMap(signupRole);

    final createResult = await createUserDocUseCase.call(
      uid: userId,
      email: email,
      phone: phone,
      roles: roles,
      city: city,
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

        // Auth often emits before Firestore `createUserDocument` finishes; refresh so
        // [main] re-runs routing and shows client onboarding (same idea as merchant gate).
        await ref.read(auth_core.authControllerProvider.notifier).refreshAuthState();
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
