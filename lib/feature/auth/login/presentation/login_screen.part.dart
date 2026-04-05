part of 'login_screen.dart';

class _LoginSocialDivider extends StatelessWidget {
  const _LoginSocialDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: _borderColor.withValues(alpha: 0.5),
            thickness: 1,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OU',
            style: TextStyle(
              fontSize: 11,
              color: _textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: _borderColor.withValues(alpha: 0.5),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

class _LoginGoogleIcon extends StatelessWidget {
  const _LoginGoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _GoogleIconPainter(),
      ),
    );
  }
}

class _LoginSocialButton extends StatelessWidget {
  const _LoginSocialButton({
    this.icon,
    this.label,
    this.iconColor,
    this.iconWidget,
    required this.onPressed,
    required this.isLoading,
  });

  final IconData? icon;
  final String? label;
  final Color? iconColor;
  final Widget? iconWidget;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _borderColor, width: 1.5),
          color: _bgDark2,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget ?? Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 4),
            Text(
              label ?? '',
              style: const TextStyle(
                fontSize: 10,
                color: _textLight,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginSocialLoginRow extends StatelessWidget {
  const _LoginSocialLoginRow({
    required this.isLoading,
    required this.onSocial,
  });

  final bool isLoading;
  final void Function(String provider) onSocial;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LoginSocialButton(
            label: 'Google',
            iconWidget: const _LoginGoogleIcon(),
            onPressed: () => onSocial('google'),
            isLoading: isLoading,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _LoginSocialButton(
            icon: Icons.facebook,
            label: 'Facebook',
            iconColor: const Color(0xFF1877F2),
            onPressed: () => onSocial('facebook'),
            isLoading: isLoading,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _LoginSocialButton(
            icon: Icons.apple,
            label: 'Apple',
            iconColor: _textLight,
            onPressed: () => onSocial('apple'),
            isLoading: isLoading,
          ),
        ),
      ],
    );
  }
}

class _LoginFooter extends StatelessWidget {
  const _LoginFooter({required this.onSignup});

  final VoidCallback onSignup;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onSignup,
          child: const Text.rich(
            TextSpan(
              text: 'Vous n\'avez pas de compte ? ',
              style: TextStyle(color: _textGrey, fontSize: 13),
              children: [
                TextSpan(
                  text: 'Créer un compte',
                  style: TextStyle(
                    color: _primaryGold,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    final matrix = Matrix4.diagonal3Values(scale, scale, scale);

    final redPath = Path()
      ..moveTo(22.56, 12.25)
      ..cubicTo(22.56, 11.47, 22.49, 10.72, 22.36, 10.0)
      ..lineTo(12.0, 10.0)
      ..lineTo(12.0, 14.26)
      ..lineTo(17.92, 14.26)
      ..cubicTo(17.66, 15.63, 16.88, 16.79, 15.71, 17.57)
      ..lineTo(15.71, 20.34)
      ..lineTo(19.28, 20.34)
      ..cubicTo(21.36, 18.42, 22.56, 15.6, 22.56, 12.25)
      ..close();
    redPath.transform(matrix.storage);
    canvas.drawPath(
      redPath,
      Paint()
        ..color = const Color(0xFFEA4335)
        ..style = PaintingStyle.fill,
    );

    final greenPath = Path()
      ..moveTo(12.0, 23.0)
      ..cubicTo(14.97, 23.0, 17.46, 22.02, 19.28, 20.34)
      ..lineTo(15.71, 17.57)
      ..cubicTo(14.73, 18.23, 13.48, 18.63, 12.0, 18.63)
      ..cubicTo(9.14, 18.63, 6.71, 16.7, 5.84, 14.09)
      ..lineTo(2.18, 16.93)
      ..cubicTo(3.99, 20.53, 7.7, 23.0, 12.0, 23.0)
      ..close();
    greenPath.transform(matrix.storage);
    canvas.drawPath(
      greenPath,
      Paint()
        ..color = const Color(0xFF34A853)
        ..style = PaintingStyle.fill,
    );

    final yellowPath = Path()
      ..moveTo(5.84, 14.09)
      ..cubicTo(5.62, 13.43, 5.49, 12.73, 5.49, 12.0)
      ..cubicTo(5.49, 11.27, 5.62, 10.57, 5.84, 9.91)
      ..lineTo(5.84, 7.07)
      ..lineTo(2.18, 7.07)
      ..cubicTo(1.43, 8.55, 1.0, 10.22, 1.0, 12.0)
      ..cubicTo(1.0, 13.78, 1.43, 15.45, 2.18, 16.93)
      ..lineTo(5.03, 14.71)
      ..lineTo(5.84, 14.09)
      ..close();
    yellowPath.transform(matrix.storage);
    canvas.drawPath(
      yellowPath,
      Paint()
        ..color = const Color(0xFFFBBC05)
        ..style = PaintingStyle.fill,
    );

    final bluePath = Path()
      ..moveTo(12.0, 5.38)
      ..cubicTo(13.62, 5.38, 15.06, 5.94, 16.21, 7.02)
      ..lineTo(19.36, 3.87)
      ..cubicTo(17.45, 2.09, 14.97, 1.0, 12.0, 1.0)
      ..cubicTo(7.7, 1.0, 3.99, 3.47, 2.18, 7.07)
      ..lineTo(5.84, 9.91)
      ..cubicTo(6.71, 7.3, 9.14, 5.38, 12.0, 5.38)
      ..close();
    bluePath.transform(matrix.storage);
    canvas.drawPath(
      bluePath,
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

extension _LoginScreenFlow on _LoginScreenState {
  void _showCityPicker(String uid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgDark2,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final searchController = TextEditingController();
            final filteredCities = <String>[];

            void filterCities(String query) {
              setModalState(() {
                if (query.isEmpty) {
                  filteredCities.clear();
                } else {
                  filteredCities.clear();
                  filteredCities.addAll(
                    frenchCities.where(
                      (city) =>
                          city.toLowerCase().contains(query.toLowerCase()),
                    ),
                  );
                }
              });
            }

            final citiesToShow =
                filteredCities.isEmpty ? frenchCities : filteredCities;

            return Container(
              padding: const EdgeInsets.all(24),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sélectionnez votre ville',
                    style: TextStyle(
                      color: _textLight,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchController,
                    style: const TextStyle(color: _textLight),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une ville...',
                      hintStyle: const TextStyle(color: _textGrey),
                      prefixIcon:
                          const Icon(Icons.search, color: _primaryGold),
                      filled: true,
                      fillColor: _bgDark1,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: _primaryGold, width: 2),
                      ),
                    ),
                    onChanged: filterCities,
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: citiesToShow.length,
                      itemBuilder: (context, index) {
                        final city = citiesToShow[index];
                        return ListTile(
                          title: Text(
                            city,
                            style: const TextStyle(color: _textLight),
                          ),
                          onTap: () {
                            searchController.dispose();
                            Navigator.pop(context);
                            final loginFlowController =
                                ref.read(loginFlowControllerProvider.notifier);
                            loginFlowController.updateCity(uid, city);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      final currentState = ref.read(loginFlowControllerProvider);
      if (currentState is LoginFlowCityRequired) {
        ref.read(loginFlowControllerProvider.notifier).reset();
      }
    });
  }

  void _showRoleMismatchDialog(LoginFlowRoleMismatch state) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        final roleName = state.requestedRole == UserRole.merchant
            ? 'commerçant'
            : 'client';
        return AlertDialog(
          backgroundColor: _bgDark2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _borderColor, width: 1),
          ),
          title: const Text(
            'Compte non disponible',
            style: TextStyle(
              color: _textLight,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Vous n\'avez pas de compte $roleName avec cet email. Souhaitez-vous créer un compte $roleName ?',
            style: const TextStyle(
              color: _textGrey,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(loginFlowControllerProvider.notifier).reset();
              },
              child: const Text(
                'Annuler',
                style: TextStyle(color: _textGrey),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(loginFlowControllerProvider.notifier).reset();
                widget.onSignup();
              },
              style: FilledButton.styleFrom(
                backgroundColor: _primaryGold,
              ),
              child: const Text(
                'Créer un compte',
                style: TextStyle(
                  color: _bgDark1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMultiRoleSelectionDialog(LoginFlowMultiRoleRequired state) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _bgDark2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _borderColor, width: 1),
          ),
          title: const Text(
            'Choisissez votre rôle',
            style: TextStyle(
              color: _textLight,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.roles['client'] == true)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderColor, width: 1),
                    color: _bgDark1,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    title: const Text(
                      'Client',
                      style: TextStyle(
                        color: _textLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: const Text(
                      'Découvrir les commerces',
                      style: TextStyle(
                        color: _textGrey,
                        fontSize: 13,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: _primaryGold, size: 18),
                    onTap: () {
                      Navigator.pop(context);
                      final loginFlowController =
                          ref.read(loginFlowControllerProvider.notifier);
                      loginFlowController.selectRole(
                        state.uid,
                        UserRole.client,
                        state.city,
                      );
                    },
                  ),
                ),
              if (state.roles['merchant'] == true)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderColor, width: 1),
                    color: _bgDark1,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    title: const Text(
                      'Commerçant',
                      style: TextStyle(
                        color: _textLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: const Text(
                      'Gérer votre commerce',
                      style: TextStyle(
                        color: _textGrey,
                        fontSize: 13,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: _primaryGold, size: 18),
                    onTap: () {
                      Navigator.pop(context);
                      final loginFlowController =
                          ref.read(loginFlowControllerProvider.notifier);
                      loginFlowController.selectRole(
                        state.uid,
                        UserRole.merchant,
                        state.city,
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    ).then((_) {
      final currentState = ref.read(loginFlowControllerProvider);
      if (currentState is LoginFlowMultiRoleRequired) {
        ref.read(loginFlowControllerProvider.notifier).reset();
      }
    });
  }
}

extension _LoginScreenUi on _LoginScreenState {
  Widget _buildLoginContent(BuildContext context, bool isLoading) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
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
            if (!didPop) {
              widget.onBack();
            }
          },
          child: Scaffold(
            backgroundColor: _bgDark1,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenH = constraints.maxHeight;
                  final isClient = widget.role == UserRole.client;
                  final logoSize = isClient
                      ? (screenH * 0.17).clamp(110.0, 168.0)
                      : (screenH * 0.24).clamp(170.0, 240.0);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: isClient ? 4 : 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: widget.onBack,
                            icon: const Icon(Icons.arrow_back),
                            color: _primaryGold,
                            iconSize: 24,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                        SizedBox(height: isClient ? 8 : 16),
                        AppLogo(
                          size: logoSize,
                          fallback: Text(
                            'Y',
                            style: TextStyle(
                              color: _bgDark1,
                              fontSize: logoSize * 0.4,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(height: isClient ? 14 : 22),
                        const Text(
                          'Connexion',
                          style: TextStyle(
                            color: _textLight,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: isClient ? 6 : 8),
                        Text(
                          widget.role == UserRole.client
                              ? 'Connectez-vous pour découvrir les commerces'
                              : 'Accédez à votre espace professionnel',
                          style: const TextStyle(
                            color: _textGrey,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isClient ? 20 : 28),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              LoginInputField(
                                controller: _emailController,
                                label: 'Adresse email',
                                hint: 'votre@email.com',
                                icon: Icons.mail_outline,
                                validator: _validateEmail,
                                enabled: !isLoading,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                enableSuggestions: false,
                                focusNode: _emailFocusNode,
                                validateOnChange: _emailHasBeenValidated,
                              ),
                              const SizedBox(height: 20),
                              LoginInputField(
                                controller: _passwordController,
                                label: 'Mot de passe',
                                hint: '••••••••',
                                icon: Icons.lock_outline,
                                obscure: !_isPasswordVisible,
                                inputFormatters: [
                                  FilteringTextInputFormatter.deny(
                                      RegExp(r'\s')),
                                ],
                                validator: _validatePassword,
                                enabled: !isLoading,
                                textInputAction: TextInputAction.done,
                                autocorrect: false,
                                enableSuggestions: false,
                                focusNode: _passwordFocusNode,
                                suffixIcon: _isPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                onSuffixTap: _togglePasswordVisibility,
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          showDialog(
                                            context: context,
                                            builder: (context) =>
                                                const ForgotPasswordDialog(),
                                          );
                                        },
                                  style: TextButton.styleFrom(
                                    foregroundColor: _primaryGold,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Mot de passe oublié ?',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _primaryGold,
                                    disabledBackgroundColor: _borderColor,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10)),
                                    ),
                                    shadowColor: _primaryGold
                                        .withValues(alpha: 0.3),
                                    elevation: isLoading ? 4 : 2,
                                  ),
                                  onPressed: (isLoading || _isLoginSubmitting)
                                      ? null
                                      : _handleLogin,
                                  child: isLoading
                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              _bgDark1.withValues(alpha: 0.8),
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          'Se connecter',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: _bgDark1,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isClient ? 22 : 32),
                        const _LoginSocialDivider(),
                        SizedBox(height: isClient ? 16 : 22),
                        _LoginSocialLoginRow(
                          isLoading: isLoading,
                          onSocial: _handleSocialLogin,
                        ),
                        SizedBox(height: isClient ? 20 : 28),
                        _LoginFooter(onSignup: widget.onSignup),
                        SizedBox(height: isClient ? 16 : 28),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
