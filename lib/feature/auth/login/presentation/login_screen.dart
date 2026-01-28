import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme.dart';
import '../../../../types.dart';
import '../application/providers.dart';
import '../application/state/login_flow_state.dart';
import '../../core/application/auth_error_mapper.dart';
import '../../../../core/shared/widgets/snackbar.dart';
import '../../signup/presentation/widgets/city_selection_modal.dart';
import '../../signup/presentation/constants/signup_constants.dart';
import '../../../../core/utils/cities.dart';
import 'widgets/input_field.dart';
import '../../core/domain/value_objects/email_address.dart';
import '../../core/domain/value_objects/password.dart';

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
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleSubmit() async {
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
    CitySelectionModal.show(
      context,
      cities: frenchCities,
      selectedCity: null,
      onCitySelected: (city) {
        final loginFlowController = ref.read(loginFlowControllerProvider.notifier);
        loginFlowController.updateCity(uid, city);
      },
      onValidateCity: () {},
    );
  }

  void _showMultiRoleSelectionDialog(LoginFlowMultiRoleRequired state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SignupConstants.bgDark2,
        title: const Text(
          'Continuer en tant que:',
          style: TextStyle(color: SignupConstants.textLight),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.roles['client'] == true)
              ListTile(
                title: const Text(
                  'Client',
                  style: TextStyle(color: SignupConstants.textLight),
                ),
                onTap: () {
                  Navigator.pop(context);
                  final loginFlowController = ref.read(loginFlowControllerProvider.notifier);
                  loginFlowController.selectRole(state.uid, UserRole.client, state.city);
                },
              ),
            if (state.roles['merchant'] == true)
              ListTile(
                title: const Text(
                  'Marchand',
                  style: TextStyle(color: SignupConstants.textLight),
                ),
                onTap: () {
                  Navigator.pop(context);
                  final loginFlowController = ref.read(loginFlowControllerProvider.notifier);
                  loginFlowController.selectRole(state.uid, UserRole.merchant, state.city);
                },
              ),
          ],
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }
    if (!EmailAddress.isValid(value)) {
      return 'Email invalide';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (!Password.isValid(value)) {
      return 'Le mot de passe doit contenir au moins 8 caractères';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final loginFlowState = ref.watch(loginFlowControllerProvider);
    final isLoading = loginFlowState is LoginFlowLoading;

    // Listen to login flow state changes (must be in build method)
    ref.listen<LoginFlowState>(loginFlowControllerProvider, (previous, next) {
      if (next is LoginFlowSuccess) {
        widget.onLoginSuccess(
          uid: next.uid,
          role: next.role,
          city: next.city,
          onboardingCompleted: next.onboardingCompleted,
        );
      } else if (next is LoginFlowError) {
        final frenchMessage = AuthErrorMapper.getFrenchMessage(next.failure);
        if (frenchMessage != null && mounted) {
          showErrorSnackbar(context, frenchMessage);
        }
      } else if (next is LoginFlowCityRequired) {
        _showCityPicker(next.uid);
      } else if (next is LoginFlowMultiRoleRequired) {
        _showMultiRoleSelectionDialog(next);
      }
    });

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back),
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: YColors.primary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: YColors.secondary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Y',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Connexion',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.role == UserRole.client
                        ? 'Connectez-vous pour découvrir les commerces'
                        : 'Accédez à votre espace professionnel',
                    style: TextStyle(color: YColors.muted),
                  ),
                  const SizedBox(height: 24),
                  LoginInputField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'votre@email.com',
                    icon: Icons.mail_outline,
                    validator: _validateEmail,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 16),
                  LoginInputField(
                    controller: _passwordController,
                    label: 'Mot de passe',
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    obscure: _obscurePassword,
                    validator: _validatePassword,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: isLoading ? null : () {},
                    style: TextButton.styleFrom(foregroundColor: YColors.secondary),
                    child: const Text('Mot de passe oublié ?'),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleSubmit,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Se connecter'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Vous n'avez pas de compte ?",
                        style: TextStyle(color: YColors.muted),
                      ),
                      TextButton(
                        onPressed: isLoading ? null : widget.onSignup,
                        style: TextButton.styleFrom(foregroundColor: YColors.secondary),
                        child: const Text("S'inscrire"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

