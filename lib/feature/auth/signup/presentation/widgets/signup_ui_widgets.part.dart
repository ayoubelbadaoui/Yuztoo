part of 'signup_ui_widgets.dart';

// ── Logo / hero section ────────────────────────────────────────────────────

extension _SignupLogoSectionUi on SignupLogoSection {
  Widget _buildSignupLogoSection(BuildContext context) {
    final isMerchant = role == UserRole.merchant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [SignupConstants.textLight, SignupConstants.primaryGold],
            stops: [0.55, 1.0],
          ).createShader(bounds),
          child: Text(
            'Créez votre compte',
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
          isMerchant
              ? 'Rejoignez Yuztoo et développez votre commerce'
              : 'Découvrez les offres et commerces près de chez vous',
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
}

// ── Primary CTA button ─────────────────────────────────────────────────────

extension _SignupButtonUi on SignupButton {
  Widget _buildSignupButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: isLoading
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFD4AF37),
                  SignupConstants.primaryGold,
                ],
              ),
        color: isLoading ? SignupConstants.borderColor : null,
        boxShadow: isLoading
            ? null
            : [
                BoxShadow(
                  color: SignupConstants.primaryGold.withValues(alpha: 0.35),
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
          onTap: isLoading ? null : onPressed,
          splashColor: Colors.white.withValues(alpha: 0.1),
          child: Center(
            child: isLoading
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
                    'Créer mon compte',
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
}

// ── "OU" divider ───────────────────────────────────────────────────────────

extension _SocialDividerUi on SocialDivider {
  Widget _buildSocialDivider(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  SignupConstants.borderColor.withValues(alpha: 0.7),
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
              color: SignupConstants.textGrey.withValues(alpha: 0.7),
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
                  SignupConstants.borderColor.withValues(alpha: 0.7),
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

// ── Google icon ────────────────────────────────────────────────────────────

class GoogleIconPainter extends CustomPainter {
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

extension _GoogleIconUi on GoogleIcon {
  Widget _buildGoogleIcon(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: GoogleIconPainter()),
    );
  }
}

// ── Social login buttons (compact icon row) ────────────────────────────────

extension _SocialLoginButtonsUi on SocialLoginButtons {
  Widget _buildSocialLoginButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialIconButton(
          iconWidget: const GoogleIcon(),
          onPressed: isLoading ? null : () => onSocialLogin('google'),
          semanticsLabel: 'Google social sign-in',
        ),
        const SizedBox(width: 16),
        _SocialIconButton(
          icon: Icons.apple,
          iconColor: SignupConstants.textLight,
          onPressed: isLoading ? null : () => onSocialLogin('apple'),
        ),
      ],
    );
  }
}

/// Compact circular icon-only social button.
class _SocialIconButton extends StatelessWidget {
  const _SocialIconButton({
    required this.onPressed,
    this.icon,
    this.iconColor,
    this.iconWidget,
    this.semanticsLabel,
  });

  final IconData? icon;
  final Color? iconColor;
  final Widget? iconWidget;
  final VoidCallback? onPressed;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final inkWell = InkWell(
      customBorder: const CircleBorder(),
      onTap: onPressed,
      splashColor: SignupConstants.primaryGold.withValues(alpha: 0.08),
      highlightColor: SignupConstants.primaryGold.withValues(alpha: 0.04),
      child: Center(
        child: iconWidget ?? Icon(icon, color: iconColor, size: 24),
      ),
    );

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: SignupConstants.bgDark2,
        shape: BoxShape.circle,
        border: Border.all(
          color: SignupConstants.borderColor,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: semanticsLabel != null
            ? Semantics(
                label: semanticsLabel,
                button: true,
                child: inkWell,
              )
            : inkWell,
      ),
    );
  }
}

// ── Footer ─────────────────────────────────────────────────────────────────

extension _SignupFooterUi on SignupFooter {
  Widget _buildSignupFooter(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Text.rich(
            TextSpan(
              text: 'Vous avez déjà un compte ? ',
              style: GoogleFonts.outfit(
                color: SignupConstants.textGrey,
                fontSize: 13,
              ),
              children: [
                TextSpan(
                  text: 'Se connecter',
                  style: GoogleFonts.outfit(
                    color: SignupConstants.primaryGold,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: SignupConstants.primaryGold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'En continuant, vous acceptez nos conditions d\'utilisation\net notre politique de confidentialité.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 10,
            color: SignupConstants.textGrey.withValues(alpha: 0.5),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
