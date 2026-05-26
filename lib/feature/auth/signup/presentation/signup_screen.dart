import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../legal/domain/legal_document.dart';
import '../../../legal/presentation/legal_document_screen.dart';
import '../application/providers.dart';
import '../application/state/oauth_signup_state.dart';
import '../../core/application/auth_error_mapper.dart';
import '../../core/domain/auth_failure.dart';
import '../../../../core/shared/widgets/snackbar.dart';
import '../../core/application/providers.dart' as auth_core;
import '../../../../types.dart';
import '../../../../core/presentation/responsive_scroll_body.dart';
import '../../../../core/shared/constants/merchant_colors.dart';
import 'constants/signup_constants.dart';
import 'utils/phone_formatter.dart';
import 'widgets/signup_form_fields.dart';
import 'widgets/signup_ui_widgets.dart';

part 'signup_screen.part.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({
    super.key,
    required this.role,
    required this.onBack,
    required this.onNavigateToOtp,
    required this.onNavigateToOAuthCompletion,
    this.initialEmail,
    this.initialPassword,
    this.initialPhone,
    this.initialCountryCode,
  });

  final UserRole role;
  final VoidCallback onBack;
  final void Function(SignupOtpNavigation data) onNavigateToOtp;

  /// Called once when the OAuth signup controller enters
  /// [OAuthSignupNeedsCompletion] — the shell is expected to push the
  /// dedicated [OAuthCompletionScreen] for phone (and optional name)
  /// collection. The signup screen stays mounted in the back stack
  /// until [OAuthSignupController.cancelCompletion] returns the flow
  /// to idle (then the shell brings this screen back to the front).
  final VoidCallback onNavigateToOAuthCompletion;

  final String? initialEmail;
  final String? initialPassword;
  final String? initialPhone;
  final String? initialCountryCode;

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailFieldKey = GlobalKey<FormFieldState>();
  final _passwordFieldKey = GlobalKey<FormFieldState>();
  final _confirmPasswordFieldKey = GlobalKey<FormFieldState>();
  final _phoneFieldKey = GlobalKey<FormFieldState>();

  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _phoneController;

  late FocusNode _emailFocusNode;
  late FocusNode _passwordFocusNode;
  late FocusNode _confirmPasswordFocusNode;
  late FocusNode _phoneFocusNode;

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isPasswordFocused = false;
  String? _phoneNumber;
  String _selectedCountryCode = '+33';

  /// Tracks the most-recent OAuth signup state we've reacted to so we do
  /// not re-trigger callbacks (`onNavigateToOAuthCompletion`, error
  /// snackbars) on every rebuild while the controller stays in the same
  /// state.
  Type? _lastHandledOAuthStateType;

  bool _emailFieldHasBeenValidated = false;
  bool _passwordFieldHasBeenValidated = false;
  bool _confirmPasswordFieldHasBeenValidated = false;
  bool _phoneFieldHasBeenValidated = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(auth_core.roleCacheServiceProvider)
          .saveLastSelectedRole(widget.role);
    });
    _initControllers();
    _initFocusNodes();
    _attachValidationListeners();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _unfocusAllFields() {
    _emailFocusNode.unfocus();
    _passwordFocusNode.unfocus();
    _confirmPasswordFocusNode.unfocus();
    _phoneFocusNode.unfocus();
  }

  void _withSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  /// Listens to [oauthSignupControllerProvider] and triggers navigation /
  /// snackbar feedback. Called from [build] (where `ref.listen` is legal).
  void _wireOAuthListener() {
    ref.listen<OAuthSignupState>(oauthSignupControllerProvider, (prev, next) {
      if (!mounted) return;
      if (next.runtimeType == _lastHandledOAuthStateType) return;
      _lastHandledOAuthStateType = next.runtimeType;

      if (next is OAuthSignupNeedsCompletion) {
        widget.onNavigateToOAuthCompletion();
        return;
      }

      if (next is OAuthSignupError && next.authUser == null) {
        showErrorSnackbar(context, next.message);
        ref.read(oauthSignupControllerProvider.notifier).dismissError();
        return;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _wireOAuthListener();
    return _buildSignupContent(context);
  }
}
