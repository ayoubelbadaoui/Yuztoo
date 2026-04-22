import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/application/auth_error_mapper.dart';
import '../../core/application/providers.dart' as auth_providers;
import '../../core/domain/value_objects/email_address.dart';
import '../../../../core/presentation/responsive_scroll_body.dart';
import '../../../../core/utils/cities.dart';
import '../../../../core/shared/widgets/snackbar.dart';
import '../../../../types.dart';
import '../application/providers.dart';
import '../application/state/login_flow_state.dart';
import 'widgets/input_field.dart';
import 'widgets/forgot_password_dialog.dart';
import '../../../../../core/shared/constants/merchant_colors.dart';

part 'login_screen.part.dart';

// Dark theme colors — same as loading / signup (#0E2A44 scaffold + header surfaces)
const Color _bgDark1 = MerchantColors.bgMain;
const Color _bgDark2 = MerchantColors.bgHeader;
const Color _primaryGold = MerchantColors.gold;
const Color _textLight = Color(0xFFF5F5F5);
const Color _textGrey = Color(0xFFB0B0B0);
const Color _borderColor = Color(0xFF2A3F5F);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    super.key,
    required this.role,
    required this.onBack,
    required this.onSignup,
  });

  final UserRole role;
  final VoidCallback onBack;
  final VoidCallback onSignup;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _isPasswordVisible = false;
  bool _isLoginSubmitting = false; // simple debounce to prevent rapid taps
  bool _shouldValidateRequired = false; // Track if we should show "required" errors
  bool _emailHasBeenValidated = false; // Track if email field has been validated (blurred)

  @override
  void initState() {
    super.initState();
    // Validate email format when user clicks on another field (blur event)
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        // Field lost focus - mark as validated and validate if it has content
        _emailHasBeenValidated = true;
        if (_emailController.text.isNotEmpty) {
          _formKey.currentState?.validate();
        }
        // Trigger rebuild to enable real-time validation
        setState(() {});
      }
    });
    
    // Enable real-time validation after first blur (for corrections)
    _emailController.addListener(() {
      if (_emailHasBeenValidated && _emailController.text.isNotEmpty) {
        // Field has been validated before - validate in real-time as user corrects
        _formKey.currentState?.validate();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    // Show "required" error only after submit attempt
    if (value == null || value.isEmpty) {
      return _shouldValidateRequired ? 'L\'adresse e-mail est requise.' : null;
    }
    // Validate format:
    // - Show error on blur (when clicking another field) if format is wrong
    // - Clear error in real-time as user corrects the format
    if (!EmailAddress.isValid(value)) {
      // Only show error if field has been validated (blurred) or on submit
      // This allows real-time correction after first validation
      if (_emailHasBeenValidated || _shouldValidateRequired) {
        return 'Adresse e-mail invalide.';
      }
      return null;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    // On login page, no validation errors shown
    // Only check on submit if empty (handled in _handleLogin)
    // Server will validate the actual password
    return null;
  }

  Future<void> _handleLogin() async {
    // Enable "required" validation on submit attempt (for email only)
    setState(() {
      _shouldValidateRequired = true;
    });
    
    // Check if email is empty
    if (_emailController.text.trim().isEmpty) {
      _formKey.currentState?.validate();
      return;
    }
    
    // Check if password is empty (no error shown, just prevent submission)
    if (_passwordController.text.isEmpty) {
      return;
    }
    
    // Validate form - this will show email format errors if any
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isLoginSubmitting) return;
    setState(() => _isLoginSubmitting = true);

    final loginFlowController = ref.read(loginFlowControllerProvider.notifier);
    try {
      await loginFlowController.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoginSubmitting = false);
      }
    }
  }

  void _togglePasswordVisibility() {
    setState(() => _isPasswordVisible = !_isPasswordVisible);
  }

  @override
  Widget build(BuildContext context) {
    final loginFlowState = ref.watch(loginFlowControllerProvider);
    final isLoading = loginFlowState is LoginFlowLoading;

    // Listen to login flow state changes (must be in build method)
    ref.listen<LoginFlowState>(
      loginFlowControllerProvider,
      (previous, next) {
        // Only handle state changes, not initial build (when previous is null)
        if (previous == null) return;

        if (next is LoginFlowSuccess) {
          // Keep role cache aligned with resolved login (multi-role / single-role).
          ref.read(auth_providers.roleCacheServiceProvider).saveLastSelectedRole(next.role);
          // Auth stream already emitted Authenticated; main.dart uses cache + _role for routing.
        } else if (next is LoginFlowError) {
          final frenchMessage = AuthErrorMapper.getFrenchMessage(next.failure);
          if (context.mounted && frenchMessage != null) {
            showErrorSnackbar(context, frenchMessage);
          }
        } else if (next is LoginFlowCityRequired) {
          // Only show if state actually changed to CityRequired
          if (previous is! LoginFlowCityRequired && context.mounted) {
            _showCityPicker(next.uid);
          }
        } else if (next is LoginFlowMultiRoleRequired) {
          // Only show if state actually changed to MultiRoleRequired
          if (previous is! LoginFlowMultiRoleRequired && context.mounted) {
            _showMultiRoleSelectionDialog(next);
          }
        } else if (next is LoginFlowRoleMismatch) {
          // User doesn't have the requested role - show error and offer signup
          if (previous is! LoginFlowRoleMismatch && context.mounted) {
            _showRoleMismatchDialog(next);
          }
        }
      },
    );

    return _buildLoginContent(context, isLoading);
  }

  Future<void> _handleSocialLogin(String provider) async {
    // TODO: Implement social login (Google, Facebook, Apple)
    showErrorSnackbar(context, 'Connexion $provider bientôt disponible');
  }
}
