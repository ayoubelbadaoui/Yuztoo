import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/providers.dart';
import '../../core/application/auth_error_mapper.dart';
import '../../../../core/shared/widgets/snackbar.dart';
import '../../../../types.dart';
import 'constants/signup_constants.dart';
import 'utils/phone_formatter.dart';
import 'widgets/signup_form_fields.dart';
import 'widgets/signup_ui_widgets.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({
    Key? key,
    required this.role,
    required this.onBack,
    required this.onSignupSuccess,
    this.initialEmail,
    this.initialPassword,
    this.initialPhone,
    this.initialCity,
    this.initialCountryCode,
  }) : super(key: key);

  final UserRole role;
  final VoidCallback onBack;
  final Function(
    String userId,
    String phoneNumber,
    String? verificationId,
    String email,
    String password,
    String city, {
    String? otpUnavailableMessage,
  }) onSignupSuccess;
  
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
    
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _passwordController = TextEditingController(text: widget.initialPassword ?? '');
    _confirmPasswordController = TextEditingController(text: widget.initialPassword ?? '');
    _phoneController = TextEditingController();
    
    if (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) {
      final phoneData = PhoneFormatter.extractPhoneData(widget.initialPhone!);
      if (phoneData != null) {
        _selectedCountryCode = phoneData['countryCode'] ?? '+33';
        _phoneController.text = phoneData['localNumber'] ?? '';
        _phoneNumber = widget.initialPhone;
      }
    }
    
    if (widget.initialCity != null && widget.initialCity!.isNotEmpty) {
      _selectedCity = widget.initialCity;
    }
    
    if (widget.initialCountryCode != null && widget.initialCountryCode!.isNotEmpty) {
      _selectedCountryCode = widget.initialCountryCode!;
      // Country code set, name and flag not needed
    }
    
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
    _confirmPasswordFocusNode = FocusNode();
    _phoneFocusNode = FocusNode();
    
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        _emailFieldKey.currentState?.validate();
        final hasError = _emailFieldKey.currentState?.hasError ?? false;
        if (hasError) {
          setState(() => _emailFieldHasBeenValidated = true);
        }
      }
    });
    
    _emailController.addListener(() {
      if (_emailFieldHasBeenValidated && _emailController.text.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _emailFieldKey.currentState?.validate());
          }
        });
      }
    });
    
    _passwordFocusNode.addListener(() {
      setState(() => _isPasswordFocused = _passwordFocusNode.hasFocus);
      if (!_passwordFocusNode.hasFocus && _passwordController.text.isNotEmpty) {
        _passwordFieldKey.currentState?.validate();
        final hasError = _passwordFieldKey.currentState?.hasError ?? false;
        if (hasError) {
          setState(() => _passwordFieldHasBeenValidated = true);
        }
      }
    });
    
    _passwordController.addListener(() {
      if (_passwordFieldHasBeenValidated && _passwordController.text.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _passwordFieldKey.currentState?.validate());
          }
        });
      }
    });
    
    _confirmPasswordFocusNode.addListener(() {
      if (!_confirmPasswordFocusNode.hasFocus && _confirmPasswordController.text.isNotEmpty) {
        _confirmPasswordFieldKey.currentState?.validate();
        final hasError = _confirmPasswordFieldKey.currentState?.hasError ?? false;
        if (hasError) {
          setState(() => _confirmPasswordFieldHasBeenValidated = true);
        }
      }
    });
    
    _confirmPasswordController.addListener(() {
      if (_confirmPasswordFieldHasBeenValidated && _confirmPasswordController.text.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _confirmPasswordFieldKey.currentState?.validate());
          }
        });
      }
    });
    
    _phoneFocusNode.addListener(() {
      if (!_phoneFocusNode.hasFocus && _phoneController.text.isNotEmpty) {
        _phoneFieldKey.currentState?.validate();
        final hasError = _phoneFieldKey.currentState?.hasError ?? false;
        if (hasError) {
          setState(() => _phoneFieldHasBeenValidated = true);
        }
      }
    });
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

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_phoneNumber == null || _phoneNumber!.isEmpty || _phoneController.text.isEmpty) {
      if (mounted) {
        showErrorSnackbar(context, 'Le numéro de téléphone est requis.');
      }
      return;
    }
    
    final formattedPhoneNumber = PhoneFormatter.formatPhoneNumber(
      _selectedCountryCode,
      _phoneController.text,
    );
    
    if (!PhoneFormatter.isValidE164(formattedPhoneNumber)) {
      if (mounted) {
        showErrorSnackbar(
          context,
          'Numéro de téléphone invalide. Vérifiez le format.',
        );
      }
      return;
    }

    if (_selectedCity == null || _selectedCity!.isEmpty) {
      if (mounted) {
        showErrorSnackbar(context, 'La ville est requise.');
      }
      return;
    }

    if (_isLoading) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final phoneNumber = formattedPhoneNumber;
    
    final sendOtpUseCase = ref.read(sendPhoneVerificationProvider);
    final otpResult = await sendOtpUseCase.call(phoneNumber: phoneNumber);

    otpResult.fold(
      (failure) {
        if (mounted) {
          final frenchMessage = AuthErrorMapper.getFrenchMessage(failure);
          if (frenchMessage != null) {
            showErrorSnackbar(context, frenchMessage);
          }
          setState(() => _isLoading = false);
        }
      },
      (verificationId) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          showSuccessSnackbar(context, 'Code de vérification envoyé!');
          widget.onSignupSuccess(
            '',
            phoneNumber,
            verificationId,
            email,
            password,
            _selectedCity!,
          );
        }
      },
    );
  }

  Future<void> _handleSocialLogin(String provider) async {
    showErrorSnackbar(context, 'Connexion $provider bientôt disponible');
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: SignupConstants.bgDark1, // Same color as background
        statusBarIconBrightness: Brightness.light, // Light icons for dark background
        statusBarBrightness: Brightness.dark, // For iOS
        systemNavigationBarColor: SignupConstants.bgDark1, // Same color as background
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: !_isLoading,
        onPopInvoked: (didPop) {
          if (!didPop && !_isLoading) {
            widget.onBack();
          }
        },
        child: Scaffold(
          backgroundColor: SignupConstants.bgDark1,
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
                const SignupLogoSection(),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.disabled,
                  child: Column(
                    children: [
                      EmailField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        fieldKey: _emailFieldKey,
                        hasBeenValidated: _emailFieldHasBeenValidated,
                        enabled: !_isLoading,
                        onUnfocusAll: _unfocusAllFields,
                      ),
                      const SizedBox(height: 16),
                      PasswordField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        fieldKey: _passwordFieldKey,
                        hasBeenValidated: _passwordFieldHasBeenValidated,
                        enabled: !_isLoading,
                        onUnfocusAll: _unfocusAllFields,
                        onFocusChanged: (isFocused) {
                          setState(() => _isPasswordFocused = isFocused);
                        },
                      ),
                      if (_isPasswordFocused) ...[
                        const SizedBox(height: 12),
                        const PasswordHint(),
                      ],
                      const SizedBox(height: 16),
                      ConfirmPasswordField(
                        controller: _confirmPasswordController,
                        passwordController: _passwordController,
                        focusNode: _confirmPasswordFocusNode,
                        fieldKey: _confirmPasswordFieldKey,
                        hasBeenValidated: _confirmPasswordFieldHasBeenValidated,
                        enabled: !_isLoading,
                        onUnfocusAll: _unfocusAllFields,
                      ),
                      const SizedBox(height: 16),
                      PhoneField(
                        controller: _phoneController,
                        focusNode: _phoneFocusNode,
                        fieldKey: _phoneFieldKey,
                        selectedCountryCode: _selectedCountryCode,
                        hasBeenValidated: _phoneFieldHasBeenValidated,
                        enabled: !_isLoading,
                        onUnfocusAll: _unfocusAllFields,
                        onPhoneNumberUpdate: (formattedPhone) {
                          setState(() => _phoneNumber = formattedPhone);
                        },
                        onCountryCodeChange: (code) {
                          setState(() => _selectedCountryCode = code);
                        },
                        onRevalidatePhone: () {
                          if (_phoneController.text.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  if (!_phoneFieldHasBeenValidated) {
                                    _phoneFieldHasBeenValidated = true;
                                  }
                                  _phoneFieldKey.currentState?.validate();
                                });
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      CityDropdown(
                        fieldKey: _cityFieldKey,
                        selectedCity: _selectedCity,
                        enabled: !_isLoading,
                        onUnfocusAll: _unfocusAllFields,
                        onCitySelected: (city) {
                          setState(() => _selectedCity = city);
                        },
                        onValidateCity: () {
                          _cityFieldKey.currentState?.validate();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SignupButton(
                  isLoading: _isLoading,
                  onPressed: _handleSignup,
                ),
                const SizedBox(height: 20),
                const SocialDivider(),
                const SizedBox(height: 16),
                SocialLoginButtons(
                  isLoading: _isLoading,
                  onSocialLogin: _handleSocialLogin,
                ),
                const SizedBox(height: 24),
                SignupFooter(
                  onBack: widget.onBack,
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
