import 'dart:io';
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
import '../../signup/application/providers.dart' as signup_providers;
import '../../signup/domain/signup_roles_map.dart';
import '../../signup/presentation/constants/signup_constants.dart';
import '../../signup/presentation/utils/phone_formatter.dart';

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
  bool _isSocialLoading = false; // loading state for Google / Apple sign-in
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

    return _buildLoginContent(context, isLoading || _isSocialLoading);
  }

  Future<void> _handleSocialLogin(String provider) async {
    switch (provider) {
      case 'google':
        await _signInWithGoogle();
        return;
      case 'apple':
        await _signInWithApple();
        return;
      default:
        showErrorSnackbar(context, 'Connexion avec $provider bientôt disponible');
    }
  }

  Future<void> _signInWithGoogle() async {
    // Block the shell from auto-routing (and auto-signing-out) while we handle
    // the OAuth flow. A brand-new Google user has no Firestore doc yet, so
    // without this guard the shell races to sign them out before _handleOAuthSuccess
    // can collect their phone number and create the document.
    ref.read(auth_providers.oauthFirestoreProfilePendingProvider.notifier).state =
        true;
    setState(() => _isSocialLoading = true);
    final result = await ref.read(signInWithGoogleProvider).call();
    if (!mounted) return;
    setState(() => _isSocialLoading = false);
    result.fold(
      (failure) {
        // Auth failed or user cancelled — unblock the shell immediately.
        ref
            .read(auth_providers.oauthFirestoreProfilePendingProvider.notifier)
            .state = false;
        showErrorSnackbar(
          context,
          AuthErrorMapper.getFrenchMessage(failure) ??
              'Une erreur s\'est produite. Veuillez réessayer.',
        );
      },
      (authUser) => _handleOAuthSuccess(authUser),
    );
  }

  Future<void> _signInWithApple() async {
    // Same shell-guard pattern as _signInWithGoogle.
    ref.read(auth_providers.oauthFirestoreProfilePendingProvider.notifier).state =
        true;
    setState(() => _isSocialLoading = true);
    final result = await ref.read(signInWithAppleProvider).call();
    if (!mounted) return;
    setState(() => _isSocialLoading = false);
    result.fold(
      (failure) {
        ref
            .read(auth_providers.oauthFirestoreProfilePendingProvider.notifier)
            .state = false;
        showErrorSnackbar(
          context,
          AuthErrorMapper.getFrenchMessage(failure) ??
              'Une erreur s\'est produite. Veuillez réessayer.',
        );
      },
      (authUser) => _handleOAuthSuccess(authUser),
    );
  }

  /// Called after a successful Google or Apple sign-in.
  ///
  /// Two scenarios:
  ///   • Existing user (Firestore doc exists) → clear the pending flag so the
  ///     shell unblocks, then refresh auth state to trigger normal routing.
  ///   • New user (no Firestore doc) → collect phone → create doc → clear flag
  ///     → refresh auth state to trigger onboarding routing.
  ///
  /// Every early-return path MUST clear [oauthFirestoreProfilePendingProvider]
  /// so the shell never stays stuck in a "blocked" state.
  Future<void> _handleOAuthSuccess(dynamic authUser) async {
    if (authUser == null) {
      ref
          .read(auth_providers.oauthFirestoreProfilePendingProvider.notifier)
          .state = false;
      return;
    }

    // Check whether this is an existing or brand-new user.
    final basicsResult = await ref
        .read(auth_providers.getUserProfileBasicsProvider)
        .call(authUser.id);
    if (!mounted) return;

    final hasProfile = basicsResult.fold((_) => false, (b) => b != null);
    if (hasProfile) {
      // Existing user — unblock the shell and let it drive routing via the
      // auth stream (it was held back by the pending flag set in _signInWithGoogle).
      ref
          .read(auth_providers.oauthFirestoreProfilePendingProvider.notifier)
          .state = false;
      await ref
          .read(auth_providers.authControllerProvider.notifier)
          .refreshAuthState();
      return;
    }

    // ── New user ── collect phone → create Firestore doc → onboard ─────────
    final email = (authUser.email as String?)?.trim();
    if (email == null || email.isEmpty) {
      ref
          .read(auth_providers.oauthFirestoreProfilePendingProvider.notifier)
          .state = false;
      showErrorSnackbar(
        context,
        'Aucune adresse e-mail n\'est associée à ce compte. Utilisez l\'inscription par e-mail.',
      );
      await ref.read(auth_providers.authControllerProvider.notifier).signOut();
      return;
    }

    // Verify email is not taken by another account.
    final emailCheck = await ref
        .read(signup_providers.verifyEmailAvailableForSignupProvider)
        .call(email: email);
    if (!mounted) return;
    if (emailCheck.isLeft) {
      ref
          .read(auth_providers.oauthFirestoreProfilePendingProvider.notifier)
          .state = false;
      final f = emailCheck.leftOrNull;
      showErrorSnackbar(
        context,
        f != null
            ? (AuthErrorMapper.getFrenchMessage(f) ??
                'Cette adresse e-mail est déjà utilisée.')
            : 'Cette adresse e-mail est déjà utilisée.',
      );
      await ref.read(auth_providers.authControllerProvider.notifier).signOut();
      return;
    }

    // Collect phone (no OTP needed — OAuth account is already trusted).
    final phoneE164 = await _promptPhoneForOAuthCompletion();
    if (!mounted) return;
    if (phoneE164 == null || phoneE164.isEmpty) {
      ref
          .read(auth_providers.oauthFirestoreProfilePendingProvider.notifier)
          .state = false;
      await ref.read(auth_providers.authControllerProvider.notifier).signOut();
      return;
    }

    // Create Firestore user document with the role from this screen.
    setState(() => _isSocialLoading = true);
    final createResult =
        await ref.read(signup_providers.createUserDocumentProvider).call(
              uid: authUser.id,
              email: email,
              phone: phoneE164,
              roles: signupRolesMap(widget.role),
            );
    if (!mounted) return;
    setState(() => _isSocialLoading = false);

    if (createResult.isLeft) {
      ref
          .read(auth_providers.oauthFirestoreProfilePendingProvider.notifier)
          .state = false;
      final f = createResult.leftOrNull;
      showErrorSnackbar(
        context,
        f != null
            ? (AuthErrorMapper.getFrenchMessage(f) ??
                'Impossible de finaliser l\'inscription.')
            : 'Impossible de finaliser l\'inscription.',
      );
      return;
    }

    // Unblock the shell and trigger routing to the correct onboarding screen.
    ref
        .read(auth_providers.oauthFirestoreProfilePendingProvider.notifier)
        .state = false;
    await ref
        .read(auth_providers.authControllerProvider.notifier)
        .refreshAuthState();
  }

  /// Shows a modal dialog asking the user to enter their phone number.
  /// Returns the E.164 formatted number, or null if cancelled.
  Future<String?> _promptPhoneForOAuthCompletion() async {
    final controller = TextEditingController();
    final submitted = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        String? fieldError;
        return StatefulBuilder(
          builder: (ctx, setModal) => AlertDialog(
            backgroundColor: SignupConstants.bgDark2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: SignupConstants.borderColor),
            ),
            title: Text(
              'Finaliser votre inscription',
              style: GoogleFonts.outfit(
                color: SignupConstants.textLight,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ajoutez votre numéro de mobile pour sécuriser votre compte.',
                    style: GoogleFonts.outfit(
                      color: SignupConstants.textGrey,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.phone,
                    autofocus: true,
                    style: GoogleFonts.outfit(
                        color: SignupConstants.textLight, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: '+33 6 12 34 56 78',
                      hintStyle: GoogleFonts.outfit(
                          color: SignupConstants.textGrey, fontSize: 14),
                      errorText: fieldError,
                      filled: true,
                      fillColor: SignupConstants.bgDark1,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: SignupConstants.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: SignupConstants.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: SignupConstants.primaryGold, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'Annuler',
                  style: GoogleFonts.outfit(color: SignupConstants.textGrey),
                ),
              ),
              TextButton(
                onPressed: () {
                  final raw = controller.text.trim();
                  final formatted = raw.startsWith('+')
                      ? raw.replaceAll(RegExp(r'\s'), '')
                      : PhoneFormatter.formatPhoneNumber('+33', raw);
                  if (!PhoneFormatter.isValidE164(formatted)) {
                    setModal(() {
                      fieldError = 'Numéro invalide (ex. +33 6 12 34 56 78).';
                    });
                    return;
                  }
                  Navigator.of(dialogContext).pop(formatted);
                },
                child: Text(
                  'Continuer',
                  style: GoogleFonts.outfit(
                    color: SignupConstants.primaryGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    return submitted;
  }
}