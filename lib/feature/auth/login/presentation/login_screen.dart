import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/application/auth_error_mapper.dart';
import '../../core/domain/value_objects/email_address.dart';
import '../../../../core/utils/cities.dart';
import '../../../../core/shared/widgets/snackbar.dart';
import '../../../../types.dart';
import '../application/providers.dart';
import '../application/state/login_flow_state.dart';
import 'widgets/input_field.dart';
import 'widgets/forgot_password_dialog.dart';

// Dark theme colors matching signup screen
const Color _bgDark1 = Color(0xFF0F1A29);
const Color _bgDark2 = Color(0xFF111A2A);
const Color _primaryGold = Color(0xFFD4A017);
const Color _textLight = Color(0xFFF5F5F5);
const Color _textGrey = Color(0xFFB0B0B0);
const Color _borderColor = Color(0xFF2A3F5F);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    super.key,
    required this.role,
    required this.onBack,
    required this.onLoginSuccess,
    required this.onSignup,
  });

  final UserRole role;
  final VoidCallback onBack;
  final Function({
    required String uid,
    required UserRole role,
    required String city,
    required bool onboardingCompleted,
  }) onLoginSuccess;
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

    final loginFlowController = ref.read(loginFlowControllerProvider.notifier);
    await loginFlowController.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  void _showCityPicker(String uid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgDark2,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final searchController = TextEditingController();
            final filteredCities = <String>[];

            void filterCities(String query) {
              setModalState(() {
                if (query.isEmpty) {
                  filteredCities.clear();
                } else {
                  filteredCities.clear();
                  filteredCities.addAll(
                    frenchCities.where(
                      (city) => city.toLowerCase().contains(query.toLowerCase()),
                    ),
                  );
                }
              });
            }

            final citiesToShow =
                filteredCities.isEmpty ? frenchCities : filteredCities;

            return Container(
              padding: const EdgeInsets.all(24),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
      child: Column(
                mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                  Text(
                    'Sélectionnez votre ville',
                    style: TextStyle(
                      color: _textLight,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchController,
                    style: const TextStyle(color: _textLight),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une ville...',
                      hintStyle: TextStyle(color: _textGrey),
                      prefixIcon: Icon(Icons.search, color: _primaryGold),
                      filled: true,
                      fillColor: _bgDark1,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _primaryGold, width: 2),
                      ),
                    ),
                    onChanged: filterCities,
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: citiesToShow.length,
                      itemBuilder: (context, index) {
                        final city = citiesToShow[index];
                        return ListTile(
                          title: Text(
                            city,
                            style: const TextStyle(color: _textLight),
                          ),
                          onTap: () {
                            searchController.dispose();
                            Navigator.pop(context);
                            final loginFlowController =
                                ref.read(loginFlowControllerProvider.notifier);
                            loginFlowController.updateCity(uid, city);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      // If user dismissed the modal without selecting, reset to initial state
      // This allows them to try logging in again
      final currentState = ref.read(loginFlowControllerProvider);
      if (currentState is LoginFlowCityRequired) {
        ref.read(loginFlowControllerProvider.notifier).reset();
      }
    });
  }

  void _showMultiRoleSelectionDialog(LoginFlowMultiRoleRequired state) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _bgDark2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _borderColor, width: 1),
          ),
          title: Text(
            'Choisissez votre rôle',
            style: TextStyle(
              color: _textLight,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
              children: [
              if (state.roles['client'] == true)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderColor, width: 1),
                    color: _bgDark1,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    title: Text(
                      'Client',
                      style: TextStyle(
                        color: _textLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Découvrir les commerces',
                      style: TextStyle(
                        color: _textGrey,
                        fontSize: 13,
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios,
                        color: _primaryGold, size: 18),
                    onTap: () {
                      Navigator.pop(context);
                      final loginFlowController =
                          ref.read(loginFlowControllerProvider.notifier);
                      loginFlowController.selectRole(
                        state.uid,
                        UserRole.client,
                        state.city,
                      );
                    },
                  ),
                ),
              if (state.roles['merchant'] == true)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderColor, width: 1),
                    color: _bgDark1,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    title: Text(
                      'Commerçant',
                      style: TextStyle(
                        color: _textLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Gérer votre commerce',
                      style: TextStyle(
                        color: _textGrey,
                        fontSize: 13,
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios,
                        color: _primaryGold, size: 18),
                    onTap: () {
                      Navigator.pop(context);
                      final loginFlowController =
                          ref.read(loginFlowControllerProvider.notifier);
                      loginFlowController.selectRole(
                        state.uid,
                        UserRole.merchant,
                        state.city,
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    ).then((_) {
      // If user dismissed the dialog without selecting, reset to initial state
      // This allows them to try logging in again
      final currentState = ref.read(loginFlowControllerProvider);
      if (currentState is LoginFlowMultiRoleRequired) {
        ref.read(loginFlowControllerProvider.notifier).reset();
      }
    });
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
          widget.onLoginSuccess(
            uid: next.uid,
            role: next.role,
            city: next.city,
            onboardingCompleted: next.onboardingCompleted,
          );
        } else if (next is LoginFlowError) {
          final frenchMessage = AuthErrorMapper.getFrenchMessage(next.failure);
          if (mounted) {
            showErrorSnackbar(context, frenchMessage);
          }
        } else if (next is LoginFlowCityRequired) {
          // Only show if state actually changed to CityRequired
          if (previous is! LoginFlowCityRequired && mounted) {
            _showCityPicker(next.uid);
          }
        } else if (next is LoginFlowMultiRoleRequired) {
          // Only show if state actually changed to MultiRoleRequired
          if (previous is! LoginFlowMultiRoleRequired && mounted) {
            _showMultiRoleSelectionDialog(next);
          }
        }
      },
    );

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: _bgDark1,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                  color: const Color(0xFFBF8719),
                  iconSize: 24,
                ),
              const SizedBox(height: 16),
              _buildLogoSection(),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    LoginInputField(
                  controller: _emailController,
                      label: 'Adresse email',
                  hint: 'votre@email.com',
                  icon: Icons.mail_outline,
                      validator: _validateEmail,
                      enabled: !isLoading,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                          focusNode: _emailFocusNode,
                          validateOnChange: _emailHasBeenValidated,
                ),
                const SizedBox(height: 16),
                    LoginInputField(
                  controller: _passwordController,
                  label: 'Mot de passe',
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                      obscure: !_isPasswordVisible,
                      validator: _validatePassword,
                      enabled: !isLoading,
                          textInputAction: TextInputAction.done,
                          autocorrect: false,
                          enableSuggestions: false,
                          focusNode: _passwordFocusNode,
                      suffixIcon: _isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      onSuffixTap: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                ),
                const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          showDialog(
                            context: context,
                            builder: (context) => const ForgotPasswordDialog(),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: _primaryGold,
                        ),
                  child: const Text('Mot de passe oublié ?'),
                      ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFBF8719),
                          disabledBackgroundColor: _borderColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          shadowColor: const Color(0xFFBF8719).withOpacity(0.3),
                          elevation: isLoading ? 4 : 2,
                        ),
                        onPressed: isLoading ? null : _handleLogin,
                        child: isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _bgDark1.withOpacity(0.8),
                                  ),
                                ),
                              )
                            : const Text(
                                'Se connecter',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _bgDark1,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSocialDivider(),
              const SizedBox(height: 16),
              _buildSocialLoginButtons(),
              const SizedBox(height: 24),
              _buildFooter(),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _primaryGold,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _primaryGold, width: 3),
            boxShadow: [
              BoxShadow(
                color: _primaryGold.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            'Y',
            style: TextStyle(
              color: _bgDark1,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Connexion',
          style: TextStyle(
            color: _textLight,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.role == UserRole.client
              ? 'Connectez-vous pour découvrir les commerces'
              : 'Accédez à votre espace professionnel',
          style: TextStyle(
            color: _textGrey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: _borderColor.withOpacity(0.5),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OU',
            style: TextStyle(
              fontSize: 11,
              color: _textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: _borderColor.withOpacity(0.5),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLoginButtons() {
    final isLoading = ref.watch(loginFlowControllerProvider) is LoginFlowLoading;
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(
            label: 'Google',
            iconWidget: _buildGoogleIcon(),
            onPressed: () => _handleSocialLogin('google'),
            isLoading: isLoading,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSocialButton(
            icon: Icons.facebook,
            label: 'Facebook',
            iconColor: const Color(0xFF1877F2),
            onPressed: () => _handleSocialLogin('facebook'),
            isLoading: isLoading,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSocialButton(
            icon: Icons.apple,
            label: 'Apple',
            iconColor: _textLight,
            onPressed: () => _handleSocialLogin('apple'),
            isLoading: isLoading,
            ),
          ),
        ],
    );
  }

  Widget _buildGoogleIcon() {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _GoogleIconPainter(),
      ),
    );
  }

  Widget _buildSocialButton({
    IconData? icon,
    String? label,
    Color? iconColor,
    Widget? iconWidget,
    required VoidCallback onPressed,
    required bool isLoading,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _borderColor, width: 1.5),
          color: _bgDark2,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget ?? Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 4),
            Text(
              label ?? '',
              style: TextStyle(
                fontSize: 10,
                color: _textLight,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSocialLogin(String provider) async {
    // TODO: Implement social login (Google, Facebook, Apple)
    showErrorSnackbar(context, 'Connexion $provider bientôt disponible');
  }

  Widget _buildFooter() {
    return Column(
      children: [
        GestureDetector(
          onTap: widget.onSignup,
          child: Text.rich(
            TextSpan(
              text: 'Vous n\'avez pas de compte ? ',
              style: TextStyle(color: _textGrey, fontSize: 13),
              children: [
                TextSpan(
                  text: 'Créer un compte',
                  style: TextStyle(
                    color: _primaryGold,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
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
      Paint()
        ..color = const Color(0xFFEA4335)
        ..style = PaintingStyle.fill,
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
      Paint()
        ..color = const Color(0xFF34A853)
        ..style = PaintingStyle.fill,
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
      Paint()
        ..color = const Color(0xFFFBBC05)
        ..style = PaintingStyle.fill,
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
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
