part of 'login_screen.dart';

class _LoginSocialDivider extends StatelessWidget {
  const _LoginSocialDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _borderColor.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'ou continuer avec',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: _textGrey.withValues(alpha: 0.7),
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _borderColor.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
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
    this.iconColor,
    this.iconWidget,
    required this.onPressed,
    required this.isLoading,
  });

  final IconData? icon;
  final Color? iconColor;
  final Widget? iconWidget;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: _bgDark2,
        shape: BoxShape.circle,
        border: Border.all(color: _borderColor, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: isLoading ? null : onPressed,
          splashColor: _primaryGold.withValues(alpha: 0.08),
          highlightColor: _primaryGold.withValues(alpha: 0.04),
          child: Center(
            child: iconWidget ?? Icon(icon, color: iconColor, size: 24),
          ),
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LoginSocialButton(
          iconWidget: const _LoginGoogleIcon(),
          onPressed: () => onSocial('google'),
          isLoading: isLoading,
        ),
        const SizedBox(width: 16),
        _LoginSocialButton(
          icon: Icons.facebook_rounded,
          iconColor: const Color(0xFF1877F2),
          onPressed: () => onSocial('facebook'),
          isLoading: isLoading,
        ),
        const SizedBox(width: 16),
        _LoginSocialButton(
          icon: Icons.apple,
          iconColor: _textLight,
          onPressed: () => onSocial('apple'),
          isLoading: isLoading,
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
    return GestureDetector(
      onTap: onSignup,
      child: Text.rich(
        TextSpan(
          text: 'Vous n\'avez pas de compte ? ',
          style: GoogleFonts.outfit(
            color: _textGrey,
            fontSize: 13,
          ),
          children: [
            TextSpan(
              text: 'Créer un compte',
              style: GoogleFonts.outfit(
                color: _primaryGold,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                decoration: TextDecoration.underline,
                decorationColor: _primaryGold,
              ),
            ),
          ],
        ),
      ),
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
    // Controller lives outside StatefulBuilder to avoid recreation on setState
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: _bgDark2,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredCities = <String>[];

            void filterCities(String query) {
              setModalState(() {
                filteredCities.clear();
                if (query.isNotEmpty) {
                  filteredCities.addAll(
                    frenchCities.where(
                      (c) => c.toLowerCase().contains(query.toLowerCase()),
                    ),
                  );
                }
              });
            }

            final citiesToShow =
                filteredCities.isEmpty ? frenchCities : filteredCities;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _borderColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Votre ville',
                      style: GoogleFonts.outfit(
                        color: _textLight,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sélectionnez votre ville de résidence',
                      style: GoogleFonts.outfit(
                        color: _textGrey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: _bgDark1,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderColor),
                      ),
                      child: TextField(
                        controller: searchController,
                        style: GoogleFonts.outfit(
                          color: _textLight,
                          fontSize: 14,
                        ),
                        cursorColor: _primaryGold,
                        decoration: InputDecoration(
                          hintText: 'Rechercher une ville...',
                          hintStyle: GoogleFonts.outfit(
                            color: _textGrey,
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: _primaryGold,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onChanged: filterCities,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: citiesToShow.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: _borderColor.withValues(alpha: 0.4),
                        ),
                        itemBuilder: (context, index) {
                          final city = citiesToShow[index];
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            title: Text(
                              city,
                              style: GoogleFonts.outfit(
                                color: _textLight,
                                fontSize: 14,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: _primaryGold,
                              size: 14,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              ref
                                  .read(loginFlowControllerProvider.notifier)
                                  .updateCity(uid, city);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      searchController.dispose();
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
        final roleName =
            state.requestedRole == UserRole.merchant ? 'commerçant' : 'client';
        return AlertDialog(
          backgroundColor: _bgDark2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _borderColor, width: 1),
          ),
          title: Text(
            'Compte non disponible',
            style: GoogleFonts.outfit(
              color: _textLight,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          content: Text(
            'Vous n\'avez pas de compte $roleName avec cet email. Souhaitez-vous en créer un ?',
            style: GoogleFonts.outfit(
              color: _textGrey,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(loginFlowControllerProvider.notifier).reset();
              },
              style: TextButton.styleFrom(foregroundColor: _textGrey),
              child: Text(
                'Annuler',
                style: GoogleFonts.outfit(fontSize: 14),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [Color(0xFFD4AF37), _primaryGold],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(loginFlowControllerProvider.notifier).reset();
                    widget.onSignup();
                  },
                  splashColor: Colors.white.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Text(
                      'Créer un compte',
                      style: GoogleFonts.outfit(
                        color: _bgDark1,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
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
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _borderColor, width: 1),
          ),
          title: Text(
            'Choisissez votre rôle',
            style: GoogleFonts.outfit(
              color: _textLight,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.roles['client'] == true)
                _RoleDialogTile(
                  title: 'Client',
                  subtitle: 'Découvrir les commerces',
                  icon: Icons.shopping_bag_outlined,
                  bottomMargin: 12,
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(loginFlowControllerProvider.notifier)
                        .selectRole(state.uid, UserRole.client, state.city);
                  },
                ),
              if (state.roles['merchant'] == true)
                _RoleDialogTile(
                  title: 'Commerçant',
                  subtitle: 'Gérer votre commerce',
                  icon: Icons.store_outlined,
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(loginFlowControllerProvider.notifier)
                        .selectRole(state.uid, UserRole.merchant, state.city);
                  },
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

class _RoleDialogTile extends StatelessWidget {
  const _RoleDialogTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.bottomMargin = 0,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final double bottomMargin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: bottomMargin),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 1),
        color: _bgDark1,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          splashColor: _primaryGold.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _primaryGold.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: _primaryGold, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: _textLight,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          color: _textGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: _primaryGold,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension _LoginScreenUi on _LoginScreenState {
  Widget _buildLoginContent(BuildContext context, bool isLoading) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
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
            if (!didPop) widget.onBack();
          },
          child: Scaffold(
            backgroundColor: _bgDark1,
            body: SafeArea(
              child: ResponsiveScrollBody(
                horizontalPadding: 24,
                verticalPadding: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top bar: back + brand mark ──────────────────────
                    SizedBox(
                      height: 44,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: widget.onBack,
                            behavior: HitTestBehavior.opaque,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: _primaryGold,
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
                                    color: _primaryGold,
                                    width: 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Y',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _primaryGold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Yuztoo',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _textLight,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Hero: title + subtitle ───────────────────────────
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [_textLight, _primaryGold],
                        stops: [0.55, 1.0],
                      ).createShader(bounds),
                      child: Text(
                        'Connexion',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.role == UserRole.client
                          ? 'Découvrez les commerces près de chez vous'
                          : 'Accédez à votre espace professionnel',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: _textGrey,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Form ─────────────────────────────────────────────
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          LoginInputField(
                            controller: _emailController,
                            label: 'Adresse email',
                            hint: 'votre@email.com',
                            icon: Icons.mail_outline_rounded,
                            validator: _validateEmail,
                            enabled: !isLoading,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            enableSuggestions: false,
                            focusNode: _emailFocusNode,
                            validateOnChange: _emailHasBeenValidated,
                          ),
                          const SizedBox(height: 16),
                          LoginInputField(
                            controller: _passwordController,
                            label: 'Mot de passe',
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            obscure: !_isPasswordVisible,
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'\s')),
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
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => showDialog(
                                        context: context,
                                        builder: (_) =>
                                            const ForgotPasswordDialog(),
                                      ),
                              style: TextButton.styleFrom(
                                foregroundColor: _primaryGold,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Mot de passe oublié ?',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: _primaryGold,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── CTA — gradient gold, matches signup ───────
                          GestureDetector(
                            onTap: (isLoading || _isLoginSubmitting)
                                ? null
                                : _handleLogin,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: (isLoading || _isLoginSubmitting)
                                    ? null
                                    : const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFFD4AF37),
                                          _primaryGold,
                                        ],
                                      ),
                                color: (isLoading || _isLoginSubmitting)
                                    ? _borderColor
                                    : null,
                                boxShadow: (isLoading || _isLoginSubmitting)
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: _primaryGold
                                              .withValues(alpha: 0.35),
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
                                  onTap: (isLoading || _isLoginSubmitting)
                                      ? null
                                      : _handleLogin,
                                  splashColor:
                                      Colors.white.withValues(alpha: 0.1),
                                  child: Center(
                                    child: isLoading
                                        ? SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<
                                                      Color>(
                                                _bgDark1.withValues(alpha: 0.8),
                                              ),
                                            ),
                                          )
                                        : Text(
                                            'Se connecter',
                                            style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: _bgDark1,
                                              letterSpacing: 0.1,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Social ───────────────────────────────────────────
                    const _LoginSocialDivider(),
                    const SizedBox(height: 20),
                    _LoginSocialLoginRow(
                      isLoading: isLoading,
                      onSocial: _handleSocialLogin,
                    ),
                    const SizedBox(height: 28),

                    // ── Footer ───────────────────────────────────────────
                    Center(child: _LoginFooter(onSignup: widget.onSignup)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
