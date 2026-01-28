import 'package:flutter/material.dart';
import '../constants/signup_constants.dart';

/// Logo section widget
class SignupLogoSection extends StatelessWidget {
  const SignupLogoSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: SignupConstants.primaryGold, width: 3),
            boxShadow: [
              BoxShadow(
                color: SignupConstants.primaryGold.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on,
            color: SignupConstants.primaryGold,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'yuztoo',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: SignupConstants.textLight,
                ),
              ),
            ],
          ),
        ),
        const Text(
          'pour eux, pour vous',
          style: TextStyle(
            fontSize: 12,
            color: SignupConstants.textGrey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Créez votre compte',
          style: TextStyle(
            fontSize: 18,
            color: SignupConstants.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Signup button widget
class SignupButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const SignupButton({
    Key? key,
    required this.isLoading,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFBF8719),
          disabledBackgroundColor: SignupConstants.borderColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          shadowColor: const Color(0xFFBF8719).withOpacity(0.3),
          elevation: isLoading ? 4 : 2,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      SignupConstants.bgDark1.withOpacity(0.8)),
                ),
              )
            : const Text(
                'Créer un compte',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: SignupConstants.bgDark1,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}

/// Social divider widget
class SocialDivider extends StatelessWidget {
  const SocialDivider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: SignupConstants.borderColor.withOpacity(0.5),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OU',
            style: TextStyle(
              fontSize: 11,
              color: SignupConstants.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: SignupConstants.borderColor.withOpacity(0.5),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

/// Google icon painter
class GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    final matrix = Matrix4.identity()..scale(scale);

    // Red path
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
      Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.fill,
    );

    // Green path
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
      Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.fill,
    );

    // Yellow path
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
      Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.fill,
    );

    // Blue path
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
      Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Google icon widget
class GoogleIcon extends StatelessWidget {
  const GoogleIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: GoogleIconPainter(),
      ),
    );
  }
}

/// Social login buttons widget
class SocialLoginButtons extends StatelessWidget {
  final bool isLoading;
  final Function(String) onSocialLogin;

  const SocialLoginButtons({
    Key? key,
    required this.isLoading,
    required this.onSocialLogin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            label: 'Google',
            iconWidget: const GoogleIcon(),
            onPressed: isLoading ? null : () => onSocialLogin('google'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SocialButton(
            icon: Icons.facebook,
            label: 'Facebook',
            iconColor: const Color(0xFF1877F2),
            onPressed: isLoading ? null : () => onSocialLogin('facebook'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SocialButton(
            icon: Icons.apple,
            label: 'Apple',
            iconColor: SignupConstants.textLight,
            onPressed: isLoading ? null : () => onSocialLogin('apple'),
          ),
        ),
      ],
    );
  }
}

/// Social button widget
class _SocialButton extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final Color? iconColor;
  final Widget? iconWidget;
  final VoidCallback? onPressed;

  const _SocialButton({
    Key? key,
    this.icon,
    this.label,
    this.iconColor,
    this.iconWidget,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SignupConstants.borderColor, width: 1.5),
          color: SignupConstants.bgDark2,
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
                color: SignupConstants.textLight,
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

/// Footer widget
class SignupFooter extends StatelessWidget {
  final VoidCallback onBack;

  const SignupFooter({
    Key? key,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Text.rich(
            TextSpan(
              text: 'Vous avez un compte ? ',
              style: const TextStyle(color: SignupConstants.textGrey, fontSize: 13),
              children: [
                const TextSpan(
                  text: 'Connectez-vous',
                  style: TextStyle(
                    color: SignupConstants.primaryGold,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Opacity(
          opacity: 0.6,
          child: Text(
            'En continuant, vous acceptez nos conditions d\'utilisation',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: SignupConstants.textGrey,
            ),
          ),
        ),
      ],
    );
  }
}

