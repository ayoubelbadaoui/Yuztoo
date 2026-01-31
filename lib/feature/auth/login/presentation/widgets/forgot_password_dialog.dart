import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers.dart';
import '../../application/state/forgot_password_state.dart';
import '../../../core/application/auth_error_mapper.dart';
import '../../../../../core/shared/widgets/snackbar.dart';
import '../../../core/domain/value_objects/email_address.dart';
import 'input_field.dart';

// Dark theme colors
const Color _bgDark1 = Color(0xFF0F1A29);
const Color _bgDark2 = Color(0xFF111A2A);
const Color _primaryGold = Color(0xFFD4A017);
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
          if (mounted) {
            showErrorSnackbar(context, frenchMessage);
          }
        }
      },
    );

    return AlertDialog(
      backgroundColor: _bgDark2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _borderColor, width: 1),
      ),
      title: const Text(
        'Mot de passe oublié',
        style: TextStyle(
          color: _textLight,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entrez votre adresse email et nous vous enverrons un lien pour réinitialiser votre mot de passe.',
              style: TextStyle(
                color: _textGrey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            LoginInputField(
              controller: _emailController,
              label: 'Adresse email',
              hint: 'votre@email.com',
              icon: Icons.mail_outline,
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
          style: TextButton.styleFrom(
            foregroundColor: _textGrey,
          ),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: isLoading ? null : _handleSendResetEmail,
          style: FilledButton.styleFrom(
            backgroundColor: _primaryGold,
            disabledBackgroundColor: _borderColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_bgDark1),
                  ),
                )
              : const Text(
                  'Envoyer',
                  style: TextStyle(
                    color: _bgDark1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}

