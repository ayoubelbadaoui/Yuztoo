import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/providers.dart';
import '../../core/application/auth_error_mapper.dart';
import '../../core/application/state/auth_state.dart';
import '../../login/application/providers.dart';
import '../../../../core/shared/widgets/snackbar.dart';
import '../../../../types.dart';

class OTPScreen extends ConsumerStatefulWidget {
  const OTPScreen({
    super.key,
    required this.onBack,
    required this.onVerify,
    required this.phone,
    required this.onResend,
    required this.email,
    required this.city,
    required this.role,
    this.verificationId,
  });

  final VoidCallback onBack;
  final VoidCallback onVerify;
  final String phone;
  final VoidCallback onResend;
  final String email;
  final String city;
  final UserRole role;
  final String? verificationId; // Optional, for resend functionality

  @override
  ConsumerState<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends ConsumerState<OTPScreen> {
  static const String _autoVerificationId = '__auto__';
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  
  int _resendTimer = 60; // 60 seconds
  bool _canResend = false;
  bool _isVerifying = false;
  Timer? _timer;

  // Colors - Match signup screen dark theme
  static const Color bgDark1 = Color(0xFF0F1A29);
  static const Color bgDark2 = Color(0xFF111A2A);
  static const Color primaryGold = Color(0xFFD4A017);
  static const Color textLight = Color(0xFFF5F5F5);
  static const Color textGrey = Color(0xFFB0B0B0);
  static const Color borderColor = Color(0xFF2A3F5F);

  @override
  void initState() {
    super.initState();
    if (widget.verificationId == _autoVerificationId) {
      // Auto-verification completed; create profile directly
      setState(() => _isVerifying = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _createFirestoreProfile();
      });
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
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
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

    final verifyPhoneUseCase = ref.read(verifyAndLinkPhoneProvider);
    final verifyResult = await verifyPhoneUseCase.call(
      verificationId: widget.verificationId!,
      smsCode: smsCode,
    );

    verifyResult.fold(
      (failure) {
        if (mounted) {
          final frenchMessage = AuthErrorMapper.getFrenchMessage(failure);
          showErrorSnackbar(context, frenchMessage);
          // Clear OTP fields on error so user can retry
          for (final controller in _controllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
          setState(() => _isVerifying = false);
        }
      },
      (_) async {
        // Phone linked successfully - now create Firestore profile
        if (mounted) {
          await _createFirestoreProfile();
        }
      },
    );
  }

  Future<void> _createFirestoreProfile() async {
    // Get current authenticated user from auth state
    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) {
      if (mounted) {
        showErrorSnackbar(context, 'Erreur: Aucun utilisateur connecté');
        setState(() => _isVerifying = false);
      }
      return;
    }

    final user = authState.user;

    // Build roles map based on widget.role
    final Map<String, bool> roles = {
      'client': widget.role == UserRole.client,
      'merchant': widget.role == UserRole.merchant,
      'provider': false, // Not used in signup flow
    };

    final createUserDocUseCase = ref.read(createUserDocumentProvider);
    final createResult = await createUserDocUseCase.call(
      uid: user.id,
      email: widget.email,
      phone: widget.phone,
      roles: roles,
      city: widget.city,
    );

    createResult.fold(
      (failure) {
        if (mounted) {
          final frenchMessage = AuthErrorMapper.getFrenchMessage(failure);
          showErrorSnackbar(context, frenchMessage);
          setState(() => _isVerifying = false);
          // Don't navigate on error - user can retry or go back
        }
      },
      (_) {
        // Firestore profile created successfully
        if (mounted) {
          showSuccessSnackbar(context, 'Inscription réussie!');
          // Navigate to home (via onVerify callback)
          widget.onVerify();
        }
      },
    );
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;

    final sendOtpUseCase = ref.read(sendPhoneVerificationProvider);
    final otpResult = await sendOtpUseCase.call(phoneNumber: widget.phone);

    otpResult.fold(
      (failure) {
        if (mounted) {
          final frenchMessage = AuthErrorMapper.getFrenchMessage(failure);
          showErrorSnackbar(context, frenchMessage);
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
    return PopScope(
      canPop: !_isVerifying, // Prevent back navigation during verification
      onPopInvoked: (didPop) {
        if (!didPop && !_isVerifying) {
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
              _buildOTPFields(),
              const SizedBox(height: 24),
              _buildResendButton(),
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
          'Vérification',
          style: TextStyle(
            fontSize: 18,
            color: textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Entrez le code envoyé au\n${widget.phone}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: textGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildOTPFields() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
        return SizedBox(
          width: 48,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            enabled: !_isVerifying,
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
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
