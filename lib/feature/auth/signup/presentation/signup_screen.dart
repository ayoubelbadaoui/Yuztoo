import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/providers.dart';
import '../../core/application/auth_error_mapper.dart';
import '../../../../core/shared/widgets/snackbar.dart';
import '../../core/application/providers.dart' as auth_core;
import '../../../../types.dart';
import '../../../../core/shared/constants/merchant_colors.dart';
import '../../../../core/utils/city_input.dart';
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
    this.initialEmail,
    this.initialPassword,
    this.initialPhone,
    this.initialCity,
    this.initialCountryCode,
  });

  final UserRole role;
  final VoidCallback onBack;
  /// Prefer routing OTP via the app shell (e.g. [ScreenId.otp]) so signup is not
  /// stacked under a nested [Navigator] that gets disposed when auth navigates away.
  final void Function(SignupOtpNavigation data) onNavigateToOtp;
  final String? initialEmail;
  final String? initialPassword;
  final String? initialPhone;
  final String? initialCity;
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
  final _cityFieldKey = GlobalKey<FormFieldState>();

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
  String? _selectedCity;
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
