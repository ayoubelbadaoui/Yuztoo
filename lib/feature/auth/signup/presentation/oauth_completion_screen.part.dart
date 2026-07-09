part of 'oauth_completion_screen.dart';

extension _OAuthCompletionScreenUi on _OAuthCompletionScreenState {
  // ── Pre-fill the form once we know which AuthUser the controller is
  //    holding. We read it on every build so a re-mount of this screen
  //    (e.g. after dismiss → re-tap) picks up the current state, but the
  //    controllers are only seeded on the first eligible state.
  void _prefillIfNeeded(OAuthSignupState state) {
    if (_didPrefill) return;
    final authUser = switch (state) {
      OAuthSignupNeedsCompletion(:final authUser) => authUser,
      OAuthSignupSubmitting(:final authUser) => authUser,
      OAuthSignupError(:final authUser?) => authUser,
      _ => null,
    };
    if (authUser == null) return;

    final identity = oauthIdentityForCreateUserDocument(authUser);
    if (_firstNameController.text.isEmpty &&
        (identity.firstName?.isNotEmpty ?? false)) {
      _firstNameController.text = identity.firstName!;
    }
    if (_lastNameController.text.isEmpty &&
        (identity.lastName?.isNotEmpty ?? false)) {
      _lastNameController.text = identity.lastName!;
    }
    _didPrefill = true;
  }

  bool _isSubmitting(OAuthSignupState state) =>
      state is OAuthSignupSubmitting;

  bool _isCompleted(OAuthSignupState state) =>
      state is OAuthSignupCompleted;

  bool _hasErrorBanner(OAuthSignupState state) =>
      state is OAuthSignupError && state.authUser != null;

  String? _errorMessage(OAuthSignupState state) =>
      state is OAuthSignupError ? state.message : null;

  bool _needsName(OAuthSignupState state) {
    return switch (state) {
      OAuthSignupNeedsCompletion(:final needsName) => needsName,
      OAuthSignupSubmitting(:final needsName) => needsName,
      OAuthSignupError(:final needsName) => needsName,
      _ => false,
    };
  }

  String? _displayEmail(OAuthSignupState state) {
    final user = switch (state) {
      OAuthSignupNeedsCompletion(:final authUser) => authUser,
      OAuthSignupSubmitting(:final authUser) => authUser,
      OAuthSignupError(:final authUser?) => authUser,
      _ => null,
    };
    final email = user?.email?.trim() ?? '';
    return email.isEmpty ? null : email;
  }

  // ── Build ────────────────────────────────────────────────────────────────

  Widget _buildScaffold(BuildContext context) {
    final state = ref.watch(oauthSignupControllerProvider);

    // Listen for terminal transitions so we can call back into the shell
    // without rebuilding the whole tree on every rebuild.
    ref.listen<OAuthSignupState>(oauthSignupControllerProvider, (prev, next) {
      if (next is OAuthSignupCompleted) {
        widget.onCompleted();
      } else if (next is OAuthSignupIdle) {
        // The controller flipped back to idle — only happens after an
        // explicit cancel. Hand control back to the shell.
        widget.onCancelled();
      }
    });

    _prefillIfNeeded(state);

    final isSubmitting = _isSubmitting(state);
    final completed = _isCompleted(state);
    final canPop = !isSubmitting && !completed;

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
          if (didPop || !canPop) return;
          _confirmCancel();
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
                  _topBar(canPop: canPop),
                  const SizedBox(height: 20),
                  _hero(state),
                  const SizedBox(height: 20),
                  if (_hasErrorBanner(state))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _errorBanner(_errorMessage(state) ?? ''),
                    ),
                  _formCard(state),
                  const SizedBox(height: 20),
                  _continueButton(state),
                  const SizedBox(height: 16),
                  _cancelButton(canPop: canPop),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Sections ─────────────────────────────────────────────────────────────

  Widget _topBar({required bool canPop}) {
    return SizedBox(
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: canPop ? _confirmCancel : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: canPop
                    ? SignupConstants.primaryGold
                    : SignupConstants.borderColor,
                size: 20,
              ),
            ),
          ),
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
    );
  }

  Widget _hero(OAuthSignupState state) {
    final email = _displayEmail(state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [SignupConstants.textLight, SignupConstants.primaryGold],
            stops: [0.55, 1.0],
          ).createShader(bounds),
          child: Text(
            'Finalisez votre compte',
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          email == null
              ? 'Ajoutez un numéro de téléphone si vous le souhaitez.'
              : 'Connecté en tant que $email — ajoutez un numéro si vous le souhaitez.',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: SignupConstants.textGrey,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: SignupConstants.errorRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SignupConstants.errorRed.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1, right: 10),
            child: Icon(
              Icons.error_outline_rounded,
              color: SignupConstants.errorRed,
              size: 18,
            ),
          ),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: SignupConstants.textLight,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formCard(OAuthSignupState state) {
    final showName = _needsName(state);
    final disabled = _isSubmitting(state) || _isCompleted(state);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MerchantColors.bgHeader,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: MerchantColors.gold
              .withValues(alpha: MerchantColors.goldBorderAlpha),
          width: 1,
        ),
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.disabled,
        child: Column(
          children: [
            if (showName) ...[
              _nameField(
                label: 'PRÉNOM',
                hint: 'Votre prénom',
                controller: _firstNameController,
                focusNode: _firstNameFocus,
                error: _firstNameError,
                enabled: !disabled,
                textInputAction: TextInputAction.next,
                onSubmit: () => _lastNameFocus.requestFocus(),
              ),
              const SizedBox(height: 16),
              _nameField(
                label: 'NOM',
                hint: 'Votre nom',
                controller: _lastNameController,
                focusNode: _lastNameFocus,
                error: _lastNameError,
                enabled: !disabled,
                textInputAction: TextInputAction.next,
                onSubmit: () => _phoneFocus.requestFocus(),
              ),
              const SizedBox(height: 16),
            ],
            _phoneFieldRow(disabled: disabled),
            if (_phoneError != null && _phoneError!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  _phoneError!,
                  style: const TextStyle(
                    color: SignupConstants.errorRed,
                    fontSize: 11,
                    height: 1.0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _nameField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String? error,
    required bool enabled,
    required TextInputAction textInputAction,
    required VoidCallback onSubmit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFB8C4D4),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          textCapitalization: TextCapitalization.words,
          textInputAction: textInputAction,
          onFieldSubmitted: (_) => onSubmit(),
          cursorColor: SignupConstants.primaryGold,
          style: const TextStyle(
            color: SignupConstants.textLight,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: SignupConstants.textGrey,
              fontSize: 13,
            ),
            errorText: error,
            errorStyle: const TextStyle(
              color: SignupConstants.errorRed,
              fontSize: 11,
            ),
            filled: true,
            fillColor: MerchantColors.inputFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: SignupConstants.borderColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: SignupConstants.borderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: SignupConstants.primaryGold,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: SignupConstants.errorRed,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: SignupConstants.errorRed,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _phoneFieldRow({required bool disabled}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NUMÉRO DE TÉLÉPHONE (FACULTATIF)',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFB8C4D4),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: SignupConstants.bgDark2,
            border: Border.all(
              color: _phoneError != null
                  ? SignupConstants.errorRed
                  : SignupConstants.borderColor,
              width: _phoneError != null ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    bottomLeft: Radius.circular(11),
                  ),
                  onTap: disabled
                      ? null
                      : () => CountryCodeModal.show(
                            context,
                            selectedCountryCode: _selectedCountryCode,
                            onCountrySelected: (code, name, flag) {
                              uiSetState(() {
                                _selectedCountryCode = code;
                                _phoneError = null;
                              });
                            },
                            phoneController: _phoneController,
                            onPhoneNumberUpdate: (_) {},
                            onRevalidatePhone: () {},
                            phoneFieldHasBeenValidated: false,
                          ),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: SignupConstants.borderColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedCountryCode,
                          style: GoogleFonts.outfit(
                            color: SignupConstants.textLight,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.expand_more_rounded,
                          color: SignupConstants.primaryGold,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  enabled: !disabled,
                  keyboardType: TextInputType.phone,
                  autocorrect: false,
                  inputFormatters: [
                    PhoneNumberFormatter(countryCode: _selectedCountryCode),
                  ],
                  cursorColor: SignupConstants.primaryGold,
                  style: const TextStyle(
                    color: SignupConstants.textLight,
                    fontSize: 14,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _onSubmitTapped(),
                  onChanged: (_) {
                    if (_phoneError != null) {
                      uiSetState(() => _phoneError = null);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: SignupConstants
                            .countryPhoneHints[_selectedCountryCode] ??
                        '---',
                    hintStyle: const TextStyle(
                      color: SignupConstants.textGrey,
                      fontSize: 13,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _continueButton(OAuthSignupState state) {
    final loading = _isSubmitting(state) || _isCompleted(state);
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: loading
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFD4AF37),
                  SignupConstants.primaryGold,
                ],
              ),
        color: loading ? SignupConstants.borderColor : null,
        boxShadow: loading
            ? null
            : [
                BoxShadow(
                  color:
                      SignupConstants.primaryGold.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: -2,
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: loading ? null : _onSubmitTapped,
          splashColor: Colors.white.withValues(alpha: 0.1),
          child: Center(
            child: loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        SignupConstants.bgDark1.withValues(alpha: 0.8),
                      ),
                    ),
                  )
                : Text(
                    'Terminer',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: SignupConstants.bgDark1,
                      letterSpacing: 0.1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _cancelButton({required bool canPop}) {
    return TextButton(
      onPressed: canPop ? _confirmCancel : null,
      style: TextButton.styleFrom(
        foregroundColor: SignupConstants.textGrey,
        textStyle: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      child: const Text('Annuler et utiliser une autre méthode'),
    );
  }

  // ── Submit / cancel ─────────────────────────────────────────────────────

  void _onSubmitTapped() {
    if (!mounted) return;
    final state = ref.read(oauthSignupControllerProvider);
    if (_isSubmitting(state) || _isCompleted(state)) return;

    final showName = _needsName(state);

    final firstName =
        showName ? _firstNameController.text.trim() : null;
    final lastName =
        showName ? _lastNameController.text.trim() : null;

    var hasError = false;

    if (showName) {
      if (firstName == null || firstName.isEmpty) {
        _firstNameError = 'Indiquez votre prénom.';
        hasError = true;
      } else {
        _firstNameError = null;
      }
      if (lastName == null || lastName.isEmpty) {
        _lastNameError = 'Indiquez votre nom.';
        hasError = true;
      } else {
        _lastNameError = null;
      }
    }

    final rawPhone = _phoneController.text.trim();
    final formatted = rawPhone.isEmpty
        ? ''
        : rawPhone.startsWith('+')
            ? rawPhone.replaceAll(RegExp(r'\s'), '')
            : PhoneFormatter.formatPhoneNumber(_selectedCountryCode, rawPhone);

    if (rawPhone.isEmpty) {
      _phoneError = null;
    } else if (!PhoneFormatter.isValidE164(formatted)) {
      _phoneError = 'Numéro invalide (ex. +33 6 12 34 56 78).';
      hasError = true;
    } else {
      _phoneError = null;
    }

    if (hasError) {
      uiSetState(() {});
      return;
    }

    uiSetState(() {
      _firstNameError = null;
      _lastNameError = null;
      _phoneError = null;
    });

    FocusScope.of(context).unfocus();

    unawaitedSubmit(formatted, firstName, lastName);
  }

  void unawaitedSubmit(String phoneE164, String? firstName, String? lastName) {
    final intendedRole = ref.read(oauthSignupIntendedRoleProvider);
    final role = resolveOAuthCompletionRole(
      shellRole: widget.role,
      intendedRole: intendedRole,
    );
    ref.read(oauthSignupControllerProvider.notifier).submitCompletion(
          role: role,
          phoneE164: phoneE164,
          firstName: firstName,
          lastName: lastName,
        );
  }

  Future<void> _confirmCancel() async {
    if (!mounted) return;
    final state = ref.read(oauthSignupControllerProvider);
    if (_isSubmitting(state) || _isCompleted(state)) return;

    final shouldCancel = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: SignupConstants.bgDark2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: SignupConstants.borderColor),
          ),
          title: Text(
            'Annuler la création du compte ?',
            style: GoogleFonts.outfit(
              color: SignupConstants.textLight,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Vous serez déconnecté(e). Vous pourrez réessayer ou utiliser une autre méthode d’inscription.',
            style: GoogleFonts.outfit(
              color: SignupConstants.textGrey,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Continuer l’inscription',
                style: GoogleFonts.outfit(
                  color: SignupConstants.primaryGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Annuler',
                style: GoogleFonts.outfit(color: SignupConstants.textGrey),
              ),
            ),
          ],
        );
      },
    );

    if (shouldCancel == true && mounted) {
      await ref
          .read(oauthSignupControllerProvider.notifier)
          .cancelCompletion();
    }
  }
}
