import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/providers.dart';
import '../../core/application/auth_error_mapper.dart';
import '../../../../core/shared/widgets/snackbar.dart';
import '../../../../core/infrastructure/logger_service.dart';
import '../../../../types.dart';
import 'utils/phone_formatter.dart';
import '../../../merchant/application/providers.dart' as merchant_providers;
import '../../../merchant/domain/merchant_failure.dart';
import '../../../merchant_onboarding/application/providers.dart' as onboarding_providers;

class OTPScreen extends ConsumerStatefulWidget {
  const OTPScreen({
    super.key,
    required this.onBack,
    required this.userId,
    required this.phone,
    required this.onResend,
    required this.email,
    required this.password,
    required this.city,
    required this.role,
    this.otpUnavailableMessage,
    this.verificationId,
  });

  final VoidCallback onBack;
  final String userId; // User ID (empty until OTP verified and user created)
  final String phone;
  final VoidCallback onResend;
  final String email;
  final String password; // Password for user creation after OTP verification
  final String city;
  final UserRole role;
  final String? otpUnavailableMessage;
  final String? verificationId; // Optional, for resend functionality

  @override
  ConsumerState<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends ConsumerState<OTPScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  
  int _resendTimer = 60; // 60 seconds
  bool _canResend = false;
  bool _isVerifying = false;
  bool _otpBlocked = false;
  bool _isCreatingMerchant = false; // Guard against multiple merchant creation attempts
  String? _otpUnavailableMessage;
  Timer? _timer;

  // Colors - Match signup screen dark theme
  static const Color bgDark1 = Color(0xFF0F1A29);
  static const Color bgDark2 = Color(0xFF111A2A);
  static const Color primaryGold = Color(0xFFD4A017);
  static const Color textLight = Color(0xFFF5F5F5);
  static const Color textGrey = Color(0xFFB0B0B0);
  static const Color borderColor = Color(0xFF2A3F5F);
  static const Color errorRed = Color(0xFFE74C3C);

  @override
  void initState() {
    super.initState();
    _otpUnavailableMessage = widget.otpUnavailableMessage;

    // Profile creation should ONLY happen after OTP verification is successful
    // Remove auto-verification shortcut - user must always verify OTP code manually

    if (widget.verificationId == null || widget.verificationId!.isEmpty) {
      _otpBlocked = true;
      if (_otpUnavailableMessage == null || _otpUnavailableMessage!.isEmpty) {
        _otpUnavailableMessage =
            'SMS indisponible pour le moment. Veuillez contacter le support.';
      }
      // Error message will be displayed in UI (red text in _buildLogoSection)
      return;
    }

    _startResendTimer();
    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    // FIX HIGH 9: Proper cleanup to prevent memory leaks
    _timer?.cancel();
    _timer = null;
    
    for (final c in _controllers) {
      c.dispose();
    }
    _controllers.clear();
    
    for (final f in _focusNodes) {
      f.dispose();
    }
    _focusNodes.clear();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendTimer = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendTimer > 0) {
            _resendTimer--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  void _onChanged(int index, String value) {
    if (_otpBlocked) return;
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    
    final code = _controllers.map((c) => c.text).join();
    if (code.length == 6 && !_isVerifying) {
      _verifyOTP(code);
    }
  }

  Future<void> _verifyOTP(String smsCode) async {
    if (widget.verificationId == null || widget.verificationId!.isEmpty) {
      if (mounted) {
        showErrorSnackbar(context, 'Erreur: ID de vérification manquant');
      }
      return;
    }

    setState(() => _isVerifying = true);

    // Verify OTP and create user with phone + email/password
    // This ensures user is only created after OTP verification
    final verifyPhoneAndCreateUserUseCase = ref.read(verifyPhoneAndCreateUserProvider);
    final verifyResult = await verifyPhoneAndCreateUserUseCase.call(
      verificationId: widget.verificationId!,
      smsCode: smsCode,
      email: widget.email,
      password: widget.password,
    );

    verifyResult.fold(
      (failure) {
        if (mounted) {
          final frenchMessage = AuthErrorMapper.getFrenchMessage(failure);
          // Only show error if it's a specific Firebase error (not generic)
          if (frenchMessage != null) {
            showErrorSnackbar(context, frenchMessage);
          }
          // Clear OTP fields on error so user can retry
          for (final controller in _controllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
          setState(() => _isVerifying = false);
        }
      },
      (authUser) async {
        // User created successfully with phone + email/password - now create Firestore profile
        if (mounted) {
          await _createFirestoreProfile(authUser.id);
        }
      },
    );
  }

  Future<void> _createFirestoreProfile(String userId) async {
    // Use user ID from created user (after OTP verification)

    // Build roles map based on widget.role
    final Map<String, bool> roles = {
      'client': widget.role == UserRole.client,
      'merchant': widget.role == UserRole.merchant,
      'provider': false, // Not used in signup flow
    };

    final createUserDocUseCase = ref.read(createUserDocumentProvider);
    final createResult = await createUserDocUseCase.call(
      uid: userId, // Use userId from created user (after OTP verification)
      email: widget.email,
      phone: widget.phone,
      roles: roles,
      city: widget.city,
    );

    createResult.fold(
      (failure) {
        if (mounted) {
          final frenchMessage = AuthErrorMapper.getFrenchMessage(failure);
          // Only show error if it's a specific Firebase error (not generic)
          if (frenchMessage != null) {
            showErrorSnackbar(context, frenchMessage);
          }
          setState(() => _isVerifying = false);
          // Don't navigate on error - user can retry or go back
        }
      },
      (_) async {
        // Firestore profile created successfully
        if (mounted) {
          // If merchant signup, create merchant document with onboarding data
          if (widget.role == UserRole.merchant) {
            await _createMerchantDocument(userId);
          } else {
            // Client signup - just show success and navigate
            showSuccessSnackbar(context, 'Inscription réussie!');
            // Navigation will be driven by auth state changes (AuthController + navigation provider)
            // Just pop OTP screen; auth stream will emit Authenticated and RootShell will navigate.
            Navigator.of(context).pop();
          }
        }
      },
    );
  }

  /// Generate a better merchant name from available data
  String _generateMerchantName(String email, String? categoryId, String city) {
    // Map category IDs to French names
    final categoryNames = {
      'restaurant': 'Restaurant',
      'retail': 'Commerce',
      'beauty': 'Salon',
      'fitness': 'Salle de sport',
      'services': 'Service',
      'other': 'Commerce',
    };
    
    final categoryName = categoryNames[categoryId] ?? 'Commerce';
    
    // Generate name: "CategoryName City" (e.g., "Restaurant Casablanca")
    // This provides a meaningful default name that can be updated later
    return '$categoryName $city';
  }

  Future<void> _createMerchantDocument(String userId) async {
    // Guard against multiple simultaneous calls
    if (_isCreatingMerchant) {
      LoggerService.logInfo('Merchant creation already in progress, skipping duplicate call');
      return;
    }

    setState(() => _isCreatingMerchant = true);

    try {
      // FIX 6: Authorization check - verify userId matches authenticated user
      // In the signup flow, userId comes from Firebase Auth after OTP verification,
      // so it's already verified. However, we add this check as a security measure.
      // The userId should match the currently authenticated user.
      // Note: At this point in signup flow, user is just created, so we trust the userId
      // from Firebase Auth. In future, if this is called from elsewhere, we should
      // verify against authControllerProvider to ensure userId matches authenticated user.
      
      // Get onboarding state from controller
      final onboardingState = ref.read(onboarding_providers.merchantOnboardingControllerProvider);
      
      // Validate that category is selected (mandatory for onboarding)
      if (onboardingState.selectedCategoryId == null || 
          onboardingState.selectedCategoryId!.isEmpty) {
        if (mounted) {
          showErrorSnackbar(
            context,
            'Erreur: Catégorie non sélectionnée. Veuillez compléter l\'onboarding.',
          );
          setState(() {
            _isVerifying = false;
            _isCreatingMerchant = false;
          });
          // Don't navigate - user needs to complete onboarding
          return;
        }
      }
    
    // Get CompleteMerchantOnboarding use case
    final completeOnboarding = ref.read(merchant_providers.completeMerchantOnboardingProvider);
    
    // Generate a better merchant name from available data
    final merchantName = _generateMerchantName(
      widget.email,
      onboardingState.selectedCategoryId,
      widget.city,
    );
    
    // Call use case with user data and onboarding selections
    final result = await completeOnboarding.call(
      userId: userId,
      name: merchantName, // Use generated name instead of email
      email: widget.email,
      phone: widget.phone,
      city: widget.city,
      categoryId: onboardingState.selectedCategoryId,
      subcategoryId: onboardingState.selectedSubcategoryId,
    );

    result.fold(
      (failure) {
        if (mounted) {
          // Get specific error message
          String errorMessage = 'Profil créé mais erreur lors de la création du commerce.';
          
          // Provide more specific error messages based on failure type
          if (failure is MerchantUnexpectedFailure) {
            final message = failure.message;
            if (message.contains('Category is required') || message.contains('catégorie est requise')) {
              errorMessage = 'Erreur: Catégorie requise. Veuillez compléter l\'onboarding.';
            } else if (message.contains('name is required') || message.contains('nom du commerce')) {
              errorMessage = 'Erreur: Nom du commerce requis.';
            } else {
              errorMessage = 'Erreur lors de la création: $message';
            }
          } else if (failure is MerchantNetworkFailure) {
            errorMessage = 'Erreur de connexion. Vérifiez votre internet et réessayez.';
          } else if (failure is UnableToCreateMerchantFailure) {
            errorMessage = 'Impossible de créer le commerce. Veuillez réessayer plus tard.';
          }
          
          // Show error but don't block navigation - merchant can complete onboarding later
          // The onboarding state is preserved in the controller, so user can retry
          showErrorSnackbar(
            context,
            '$errorMessage Vous pourrez compléter l\'onboarding depuis votre profil.',
          );
          setState(() {
            _isVerifying = false;
            _isCreatingMerchant = false;
          });
          // Still navigate - user document is created, merchant can be created later
          // Navigation will route to merchantOnboarding screen if onboarding is incomplete
          Navigator.of(context).pop();
        }
      },
      (merchant) {
        // Merchant created successfully
        if (mounted) {
          // Reset onboarding state after successful creation
          ref.read(onboarding_providers.merchantOnboardingControllerProvider.notifier).reset();
          
          showSuccessSnackbar(context, 'Inscription réussie! Votre commerce a été créé.');
          setState(() {
            _isVerifying = false;
            _isCreatingMerchant = false;
          });
          // Navigation will be driven by auth state changes (AuthController + navigation provider)
          // Just pop OTP screen; auth stream will emit Authenticated and RootShell will navigate.
          Navigator.of(context).pop();
        }
      },
    );
    } finally {
      // Ensure flag is reset even if error occurs
      if (mounted) {
        setState(() => _isCreatingMerchant = false);
      }
    }
  }

  Future<void> _handleResend() async {
    if (_otpBlocked) {
      if (mounted && _otpUnavailableMessage != null) {
        showErrorSnackbar(context, _otpUnavailableMessage!);
      }
      return;
    }
    if (!_canResend) return;

    final sendOtpUseCase = ref.read(sendPhoneVerificationProvider);
    final otpResult = await sendOtpUseCase.call(phoneNumber: widget.phone);

    otpResult.fold(
      (failure) {
        if (mounted) {
          final frenchMessage = AuthErrorMapper.getFrenchMessage(failure);
          // Only show error if it's a specific Firebase error (not generic)
          if (frenchMessage != null) {
            showErrorSnackbar(context, frenchMessage);
          }
        }
      },
      (verificationId) {
        if (mounted) {
          showSuccessSnackbar(context, 'Code de vérification renvoyé!');
          _startResendTimer();
          widget.onResend();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: bgDark1, // Same color as background
        statusBarIconBrightness: Brightness.light, // Light icons for dark background
        statusBarBrightness: Brightness.dark, // For iOS
        systemNavigationBarColor: bgDark1, // Same color as background
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: PopScope(
        // FIX HIGH 6: Prevent back button during critical operations
        canPop: !_isVerifying && !_isCreatingMerchant, // Use our custom navigation instead of route popping
        onPopInvoked: (didPop) {
          if (!didPop && !_isVerifying && !_isCreatingMerchant) {
            // Handle Android back button
            widget.onBack();
          } else if (!didPop && (_isVerifying || _isCreatingMerchant)) {
            // Show message that operation is in progress
            showErrorSnackbar(
              context,
              'Opération en cours. Veuillez patienter...',
            );
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
              const SizedBox(height: 40),
              _buildOTPFields(),
              const SizedBox(height: 32),
              _buildResendButton(),
            ],
          ),
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
        const SizedBox(height: 20),
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
        const SizedBox(height: 6),
        const Text(
          'pour eux, pour vous',
          style: TextStyle(
            fontSize: 12,
            color: textGrey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Vérification',
          style: TextStyle(
            fontSize: 18,
            color: textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              color: textGrey,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'Entrez le code envoyé au\n'),
              TextSpan(
                text: PhoneFormatter.formatPhoneForDisplay(widget.phone),
                style: const TextStyle(
                  color: primaryGold,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _isVerifying ? null : widget.onBack,
          child: Text(
            'Numéro incorrect ?',
            style: TextStyle(
              fontSize: 13,
              color: _isVerifying ? textGrey.withOpacity(0.5) : primaryGold,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
              decorationColor: _isVerifying ? textGrey.withOpacity(0.5) : primaryGold,
            ),
          ),
        ),
        if (_otpUnavailableMessage != null && _otpUnavailableMessage!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: errorRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: errorRed.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: errorRed, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _otpUnavailableMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: errorRed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOTPFields() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 4,
                  right: index == 5 ? 0 : 4,
                ),
                child: SizedBox(
                  height: 64,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    enabled: !_isVerifying && !_otpBlocked,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    cursorColor: primaryGold,
                    style: const TextStyle(
                      color: textLight,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    onChanged: (value) => _onChanged(index, value),
                    onTap: () {
                      if (!_isVerifying) {
                        // Clear field when tapped
                        _controllers[index].clear();
                      }
                    },
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: bgDark2,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
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
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        if (_isVerifying) ...[
          const SizedBox(height: 16),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(primaryGold),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResendButton() {
    return Column(
      children: [
        TextButton(
          onPressed: (_canResend && !_isVerifying) ? _handleResend : null,
          style: TextButton.styleFrom(
            foregroundColor: _canResend ? primaryGold : textGrey,
          ),
          child: Text(
            _canResend
                ? 'Renvoyer le code'
                : 'Renvoyer le code (${_resendTimer}s)',
            style: TextStyle(
              color: _canResend ? primaryGold : textGrey,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
