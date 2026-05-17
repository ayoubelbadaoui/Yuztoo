part of 'signup_screen.dart';

extension _SignupScreenUi on _SignupScreenState {
  void _initControllers() {
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _passwordController =
        TextEditingController(text: widget.initialPassword ?? '');
    _confirmPasswordController =
        TextEditingController(text: widget.initialPassword ?? '');
    _phoneController = TextEditingController();

    if (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) {
      final phoneData = PhoneFormatter.extractPhoneData(widget.initialPhone!);
      if (phoneData != null) {
        _selectedCountryCode = phoneData['countryCode'] ?? '+33';
        _phoneController.text = phoneData['localNumber'] ?? '';
        _phoneNumber = widget.initialPhone;
      }
    }

    if (widget.initialCountryCode != null &&
        widget.initialCountryCode!.isNotEmpty) {
      _selectedCountryCode = widget.initialCountryCode!;
    }
  }

  void _initFocusNodes() {
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
    _confirmPasswordFocusNode = FocusNode();
    _phoneFocusNode = FocusNode();
  }

  void _attachValidationListeners() {
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        _emailFieldKey.currentState?.validate();
        final hasError = _emailFieldKey.currentState?.hasError ?? false;
        if (hasError) {
          _withSetState(() => _emailFieldHasBeenValidated = true);
        }
      }
    });

    _emailController.addListener(() {
      if (_emailFieldHasBeenValidated && _emailController.text.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _withSetState(() => _emailFieldKey.currentState?.validate());
          }
        });
      }
    });

    _passwordFocusNode.addListener(() {
      _withSetState(() => _isPasswordFocused = _passwordFocusNode.hasFocus);
      if (!_passwordFocusNode.hasFocus && _passwordController.text.isNotEmpty) {
        _passwordFieldKey.currentState?.validate();
        final hasError = _passwordFieldKey.currentState?.hasError ?? false;
        if (hasError) {
          _withSetState(() => _passwordFieldHasBeenValidated = true);
        }
      }
    });

    _passwordController.addListener(() {
      if (_passwordFieldHasBeenValidated &&
          _passwordController.text.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _withSetState(() => _passwordFieldKey.currentState?.validate());
          }
        });
      }
    });

    _confirmPasswordFocusNode.addListener(() {
      if (!_confirmPasswordFocusNode.hasFocus &&
          _confirmPasswordController.text.isNotEmpty) {
        _confirmPasswordFieldKey.currentState?.validate();
        final hasError =
            _confirmPasswordFieldKey.currentState?.hasError ?? false;
        if (hasError) {
          _withSetState(() => _confirmPasswordFieldHasBeenValidated = true);
        }
      }
    });

    _confirmPasswordController.addListener(() {
      if (_confirmPasswordFieldHasBeenValidated &&
          _confirmPasswordController.text.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _withSetState(
                () => _confirmPasswordFieldKey.currentState?.validate());
          }
        });
      }
    });

    _phoneFocusNode.addListener(() {
      if (!_phoneFocusNode.hasFocus && _phoneController.text.isNotEmpty) {
        _phoneFieldKey.currentState?.validate();
        final hasError = _phoneFieldKey.currentState?.hasError ?? false;
        if (hasError) {
          _withSetState(() => _phoneFieldHasBeenValidated = true);
        }
      }
    });
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_phoneNumber == null ||
        _phoneNumber!.isEmpty ||
        _phoneController.text.isEmpty) {
      if (mounted) {
        showErrorSnackbar(context, 'Le numéro de téléphone est requis.');
      }
      return;
    }

    final formattedPhoneNumber = PhoneFormatter.formatPhoneNumber(
      _selectedCountryCode,
      _phoneController.text,
    );

    if (!PhoneFormatter.isValidE164(formattedPhoneNumber)) {
      if (mounted) {
        showErrorSnackbar(
          context,
          'Numéro de téléphone invalide. Vérifiez le format.',
        );
      }
      return;
    }

    if (_isSubmitting) return;
    _withSetState(() => _isSubmitting = true);

    if (_isLoading) {
      _withSetState(() => _isSubmitting = false);
      return;
    }

    _withSetState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final phoneNumber = formattedPhoneNumber;

    final verifyEmail = ref.read(verifyEmailAvailableForSignupProvider);
    final emailResult = await verifyEmail.call(email: email);
    var emailBlocked = false;
    final emailError = emailResult.fold<String?>(
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
        _withSetState(() {
          _isLoading = false;
          _isSubmitting = false;
        });
      }
      return;
    }

    final verifyPhone = ref.read(verifyPhoneAvailableForSignupProvider);
    final phoneResult = await verifyPhone.call(phoneNumber: phoneNumber);
    var phoneBlocked = false;
    final phoneError = phoneResult.fold<String?>(
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
        _withSetState(() {
          _isLoading = false;
          _isSubmitting = false;
        });
      }
      return;
    }

    final sendOtpUseCase = ref.read(sendPhoneVerificationProvider);

    try {
      final otpResult = await sendOtpUseCase.call(phoneNumber: phoneNumber);

      otpResult.fold(
        (failure) {
          if (mounted) {
            // ALWAYS show an error — the previous code silently swallowed
            // failures whose mapper returned null, which left the user
            // stuck on the signup form with no feedback (the reported
            // "shows only error" / "no OTP page" symptom). When the mapper
            // has nothing specific to say, fall back to the raw failure
            // message so support can at least eyeball it.
            final mapped = AuthErrorMapper.getFrenchMessage(failure);
            final shown = mapped ??
                (failure.message.isNotEmpty
                    ? failure.message
                    : 'Impossible d\'envoyer le code de vérification. Vérifiez votre connexion ou réessayez plus tard.');
            showErrorSnackbar(context, shown);
            _withSetState(() {
              _isLoading = false;
              _isSubmitting = false;
            });
          }
        },
        (verificationId) {
          if (mounted) {
            _withSetState(() {
              _isLoading = false;
              _isSubmitting = false;
            });

            showSuccessSnackbar(context, 'Code de vérification envoyé!');
            widget.onNavigateToOtp(
              SignupOtpNavigation(
                verificationId: verificationId,
                email: email,
                password: password,
                phone: phoneNumber,
              ),
            );
          }
        },
      );
    } catch (_) {
      if (mounted) {
        _withSetState(() {
          _isLoading = false;
          _isSubmitting = false;
        });
      }
      rethrow;
    }

    if (mounted && _isSubmitting) {
      _withSetState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    switch (provider) {
      case 'apple':
        if (!Platform.isIOS) {
          showErrorSnackbar(
            context,
            'Connexion Apple disponible sur iPhone et iPad.',
          );
          return;
        }
        await _completeOAuthSignup(
          () => ref.read(login_providers.signInWithAppleProvider).call(),
        );
        return;
      case 'google':
        await _completeOAuthSignup(
          () => ref.read(login_providers.signInWithGoogleProvider).call(),
        );
        return;
      default:
        showErrorSnackbar(context, 'Connexion $provider bientôt disponible');
    }
  }

  /// Google / Apple: existing Firestore profile → same as login. New Auth user
  /// without `/users/{uid}` → phone dialog then [CreateUserDocument].
  Future<void> _completeOAuthSignup(
    Future<Result<AuthUser>> Function() signIn,
  ) async {
    ref.read(auth_core.oauthFirestoreProfilePendingProvider.notifier).state =
        true;
    _withSetState(() => _isSocialLoading = true);
    try {
      final result = await signIn();
      if (!mounted) return;

      if (result.isLeft) {
        ref.read(auth_core.oauthFirestoreProfilePendingProvider.notifier).state =
            false;
        final failure = result.leftOrNull;
        final msg = failure != null
            ? (AuthErrorMapper.getFrenchMessage(failure) ??
                'Une erreur s\'est produite. Veuillez réessayer.')
            : 'Une erreur s\'est produite. Veuillez réessayer.';
        showErrorSnackbar(context, msg);
        return;
      }

      final authUser = result.rightOrNull;
      if (authUser == null) {
        ref.read(auth_core.oauthFirestoreProfilePendingProvider.notifier).state =
            false;
        return;
      }

      final basicsResult = await ref
          .read(auth_core.getUserProfileBasicsProvider)
          .call(authUser.id);
      if (!mounted) return;
      final hasProfile = basicsResult.fold((_) => false, (b) => b != null);

      if (hasProfile) {
        ref.read(auth_core.oauthFirestoreProfilePendingProvider.notifier).state =
            false;
        await ref.read(auth_core.authControllerProvider.notifier).refreshAuthState();
        return;
      }

      final email = authUser.email?.trim();
      if (email == null || email.isEmpty) {
        ref.read(auth_core.oauthFirestoreProfilePendingProvider.notifier).state =
            false;
        if (!mounted) return;
        showErrorSnackbar(
          context,
          'Aucune adresse e-mail n\'est associée à ce compte. Utilisez l\'inscription par e-mail.',
        );
        await ref.read(auth_core.authControllerProvider.notifier).signOut();
        return;
      }

      final emailCheck = await ref
          .read(verifyEmailAvailableForSignupProvider)
          .call(email: email);
      if (!mounted) return;
      if (emailCheck.isLeft) {
        ref.read(auth_core.oauthFirestoreProfilePendingProvider.notifier).state =
            false;
        final f = emailCheck.leftOrNull;
        showErrorSnackbar(
          context,
          f != null
              ? (AuthErrorMapper.getFrenchMessage(f) ??
                  'Cette adresse e-mail ne peut pas être utilisée.')
              : 'Cette adresse e-mail ne peut pas être utilisée.',
        );
        await ref.read(auth_core.authControllerProvider.notifier).signOut();
        return;
      }

      final phoneE164 = await _promptPhoneForOAuthCompletion();
      if (!mounted) return;

      if (phoneE164 == null || phoneE164.isEmpty) {
        ref.read(auth_core.oauthFirestoreProfilePendingProvider.notifier).state =
            false;
        await ref.read(auth_core.authControllerProvider.notifier).signOut();
        return;
      }

      final phoneCheck = await ref
          .read(verifyPhoneAvailableForSignupProvider)
          .call(phoneNumber: phoneE164);
      if (!mounted) return;
      if (phoneCheck.isLeft) {
        ref.read(auth_core.oauthFirestoreProfilePendingProvider.notifier).state =
            false;
        final f = phoneCheck.leftOrNull;
        showErrorSnackbar(
          context,
          f != null
              ? (AuthErrorMapper.getFrenchMessage(f) ??
                  'Ce numéro ne peut pas être utilisé.')
              : 'Ce numéro ne peut pas être utilisé.',
        );
        await ref.read(auth_core.authControllerProvider.notifier).signOut();
        return;
      }

      final oauthIdentity = oauthIdentityForCreateUserDocument(authUser);
      final createResult = await ref.read(createUserDocumentProvider).call(
            uid: authUser.id,
            email: email,
            phone: phoneE164,
            roles: signupRolesMap(widget.role),
            firstName: oauthIdentity.firstName,
            lastName: oauthIdentity.lastName,
            displayName: oauthIdentity.displayName,
            photoUrl: oauthIdentity.photoUrl,
          );
      if (!mounted) return;

      if (createResult.isLeft) {
        ref.read(auth_core.oauthFirestoreProfilePendingProvider.notifier).state =
            false;
        final f = createResult.leftOrNull;
        showErrorSnackbar(
          context,
          f != null
              ? (AuthErrorMapper.getFrenchMessage(f) ??
                  'Impossible de finaliser l\'inscription.')
              : 'Impossible de finaliser l\'inscription.',
        );
        await ref.read(auth_core.authControllerProvider.notifier).signOut();
        return;
      }

      ref.read(auth_core.oauthFirestoreProfilePendingProvider.notifier).state =
          false;
      try {
        await ref.read(auth_core.patchUserDocumentProvider).call(authUser.id);
      } catch (_) {}
      try {
        await ref.read(auth_core.updateLastLoginAtProvider).call(
              authUser.id,
              displayName: authUser.displayName,
              photoUrl: authUser.photoUrl,
            );
      } catch (_) {}
      await ref.read(auth_core.authControllerProvider.notifier).refreshAuthState();
    } catch (_) {
      ref.read(auth_core.oauthFirestoreProfilePendingProvider.notifier).state =
          false;
      if (mounted) {
        showErrorSnackbar(
          context,
          'Une erreur s\'est produite. Veuillez réessayer.',
        );
        await ref.read(auth_core.authControllerProvider.notifier).signOut();
      }
    } finally {
      if (mounted) {
        _withSetState(() => _isSocialLoading = false);
      }
    }
  }

  /// E.164 phone to attach to a new OAuth account before [CreateUserDocument].
  Future<String?> _promptPhoneForOAuthCompletion() async {
    final initial = (_phoneNumber != null && _phoneNumber!.trim().isNotEmpty)
        ? _phoneNumber!.trim()
        : '';
    final controller = TextEditingController(text: initial);

    final submitted = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        String? fieldError;
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return AlertDialog(
              backgroundColor: SignupConstants.bgDark2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: SignupConstants.borderColor),
              ),
              title: Text(
                'Finaliser votre inscription',
                style: GoogleFonts.outfit(
                  color: SignupConstants.textLight,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pour sécuriser votre compte, indiquez votre numéro de mobile (format international).',
                      style: GoogleFonts.outfit(
                        color: SignupConstants.textGrey,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.phone,
                      autocorrect: false,
                      style: GoogleFonts.outfit(
                        color: SignupConstants.textLight,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: '+33 6 12 34 56 78',
                        hintStyle: GoogleFonts.outfit(
                          color: SignupConstants.textGrey,
                          fontSize: 14,
                        ),
                        errorText: fieldError,
                        filled: true,
                        fillColor: SignupConstants.bgDark1,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: SignupConstants.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: SignupConstants.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: SignupConstants.primaryGold,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Annuler',
                    style: GoogleFonts.outfit(color: SignupConstants.textGrey),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final raw = controller.text.trim();
                    final formatted = raw.startsWith('+')
                        ? raw.replaceAll(RegExp(r'\s'), '')
                        : PhoneFormatter.formatPhoneNumber(
                            _selectedCountryCode,
                            raw,
                          );
                    if (!PhoneFormatter.isValidE164(formatted)) {
                      setModal(() {
                        fieldError = 'Numéro invalide (ex. +33 6 12 34 56 78).';
                      });
                      return;
                    }
                    setModal(() => fieldError = null);
                    Navigator.of(dialogContext).pop(formatted);
                  },
                  child: Text(
                    'Continuer',
                    style: GoogleFonts.outfit(
                      color: SignupConstants.primaryGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return submitted;
  }

  void _onPasswordFieldFocusChanged(bool isFocused) {
    _withSetState(() => _isPasswordFocused = isFocused);
  }

  void _onPhoneNumberUpdate(String formattedPhone) {
    // Stored for submit only — no setState (avoids rebuilding the whole form
    // on every digit, which can break focus / formatters on Android).
    _phoneNumber = formattedPhone;
  }

  void _onCountryCodeChange(String code) {
    _withSetState(() => _selectedCountryCode = code);
  }

  void _revalidatePhoneAfterEdit() {
    if (_phoneController.text.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _withSetState(() {
        if (!_phoneFieldHasBeenValidated) {
          _phoneFieldHasBeenValidated = true;
        }
        _phoneFieldKey.currentState?.validate();
      });
    });
  }

  Widget _buildSignupContent(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: MerchantColors.bgMain,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !_isLoading) {
            widget.onBack();
          }
        },
        child: Scaffold(
          backgroundColor: MerchantColors.bgMain,
          body: SafeArea(
            child: ResponsiveScrollBody(
              horizontalPadding: 24,
              verticalPadding: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top bar: back arrow ← + Yuztoo brand mark →
                  SizedBox(
                    height: 44,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: widget.onBack,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: SignupConstants.primaryGold,
                              size: 20,
                            ),
                          ),
                        ),
                        // Inline brand mark — keeps identity without wasting space
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: SignupConstants.primaryGold,
                                  width: 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Y',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: SignupConstants.primaryGold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Yuztoo',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: SignupConstants.textLight,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Hero
                  SignupLogoSection(role: widget.role),
                  const SizedBox(height: 20),
                  // Form card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: MerchantColors.bgHeader,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: MerchantColors.gold.withValues(
                            alpha: MerchantColors.goldBorderAlpha),
                        width: 1,
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.disabled,
                      child: Column(
                        children: [
                          EmailField(
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            fieldKey: _emailFieldKey,
                            hasBeenValidated: _emailFieldHasBeenValidated,
                            enabled: !_isLoading,
                            onUnfocusAll: _unfocusAllFields,
                          ),
                          const SizedBox(height: 16),
                          PasswordField(
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            fieldKey: _passwordFieldKey,
                            hasBeenValidated: _passwordFieldHasBeenValidated,
                            enabled: !_isLoading,
                            onUnfocusAll: _unfocusAllFields,
                            onFocusChanged: _onPasswordFieldFocusChanged,
                          ),
                          if (_isPasswordFocused) ...[
                            const SizedBox(height: 8),
                            const PasswordHint(),
                          ],
                          const SizedBox(height: 16),
                          ConfirmPasswordField(
                            controller: _confirmPasswordController,
                            passwordController: _passwordController,
                            focusNode: _confirmPasswordFocusNode,
                            fieldKey: _confirmPasswordFieldKey,
                            hasBeenValidated:
                                _confirmPasswordFieldHasBeenValidated,
                            enabled: !_isLoading,
                            onUnfocusAll: _unfocusAllFields,
                          ),
                          const SizedBox(height: 16),
                          PhoneField(
                            controller: _phoneController,
                            focusNode: _phoneFocusNode,
                            fieldKey: _phoneFieldKey,
                            selectedCountryCode: _selectedCountryCode,
                            hasBeenValidated: _phoneFieldHasBeenValidated,
                            enabled: !_isLoading,
                            onUnfocusAll: _unfocusAllFields,
                            onPhoneNumberUpdate: _onPhoneNumberUpdate,
                            onCountryCodeChange: _onCountryCodeChange,
                            onRevalidatePhone: _revalidatePhoneAfterEdit,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SignupButton(
                    isLoading: _isLoading,
                    onPressed:
                        (_isLoading || _isSubmitting) ? null : _handleSignup,
                  ),
                  const SizedBox(height: 12),
                  // RGPD/CGU consent disclaimer. Implicit acceptance via
                  // account creation — explicit checkbox would add
                  // friction without legal benefit since the action is
                  // already a clear consent gesture under French law.
                  // The two links MUST be tappable here (not just in
                  // settings) so a prospective user can read both
                  // documents BEFORE committing.
                  const _LegalConsentDisclaimer(),
                  const SizedBox(height: 16),
                  const SocialDivider(),
                  const SizedBox(height: 16),
                  SocialLoginButtons(
                    isLoading: _isLoading || _isSocialLoading,
                    onSocialLogin: _handleSocialLogin,
                  ),
                  const SizedBox(height: 24),
                  SignupFooter(
                    onBack: widget.onBack,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Implicit-consent disclaimer shown directly under the "S'inscrire" CTA.
/// The two link spans push the bundled legal screens — they must work
/// without leaving the app and without network (App Store reviewers).
class _LegalConsentDisclaimer extends StatelessWidget {
  const _LegalConsentDisclaimer();

  @override
  Widget build(BuildContext context) {
    final baseStyle = GoogleFonts.outfit(
      fontSize: 11.5,
      height: 1.4,
      color: MerchantColors.textGrey,
    );
    final linkStyle = baseStyle.copyWith(
      color: SignupConstants.primaryGold,
      decoration: TextDecoration.underline,
      decorationColor: SignupConstants.primaryGold,
      fontWeight: FontWeight.w600,
    );
    void open(LegalDocument doc) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LegalDocumentScreen(document: doc),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text.rich(
        TextSpan(
          style: baseStyle,
          children: [
            const TextSpan(
              text: 'En créant un compte, vous acceptez nos ',
            ),
            TextSpan(
              text: 'Conditions d\'utilisation',
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () => open(LegalDocument.termsOfService),
            ),
            const TextSpan(text: ' et notre '),
            TextSpan(
              text: 'Politique de confidentialité',
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () => open(LegalDocument.privacyPolicy),
            ),
            const TextSpan(text: '.'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Payload for [SignupScreen.onNavigateToOtp] when the verification SMS is sent.
class SignupOtpNavigation {
  const SignupOtpNavigation({
    required this.verificationId,
    required this.email,
    required this.password,
    required this.phone,
  });
  final String verificationId;
  final String email;
  final String password;
  final String phone;
}
