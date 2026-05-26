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
            showErrorSnackbar(
              context,
              AuthErrorMapper.displayMessage(failure),
            );
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
    } catch (e, st) {
      if (mounted) {
        showErrorSnackbar(
          context,
          AuthErrorMapper.displayMessage(
            AuthUnexpectedFailure(cause: e, stackTrace: st),
          ),
        );
        _withSetState(() {
          _isLoading = false;
          _isSubmitting = false;
        });
      }
    }

    if (mounted && _isSubmitting) {
      _withSetState(() => _isSubmitting = false);
    }
  }

  /// Routes the social-login button taps into [OAuthSignupController].
  ///
  /// All real orchestration (credential exchange, profile resolution,
  /// existing-vs-new-user routing, phone collection, Firestore write,
  /// auth refresh) lives in the controller. This screen only:
  ///   - guards Apple → iOS,
  ///   - delegates to the controller,
  ///   - shows a full-page overlay while the controller is busy
  ///     (rendered in [_buildSignupContent]).
  Future<void> _handleSocialLogin(String provider) async {
    final notifier = ref.read(oauthSignupControllerProvider.notifier);
    if (notifier.isBusy || _isLoading) return;

    switch (provider) {
      case 'apple':
        if (!Platform.isIOS) {
          showErrorSnackbar(
            context,
            'Connexion Apple disponible sur iPhone et iPad.',
          );
          return;
        }
        await notifier.startApple();
        return;
      case 'google':
        await notifier.startGoogle();
        return;
      default:
        showErrorSnackbar(context, 'Connexion $provider bientôt disponible');
    }
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
    final oauthState = ref.watch(oauthSignupControllerProvider);
    final oauthBusy = oauthState is OAuthSignupAuthenticating ||
        oauthState is OAuthSignupResolvingProfile ||
        oauthState is OAuthSignupExistingUser;
    final googleBusy = oauthState is OAuthSignupAuthenticating &&
        oauthState.provider == OAuthSignupProvider.google;
    final appleBusy = oauthState is OAuthSignupAuthenticating &&
        oauthState.provider == OAuthSignupProvider.apple;

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
          if (!didPop && !_isLoading && !oauthBusy) {
            widget.onBack();
          }
        },
        child: Scaffold(
          backgroundColor: MerchantColors.bgMain,
          body: SafeArea(
            child: Stack(
              children: [
                ResponsiveScrollBody(
                  horizontalPadding: 24,
                  verticalPadding: 8,
                  child: _buildSignupBody(
                    context,
                    googleBusy: googleBusy,
                    appleBusy: appleBusy,
                    oauthBusy: oauthBusy,
                  ),
                ),
                if (oauthBusy)
                  _OAuthLoadingOverlay(state: oauthState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignupBody(
    BuildContext context, {
    required bool googleBusy,
    required bool appleBusy,
    required bool oauthBusy,
  }) {
    return Column(
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
                    isLoading: _isLoading || oauthBusy,
                    googleLoading: googleBusy,
                    appleLoading: appleBusy,
                    onSocialLogin: _handleSocialLogin,
                  ),
                  const SizedBox(height: 24),
                  SignupFooter(
                    onBack: widget.onBack,
                  ),
                  const SizedBox(height: 16),
                ],
              );
  }
}

/// Full-page loading overlay shown while the OAuth signup controller is
/// busy with credential exchange / profile resolution / auth refresh.
///
/// Fixes the previous "tiny social button spinner that the user could
/// not see while the keyboard was up" UX. Disabling pointer events on
/// the form behind this overlay also prevents double-taps and stray
/// focus changes during the OAuth round-trip.
class _OAuthLoadingOverlay extends StatelessWidget {
  const _OAuthLoadingOverlay({required this.state});

  final OAuthSignupState state;

  String get _copy {
    return switch (state) {
      OAuthSignupAuthenticating(:final provider) =>
        provider == OAuthSignupProvider.google
            ? 'Connexion à Google…'
            : 'Connexion à Apple…',
      OAuthSignupResolvingProfile() => 'Vérification de votre compte…',
      OAuthSignupExistingUser() => 'Connexion…',
      _ => 'Veuillez patienter…',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        child: ColoredBox(
          color: MerchantColors.bgMain.withValues(alpha: 0.85),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 38,
                  height: 38,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      SignupConstants.primaryGold,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _copy,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: SignupConstants.textLight,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
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
