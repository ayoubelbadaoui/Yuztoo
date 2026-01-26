import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/cities.dart';
import '../application/providers.dart';
import '../../core/application/auth_error_mapper.dart';
import '../../../../core/shared/widgets/snackbar.dart';
import '../../../../types.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({
    Key? key,
    required this.role,
    required this.onBack,
    required this.onSignupSuccess,
  }) : super(key: key);

  final UserRole role;
  final VoidCallback onBack;
  final Function(
    String userId,
    String phoneNumber,
    String? verificationId,
    String email,
    String city, {
    String? otpUnavailableMessage,
  }) onSignupSuccess; // Pass signup data

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
  
  // Controllers
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  
  // Focus Nodes
  late FocusNode _emailFocusNode;
  late FocusNode _passwordFocusNode;
  late FocusNode _confirmPasswordFocusNode;
  late FocusNode _phoneFocusNode;

  // State variables
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isPasswordFocused = false;
  String? _selectedCity;
  String? _phoneNumber;
  String _selectedCountryCode = '+33';
  String _selectedCountryName = 'France';
  String _selectedCountryFlag = '🇫🇷';
  String _selectedRole = 'client';
  String? _phoneVerificationId;
  
  // Track if fields have been validated (error shown)
  bool _emailFieldHasBeenValidated = false;
  bool _passwordFieldHasBeenValidated = false;
  
  // Real-time validation state
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  final List<Map<String, String>> countryCodes = [
    {'code': '+33', 'name': 'France', 'flag': '🇫🇷'},
    {'code': '+1', 'name': 'États-Unis', 'flag': '🇺🇸'},
    {'code': '+44', 'name': 'Royaume-Uni', 'flag': '🇬🇧'},
    {'code': '+34', 'name': 'Espagne', 'flag': '🇪🇸'},
    {'code': '+49', 'name': 'Allemagne', 'flag': '🇩🇪'},
    {'code': '+39', 'name': 'Italie', 'flag': '🇮🇹'},
    {'code': '+31', 'name': 'Pays-Bas', 'flag': '🇳🇱'},
    {'code': '+32', 'name': 'Belgique', 'flag': '🇧🇪'},
    {'code': '+41', 'name': 'Suisse', 'flag': '🇨🇭'},
    {'code': '+43', 'name': 'Autriche', 'flag': '🇦🇹'},
    {'code': '+351', 'name': 'Portugal', 'flag': '🇵🇹'},
    {'code': '+30', 'name': 'Grèce', 'flag': '🇬🇷'},
    {'code': '+46', 'name': 'Suède', 'flag': '🇸🇪'},
    {'code': '+47', 'name': 'Norvège', 'flag': '🇳🇴'},
    {'code': '+45', 'name': 'Danemark', 'flag': '🇩🇰'},
    {'code': '+358', 'name': 'Finlande', 'flag': '🇫🇮'},
    {'code': '+48', 'name': 'Pologne', 'flag': '🇵🇱'},
    {'code': '+420', 'name': 'République tchèque', 'flag': '🇨🇿'},
    {'code': '+36', 'name': 'Hongrie', 'flag': '🇭🇺'},
    {'code': '+40', 'name': 'Roumanie', 'flag': '🇷🇴'},
    {'code': '+212', 'name': 'Maroc', 'flag': '🇲🇦'},
    {'code': '+216', 'name': 'Tunisie', 'flag': '🇹🇳'},
    {'code': '+213', 'name': 'Algérie', 'flag': '🇩🇿'},
    {'code': '+20', 'name': 'Égypte', 'flag': '🇪🇬'},
    {'code': '+27', 'name': 'Afrique du Sud', 'flag': '🇿🇦'},
    {'code': '+81', 'name': 'Japon', 'flag': '🇯🇵'},
    {'code': '+82', 'name': 'Corée du Sud', 'flag': '🇰🇷'},
    {'code': '+86', 'name': 'Chine', 'flag': '🇨🇳'},
    {'code': '+91', 'name': 'Inde', 'flag': '🇮🇳'},
    {'code': '+61', 'name': 'Australie', 'flag': '🇦🇺'},
    {'code': '+64', 'name': 'Nouvelle-Zélande', 'flag': '🇳🇿'},
    {'code': '+55', 'name': 'Brésil', 'flag': '🇧🇷'},
    {'code': '+52', 'name': 'Mexique', 'flag': '🇲🇽'},
    {'code': '+54', 'name': 'Argentine', 'flag': '🇦🇷'},
    {'code': '+56', 'name': 'Chili', 'flag': '🇨🇱'},
  ];

  // Colors - Exact Yuztoo theme
  static const Color bgDark1 = Color(0xFF0F1A29);
  static const Color bgDark2 = Color(0xFF111A2A);
  static const Color primaryGold = Color(0xFFD4A017);
  static const Color textLight = Color(0xFFF5F5F5);
  static const Color textGrey = Color(0xFFB0B0B0);
  static const Color borderColor = Color(0xFF2A3F5F);
  static const Color cardBg = Color(0xFF1A2A3A);
  static const Color errorRed = Color(0xFFE74C3C);
  static const Color successGreen = Color(0xFF27AE60);
  static const transparent = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _phoneController = TextEditingController();
    _cityController = TextEditingController();
    
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
    _confirmPasswordFocusNode = FocusNode();
    _phoneFocusNode = FocusNode();
    
    // Add listener to validate only when field loses focus (blur)
    _emailFocusNode.addListener(() {
      // Validate only when field loses focus (after user changes/interacts with field)
      if (!_emailFocusNode.hasFocus) {
        _emailFieldKey.currentState?.validate();
        // Mark as validated so real-time validation can work when correcting
        setState(() {
          _emailFieldHasBeenValidated = true;
        });
      } else {
        // Reset when field gains focus again (user starts editing)
        setState(() {
          _emailFieldHasBeenValidated = false;
        });
      }
    });
    
    // Add real-time validation for email field when user corrects it (only after error was shown)
    _emailController.addListener(() {
      // Validate in real-time only if field has been validated (error shown) and user is correcting
      if (_emailFieldHasBeenValidated && _emailController.text.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _emailFieldKey.currentState?.validate();
            });
          }
        });
      }
    });
    
    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
      if (!_passwordFocusNode.hasFocus && _passwordController.text.isNotEmpty) {
        _passwordFieldKey.currentState?.validate();
        // Mark as validated so real-time validation can work when correcting
        setState(() {
          _passwordFieldHasBeenValidated = true;
        });
      } else if (_passwordFocusNode.hasFocus) {
        // Reset when field gains focus again (user starts editing)
        setState(() {
          _passwordFieldHasBeenValidated = false;
        });
      }
    });
    
    // Add real-time validation for password field when user corrects it (only after error was shown)
    _passwordController.addListener(() {
      // Validate in real-time only if field has been validated (error shown) and user is correcting
      if (_passwordFieldHasBeenValidated && _passwordController.text.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _passwordFieldKey.currentState?.validate();
            });
          }
        });
      }
    });
    
    _confirmPasswordFocusNode.addListener(() {
      if (!_confirmPasswordFocusNode.hasFocus &&
          _confirmPasswordController.text.isNotEmpty) {
        _confirmPasswordFieldKey.currentState?.validate();
      }
    });
    
    _phoneFocusNode.addListener(() {
      if (!_phoneFocusNode.hasFocus && _phoneController.text.isNotEmpty) {
        _phoneFieldKey.currentState?.validate();
      }
    });
    
    // Validation only happens on blur (when leaving field), not while typing
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  // Validation methods
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'adresse e-mail est requise.';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Adresse e-mail invalide.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis.';
    }
    if (value.length < 8) {
      return 'Au minimum 8 caractères.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Doit contenir une majuscule.';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Doit contenir une minuscule.';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Doit contenir un chiffre.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirmez votre mot de passe.';
    }
    if (value != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas.';
    }
    return null;
  }

  void _unfocusAllFields() {
    _emailFocusNode.unfocus();
    _passwordFocusNode.unfocus();
    _confirmPasswordFocusNode.unfocus();
    _phoneFocusNode.unfocus();
  }

  String _formatPhoneNumber(String countryCode, String rawInput) {
    final trimmed = rawInput.trim();
    final countryDigits = countryCode.replaceAll(RegExp(r'\\D'), '');
    var digits = trimmed.replaceAll(RegExp(r'\\D'), '');

    // If user already typed an international number (starts with +)
    if (trimmed.startsWith('+')) {
      // Normalize to +<digits> without leading zeros after +
      digits = digits.replaceFirst(RegExp(r'^0+'), '');
      return '+$digits';
    }

    // If user typed an international number with 00 prefix
    if (digits.startsWith('00')) {
      digits = digits.substring(2).replaceFirst(RegExp(r'^0+'), '');
      return '+$digits';
    }

    // If user typed full number including country code (without +), don't double it
    if (countryDigits.isNotEmpty && digits.startsWith(countryDigits)) {
      return '+$digits';
    }

    // Otherwise, treat as national number and strip trunk prefix
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
    return '$countryCode$digits';
  }

  bool _isValidE164(String phoneNumber) {
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    // E.164 allows up to 15 digits (country code + national number)
    return digits.length >= 8 && digits.length <= 15;
  }

  String? _validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'La ville est requise.';
    }
    return null;
  }

  Future<void> _handleSignup() async {
    // Validate form - errors will show for all invalid fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if phone number is provided
    if (_phoneNumber == null || _phoneNumber!.isEmpty || _phoneController.text.isEmpty) {
      if (mounted) {
        showErrorSnackbar(context, 'Le numéro de téléphone est requis.');
      }
      return;
    }
    final formattedPhoneNumber =
        _formatPhoneNumber(_selectedCountryCode, _phoneController.text);
    if (!_isValidE164(formattedPhoneNumber)) {
      if (mounted) {
        showErrorSnackbar(
          context,
          'Numéro de téléphone invalide. Vérifiez le format.',
        );
      }
      return;
    }

    // Check if city is selected
    if (_selectedCity == null || _selectedCity!.isEmpty) {
      if (mounted) {
        showErrorSnackbar(context, 'La ville est requise.');
      }
      return;
    }

    if (_isLoading) return;

    setState(() => _isLoading = true);

    // 1. Create user with email/password
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    final signupUseCase = ref.read(signupWithEmailPasswordProvider);
    final signupResult = await signupUseCase.call(email: email, password: password);

    signupResult.fold(
      (failure) {
        if (mounted) {
          final frenchMessage = AuthErrorMapper.getFrenchMessage(failure);
          // Only show error if it's a specific Firebase error (not generic)
          if (frenchMessage != null) {
            showErrorSnackbar(context, frenchMessage);
          }
          setState(() => _isLoading = false);
        }
      },
      (authUser) async {
        // User created successfully - proceed to phone verification
        if (mounted) {
          // 2. Send OTP for phone verification
          final phoneNumber = formattedPhoneNumber; // E.164 formatted
          final sendOtpUseCase = ref.read(sendPhoneVerificationProvider);
          final otpResult = await sendOtpUseCase.call(phoneNumber: phoneNumber);
          final failure = otpResult.leftOrNull;
          if (failure != null) {
            final frenchMessage = AuthErrorMapper.getFrenchMessage(failure);
            // Only proceed if we have a specific error message (Firebase error)
            if (frenchMessage == null) {
              // Generic error - don't show, just continue silently
              if (mounted) {
                setState(() => _isLoading = false);
              }
              return;
            }
            final isBillingBlocked =
                frenchMessage.toLowerCase().contains('facturation') ||
                    frenchMessage.contains('BILLING_NOT_ENABLED');
            
            // Always navigate to OTP screen, even if billing is disabled
            // This allows the user to see the error message and understand what happened
            if (mounted) {
              setState(() => _isLoading = false);
              // Navigate to OTP screen with empty verificationId and error message
              widget.onSignupSuccess(
                authUser.id, // Pass user ID to avoid Firebase import in presentation
                phoneNumber,
                null, // OTP screen will send OTP automatically
                email,
                _selectedCity!,
                otpUnavailableMessage: frenchMessage, // Pass the error message to OTP screen
              );
            }
            
            // Only delete user if it's NOT a billing error
            // For billing errors, keep the user so they can try again later when billing is enabled
            if (!isBillingBlocked) {
              // Roll back created auth user if OTP couldn't be sent (non-billing error)
              final deleteUserUseCase = ref.read(deleteCurrentUserProvider);
              await deleteUserUseCase.call();
            }
            return;
          }

          final verificationId = otpResult.rightOrNull!;
          // Store verificationId for later use
          if (mounted) {
            setState(() {
              _phoneVerificationId = verificationId;
              _isLoading = false;
            });

            showSuccessSnackbar(context, 'Code de vérification envoyé!');
            // Navigate to OTP screen with all signup data
            widget.onSignupSuccess(
              authUser.id, // Pass user ID to avoid Firebase import in presentation
              phoneNumber,
              verificationId,
              email,
              _selectedCity!,
            );
          }
        }
      },
    );
  }

  /// Build roles map based on user role
  Map<String, bool> _buildRolesMap() {
    if (widget.role == UserRole.client) {
      return {
        'client': true,
        'merchant': false,
        'provider': false,
      };
    } else {
      return {
        'client': false,
        'merchant': true,
        'provider': false,
      };
    }
  }


  void _clearForm() {
    // Reset form state
    _formKey.currentState?.reset();
    
    // Clear all controllers
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _phoneController.clear();
    
    // Reset state variables
    setState(() {
      _selectedCity = null;
      _phoneNumber = null;
      _phoneVerificationId = null;
      _isPasswordVisible = false;
      _isConfirmPasswordVisible = false;
      _isPasswordFocused = false;
      _isLoading = false;
    });
    
    // Unfocus all fields
    _emailFocusNode.unfocus();
    _passwordFocusNode.unfocus();
    _confirmPasswordFocusNode.unfocus();
    _phoneFocusNode.unfocus();
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading, // Prevent back navigation during loading
      onPopInvoked: (didPop) {
        if (!didPop && !_isLoading) {
          // Handle Android back button
          widget.onBack();
        }
      },
      child: Scaffold(
        backgroundColor: bgDark1,
        body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                  color: const Color(0xFFBF8719),
                  iconSize: 24,
                ),
              ),
              _buildLogoSection(),
              const SizedBox(height: 32),
              _buildSignupForm(),
              const SizedBox(height: 24),
              _buildSignupButton(),
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
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryGold, width: 3),
            boxShadow: [
              BoxShadow(
                color: primaryGold.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on,
            color: primaryGold,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'yuztoo',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textLight,
                ),
              ),
            ],
          ),
        ),
        const Text(
          'pour eux, pour vous',
          style: TextStyle(
            fontSize: 12,
            color: textGrey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Créez votre compte',
          style: TextStyle(
            fontSize: 18,
            color: textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.disabled, // Disable form-level validation
      child: Column(
        children: [
          _buildTextField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            label: 'Adresse email',
            hint: 'votre@email.com',
            keyboardType: TextInputType.emailAddress,
            icon: Icons.mail_outline,
            validator: _validateEmail,
            enabled: !_isLoading,
            onTap: () {
              _unfocusAllFields();
              _emailFocusNode.requestFocus();
            },
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            label: 'Mot de passe',
            hint: 'Min. 8 caractères',
            validator: _validatePassword,
            enabled: !_isLoading,
            onTap: () {
              _unfocusAllFields();
              _passwordFocusNode.requestFocus();
            },
          ),
          if (_isPasswordFocused) ...[
            const SizedBox(height: 12),
            _buildPasswordHint(),
          ],
          const SizedBox(height: 16),
          _buildConfirmPasswordField(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocusNode,
            label: 'Confirmer mot de passe',
            hint: 'Répétez votre mot de passe',
            validator: _validateConfirmPassword,
            enabled: !_isLoading,
            onTap: () {
              _unfocusAllFields();
              _confirmPasswordFocusNode.requestFocus();
            },
          ),
          const SizedBox(height: 16),
          _buildPhoneField(),
          const SizedBox(height: 16),
          _buildCityDropdown(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textGrey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: _emailFieldKey,
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          keyboardType: keyboardType,
          validator: validator,
          autovalidateMode: AutovalidateMode.disabled,
          cursorColor: const Color(0xFFBF8719),
          onTap: onTap,
          onChanged: (value) {
            // Real-time validation when correcting wrong email (only after error was shown)
            if (_emailFieldHasBeenValidated && controller == _emailController && value.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _emailFieldKey.currentState?.validate();
                  });
                }
              });
            }
          },
          style: const TextStyle(
            color: textLight,
            fontSize: 14,
            decoration: TextDecoration.none,
            decorationColor: Colors.transparent,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: textGrey,
              fontSize: 13,
              decoration: TextDecoration.none,
            ),
            prefixIcon: Icon(icon, color: primaryGold, size: 18),
            filled: true,
            fillColor: bgDark2,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primaryGold, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: errorRed, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor, width: 1),
            ),
            errorStyle: const TextStyle(
              color: errorRed,
              fontSize: 11,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textGrey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: _passwordFieldKey,
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          obscureText: !_isPasswordVisible,
          validator: validator,
          autovalidateMode: AutovalidateMode.disabled, // Validate only on blur via FocusNode listener
          cursorColor: const Color(0xFFBF8719),
          onTap: onTap,
          onChanged: (value) {
            // Real-time validation when correcting wrong password (only after error was shown)
            if (_passwordFieldHasBeenValidated && controller == _passwordController && value.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _passwordFieldKey.currentState?.validate();
                  });
                }
              });
            }
          },
          style: const TextStyle(color: textLight, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: textGrey, fontSize: 13),
            prefixIcon: Icon(Icons.lock_outline, color: primaryGold, size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: primaryGold,
                size: 20,
              ),
              onPressed: enabled
                  ? () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible)
                  : null,
            ),
            filled: true,
            fillColor: bgDark2,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primaryGold, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: errorRed, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor, width: 1),
            ),
            errorStyle: const TextStyle(
              color: errorRed,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 14,
            color: textGrey,
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              '8+ caractères, majuscules, minuscules et chiffres',
              style: TextStyle(
                fontSize: 11,
                color: textGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textGrey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: _confirmPasswordFieldKey,
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          obscureText: !_isConfirmPasswordVisible,
          validator: validator,
          autovalidateMode: AutovalidateMode.disabled, // Validate only on blur via FocusNode listener
          cursorColor: const Color(0xFFBF8719),
          onTap: onTap,
          style: const TextStyle(color: textLight, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: textGrey, fontSize: 13),
            prefixIcon: Icon(Icons.lock_outline, color: primaryGold, size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: primaryGold,
                size: 20,
              ),
              onPressed: enabled
                  ? () => setState(
                      () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible)
                  : null,
            ),
            filled: true,
            fillColor: bgDark2,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primaryGold, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: errorRed, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor, width: 1),
            ),
            errorStyle: const TextStyle(
              color: errorRed,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Numéro de téléphone',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textGrey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Country code button
            GestureDetector(
              onTap: _isLoading ? null : () => _showCountryCodeModal(context),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: 1),
                  color: bgDark2,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedCountryCode,
                      style: const TextStyle(
                        color: textLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.expand_more,
                      color: primaryGold,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Phone number field
            Expanded(
              child: TextFormField(
                key: _phoneFieldKey,
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                enabled: !_isLoading,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  // Only allow numbers - reject any symbols
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le numéro est requis.';
                  }
                  if (value.length < 8) {
                    return 'Numéro invalide.';
                  }
                  // Additional regex check to ensure only numbers
                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return 'Seuls les chiffres sont autorisés.';
                  }
                  return null;
                },
                autovalidateMode: AutovalidateMode.disabled, // Validate only on blur via FocusNode listener
                cursorColor: const Color(0xFFBF8719),
                onTap: () {
                  _unfocusAllFields();
                  _phoneFocusNode.requestFocus();
                },
                style: const TextStyle(color: textLight, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '612345678',
                  hintStyle: const TextStyle(color: textGrey, fontSize: 13),
                  filled: true,
                  fillColor: bgDark2,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: borderColor, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: borderColor, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: primaryGold, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: errorRed, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: errorRed, width: 1.5),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: borderColor, width: 1),
                  ),
                  errorStyle: const TextStyle(
                    color: errorRed,
                    fontSize: 11,
                  ),
                  errorMaxLines: 1,
                ),
                onChanged: (value) {
                  setState(() {
                    _phoneNumber =
                        _formatPhoneNumber(_selectedCountryCode, value);
                  });
                  // If phone field already shows an error, re-validate to clear it when corrected
                  if (_phoneFieldKey.currentState?.hasError == true) {
                    _phoneFieldKey.currentState?.validate();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showCountryCodeModal(BuildContext context) {
    final TextEditingController searchController = TextEditingController();
    List<Map<String, String>> filteredCountries = countryCodes;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgDark2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: borderColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sélectionnez votre pays',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Search field
                      TextField(
                        controller: searchController,
                        style: const TextStyle(color: textLight, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Rechercher un pays...',
                          hintStyle:
                              const TextStyle(color: textGrey, fontSize: 13),
                          prefixIcon: Icon(Icons.search, color: primaryGold),
                          filled: true,
                          fillColor: bgDark1,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: borderColor, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: borderColor, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: primaryGold,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            if (value.isEmpty) {
                              filteredCountries = countryCodes;
                            } else {
                              filteredCountries = countryCodes
                                  .where((country) =>
                                      country['name']!
                                          .toLowerCase()
                                          .contains(value.toLowerCase()) ||
                                      country['code']!
                                          .contains(value.toLowerCase()))
                                  .toList();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
                // Countries list
                Expanded(
                  child: filteredCountries.isEmpty
                      ? Center(
                          child: Text(
                            'Aucun pays trouvé',
                            style: TextStyle(
                              fontSize: 14,
                              color: textGrey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: filteredCountries.length,
                          itemBuilder: (context, index) {
                            final country = filteredCountries[index];
                            final isSelected =
                                _selectedCountryCode == country['code'];

                            return GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                this.setState(() {
                                  _selectedCountryCode = country['code']!;
                                  _selectedCountryName = country['name']!;
                                  _selectedCountryFlag = country['flag']!;
                                  // Update phone number with new country code
                                  if (_phoneController.text.isNotEmpty) {
                                    _phoneNumber = _formatPhoneNumber(
                                      country['code']!,
                                      _phoneController.text,
                                    );
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: isSelected
                                      ? primaryGold.withOpacity(0.15)
                                      : transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? primaryGold
                                        : transparent,
                                    width: isSelected ? 2 : 0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(
                                            country['flag']!,
                                            style: const TextStyle(
                                                fontSize: 24),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  country['name']!,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: isSelected
                                                        ? primaryGold
                                                        : textLight,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.w400,
                                                  ),
                                                ),
                                                Text(
                                                  country['code']!,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isSelected
                                                        ? primaryGold
                                                            .withOpacity(0.7)
                                                        : textGrey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: primaryGold,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
            ),
            );
          },
        );
      },
    );
  }

  Widget _buildCityDropdown() {
    return FormField<String>(
      key: _cityFieldKey,
      validator: (value) {
        if (_selectedCity == null || _selectedCity!.isEmpty) {
          return 'La ville est requise.';
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.disabled, // Validate only on blur via manual validation
      builder: (FormFieldState<String> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ville',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textGrey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _isLoading
                  ? null
                  : () {
                      _unfocusAllFields();
                      _showCitySelectionModal(context, frenchCities);
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: state.hasError ? errorRed : borderColor,
                    width: state.hasError ? 1.5 : 1,
                  ),
                  color: bgDark2,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_city_outlined,
                      color: primaryGold,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedCity ?? 'Sélectionnez votre ville',
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedCity != null ? textLight : textGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(
                    color: errorRed,
                    fontSize: 11,
                    height: 1.0,
                  ),
                  maxLines: 1,
                ),
              ),
          ],
        );
      },
    );
  }

  void _showCitySelectionModal(BuildContext context, List<String> cities) {
    final TextEditingController searchController = TextEditingController();
    List<String> filteredCities = cities;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgDark2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: borderColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sélectionnez votre ville',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Search field
                      TextField(
                        controller: searchController,
                        style: const TextStyle(color: textLight, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Rechercher une ville...',
                          hintStyle:
                              const TextStyle(color: textGrey, fontSize: 13),
                          prefixIcon: Icon(Icons.search, color: primaryGold),
                          filled: true,
                          fillColor: bgDark1,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: borderColor, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: borderColor, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: primaryGold,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            if (value.isEmpty) {
                              filteredCities = cities;
                            } else {
                              filteredCities = cities
                                  .where((city) => city
                                      .toLowerCase()
                                      .contains(value.toLowerCase()))
                                  .toList();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
                // Cities list
                Expanded(
                  child: filteredCities.isEmpty
                      ? Center(
                          child: Text(
                            'Aucune ville trouvée',
                            style: TextStyle(
                              fontSize: 14,
                              color: textGrey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: filteredCities.length,
                          itemBuilder: (context, index) {
                            final city = filteredCities[index];
                            final isSelected = _selectedCity == city;

                            return GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                // Update city and validate after modal closes
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    setState(() {
                                      _selectedCity = city;
                                    });
                                    // Validate city field after selection
                                    _cityFieldKey.currentState?.validate();
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: isSelected
                                      ? primaryGold.withOpacity(0.15)
                                      : transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? primaryGold
                                        : transparent,
                                    width: isSelected ? 2 : 0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      city,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isSelected
                                            ? primaryGold
                                            : textLight,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: primaryGold,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
            ),
            );
          },
        );
      },
    );
  }

  Widget _buildSignupButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFBF8719),
          disabledBackgroundColor: borderColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          shadowColor: const Color(0xFFBF8719).withOpacity(0.3),
          elevation: _isLoading ? 4 : 2,
        ),
        onPressed: _isLoading ? null : _handleSignup,
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(bgDark1.withOpacity(0.8)),
                ),
              )
            : const Text(
                'Créer un compte',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: bgDark1,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  Widget _buildSocialDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: borderColor.withOpacity(0.5),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OU',
            style: TextStyle(
              fontSize: 11,
              color: textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: borderColor.withOpacity(0.5),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLoginButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(
            label: 'Google',
            iconWidget: _buildGoogleIcon(),
            onPressed: () => _handleSocialLogin('google'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSocialButton(
            icon: Icons.facebook,
            label: 'Facebook',
            iconColor: const Color(0xFF1877F2),
            onPressed: () => _handleSocialLogin('facebook'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSocialButton(
            icon: Icons.apple,
            label: 'Apple',
            iconColor: textLight,
            onPressed: () => _handleSocialLogin('apple'),
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
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.5),
          color: bgDark2,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget ?? Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 4),
            Text(
              label ?? '',
              style: const TextStyle(
                fontSize: 10,
                color: textLight,
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
          onTap: widget.onBack,
          child: Text.rich(
            TextSpan(
              text: 'Vous avez un compte ? ',
              style: const TextStyle(color: textGrey, fontSize: 13),
              children: [
                TextSpan(
                  text: 'Connectez-vous',
                  style: const TextStyle(
                    color: primaryGold,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Opacity(
          opacity: 0.6,
          child: Text(
            'En continuant, vous acceptez nos conditions d\'utilisation',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: textGrey,
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
    // Scale factor: SVG viewBox is 24x24, we need to scale to actual size
    final scale = size.width / 24.0;
    final matrix = Matrix4.identity()..scale(scale);

    // Red path - #EA4335
    // M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z
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
      Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.fill,
    );

    // Green path - #34A853
    // M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z
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
      Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.fill,
    );

    // Yellow path - #FBBC05
    // M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z
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
      Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.fill,
    );

    // Blue path - #4285F4
    // M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z
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
      Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
