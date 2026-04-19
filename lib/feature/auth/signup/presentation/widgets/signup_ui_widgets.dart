import 'package:flutter/material.dart';
import '../constants/signup_constants.dart';
import '../../../../../core/shared/widgets/app_logo.dart';
import '../../../../../types.dart';

part 'signup_ui_widgets.part.dart';

/// Logo section widget
class SignupLogoSection extends StatelessWidget {
  final UserRole role;

  const SignupLogoSection({super.key, required this.role});

  @override
  Widget build(BuildContext context) => _buildSignupLogoSection(context);
}

/// Signup primary CTA — single full-width button.
class SignupButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const SignupButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => _buildSignupButton(context);
}

/// Social divider widget
class SocialDivider extends StatelessWidget {
  const SocialDivider({super.key});

  @override
  Widget build(BuildContext context) => _buildSocialDivider(context);
}

/// Google icon widget
class GoogleIcon extends StatelessWidget {
  const GoogleIcon({super.key});

  @override
  Widget build(BuildContext context) => _buildGoogleIcon(context);
}

/// Social login buttons widget
class SocialLoginButtons extends StatelessWidget {
  final bool isLoading;
  final Function(String) onSocialLogin;

  const SocialLoginButtons({
    super.key,
    required this.isLoading,
    required this.onSocialLogin,
  });

  @override
  Widget build(BuildContext context) => _buildSocialLoginButtons(context);
}

/// Footer widget
class SignupFooter extends StatelessWidget {
  final VoidCallback onBack;

  const SignupFooter({
    super.key,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) => _buildSignupFooter(context);
}
