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
import '../domain/signup_roles_map.dart';
import '../../login/application/providers.dart' as login_providers;
import '../../core/application/auth_error_mapper.dart';
import '../../core/domain/auth_failure.dart';
import '../../../../core/shared/widgets/snackbar.dart';
import '../../core/application/providers.dart' as auth_core;
import '../../../../types.dart';
import '../../../../core/domain/core/result.dart';
import '../../core/application/oauth_identity_helpers.dart';
import '../../../../core/presentation/responsive_scroll_body.dart';
import '../../core/domain/entities/auth_user.dart';
import '../../../../core/shared/constants/merchant_colors.dart';
import 'constants/signup_constants.dart';
import 'utils/phone_formatter.dart';
import 'widgets/country_code_modal.dart';
import 'widgets/phone_number_formatter.dart';
import 'widgets/signup_form_fields.dart';
import 'widgets/signup_ui_widgets.dart';

part 'signup_screen.part.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({
    super.key,
    required this.role,
    required this.onBack,
    required this.onNavigateToOtp,
    this.initialEmail,
    this.initialPassword,
    this.initialPhone,
    this.initialCountryCode,
  });

  final UserRole role;
  final VoidCallback onBack;
  final void Function(SignupOtpNavigation data) onNavigateToOtp;
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
  bool _isSocialLoading = false;
  bool _isSubmitting = false;
  bool _isPasswordFocused = false;
  String? _phoneNumber;
  String _selectedCountryCode = '+33';

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

  @override
  Widget build(BuildContext context) => _buildSignupContent(context);
}
