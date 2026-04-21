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
              ? 'Impossible de vérifier l\'adresse email.'
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
            final frenchMessage = AuthErrorMapper.getFrenchMessage(failure);
            if (frenchMessage != null) {
              showErrorSnackbar(context, frenchMessage);
            }
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
    showErrorSnackbar(context, 'Connexion $provider bientôt disponible');
  }

  void _onPasswordFieldFocusChanged(bool isFocused) {
    _withSetState(() => _isPasswordFocused = isFocused);
  }

  void _onPhoneNumberUpdate(String formattedPhone) {
    _withSetState(() => _phoneNumber = formattedPhone);
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                  const SizedBox(height: 24),
                  const SocialDivider(),
                  const SizedBox(height: 16),
                  SocialLoginButtons(
                    isLoading: _isLoading,
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
