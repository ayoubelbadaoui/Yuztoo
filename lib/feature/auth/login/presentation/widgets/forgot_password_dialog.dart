import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/providers.dart';
import '../../application/state/forgot_password_state.dart';
import '../../../core/application/auth_error_mapper.dart';
import '../../../../../core/shared/widgets/snackbar.dart';
import '../../../core/domain/value_objects/email_address.dart';
import 'input_field.dart';
import '../../../../../core/shared/constants/merchant_colors.dart';

// Dark theme colors — same as loading / login scaffold (#0E2A44)
const Color _bgDark1 = MerchantColors.bgMain;
const Color _bgDark2 = MerchantColors.bgHeader;
const Color _primaryGold = MerchantColors.gold;
const Color _textLight = Color(0xFFF5F5F5);
const Color _textGrey = Color(0xFFB0B0B0);
const Color _borderColor = Color(0xFF2A3F5F);

class ForgotPasswordDialog extends ConsumerStatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  ConsumerState<ForgotPasswordDialog> createState() =>
      _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends ConsumerState<ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'adresse e-mail est requise.';
    }
    if (!EmailAddress.isValid(value)) {
      return 'Adresse e-mail invalide.';
    }
    return null;
  }

  Future<void> _handleSendResetEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = ref.read(forgotPasswordControllerProvider.notifier);
    await controller.sendResetEmail(email: _emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final forgotPasswordState = ref.watch(forgotPasswordControllerProvider);
    final isLoading = forgotPasswordState is ForgotPasswordLoading;

    // Listen to state changes
    ref.listen<ForgotPasswordState>(
      forgotPasswordControllerProvider,
      (previous, next) {
        if (next is ForgotPasswordSuccess) {
          Navigator.of(context).pop();
          if (mounted) {
            showSuccessSnackbar(
              context,
              'Un email de réinitialisation a été envoyé à ${_emailController.text.trim()}',
            );
          }
        } else if (next is ForgotPasswordError) {
          final frenchMessage = AuthErrorMapper.getFrenchMessage(next.failure);
          if (mounted && frenchMessage != null) {
            showErrorSnackbar(context, frenchMessage);
          }
        }
      },
    );

    return AlertDialog(
      backgroundColor: _bgDark2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _borderColor, width: 1),
      ),
      title: Text(
        'Mot de passe oublié',
        style: GoogleFonts.outfit(
          color: _textLight,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saisissez votre adresse e-mail : nous vous enverrons un lien pour réinitialiser votre mot de passe.',
              style: GoogleFonts.outfit(
                color: _textGrey,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            LoginInputField(
              controller: _emailController,
              label: 'Adresse e-mail',
              hint: 'votre@email.com',
              icon: Icons.mail_outline_rounded,
              validator: _validateEmail,
              enabled: !isLoading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading
              ? null
              : () {
                  Navigator.of(context).pop();
                  ref.read(forgotPasswordControllerProvider.notifier).reset();
                },
          style: TextButton.styleFrom(foregroundColor: _textGrey),
          child: Text(
            'Annuler',
            style: GoogleFonts.outfit(fontSize: 14),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isLoading
                ? null
                : const LinearGradient(
                    colors: [Color(0xFFD4AF37), _primaryGold],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: isLoading ? _borderColor : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: isLoading ? null : _handleSendResetEmail,
              splashColor: Colors.white.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(_bgDark1),
                        ),
                      )
                    : Text(
                        'Envoyer',
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
  }
}

