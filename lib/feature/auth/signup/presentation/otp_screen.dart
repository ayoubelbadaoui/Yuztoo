import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/providers.dart';
import '../../core/application/auth_error_mapper.dart';
import '../../core/application/providers.dart' as auth_core;
import '../../../../core/shared/widgets/snackbar.dart';
import '../../../../core/shared/widgets/app_logo.dart';
import '../../../../types.dart';
import 'utils/phone_formatter.dart';

class OTPScreen extends ConsumerStatefulWidget {
  const OTPScreen({
    super.key,
    this.onBack,
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

  /// Optional external back handler (used when OTP is shown via RootShell state,
  /// where there may be no Navigator stack to pop).
  final VoidCallback? onBack;
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
  final List<String> _lastValues = List.filled(6, '');

  bool _isProgrammaticOtpUpdate = false;
  
  int _resendTimer = 60; // 60 seconds
  bool _canResend = false;
  bool _isVerifying = false;
  bool _otpBlocked = false;
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

    // Persist role as a fallback when Firestore is unavailable.
    // This helps ensure merchant users don't get routed as client.
    Future.microtask(() {
      ref.read(auth_core.roleCacheServiceProvider).saveLastSelectedRole(widget.role);
    });

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

  void _handleBack() {
    if (_isVerifying) return;
    // Prefer popping this route if it exists.
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    // Fallback to external handler if we cannot pop.
    widget.onBack?.call();
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

  void _setOtpAt(int index, String value) {
    // Prevent recursive onChanged when we set controller values programmatically.
    _isProgrammaticOtpUpdate = true;
    _controllers[index].value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _lastValues[index] = value;
    _isProgrammaticOtpUpdate = false;
  }

  void _onChanged(int index, String value) {
    if (_otpBlocked || _isVerifying) return;
    if (_isProgrammaticOtpUpdate) return;
    
    // Keep only digits (handles keyboards that insert spaces/dashes).
    final digitsOnly = value.replaceAll(RegExp(r'\\D'), '');
    
    // Empty -> possibly backspace.
    if (digitsOnly.isEmpty) {
      final prev = _lastValues[index];
      _lastValues[index] = '';

      // Heuristic: if field was already empty and user hits backspace again,
      // move to previous field and clear it (classic OTP UX).
      if (prev.isEmpty && index > 0) {
        _setOtpAt(index - 1, '');
        _focusNodes[index - 1].requestFocus();
      }
      return;
    }

    // Paste/autofill into a single box (or user pasted multiple digits).
    if (digitsOnly.length > 1) {
      _applyPastedCode(startIndex: index, digits: digitsOnly);
      return;
    }

    // Single digit
    if (_controllers[index].text != digitsOnly) {
      _setOtpAt(index, digitsOnly);
    } else {
      _lastValues[index] = digitsOnly;
    }

    if (index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }

    // Check if all 6 digits are filled and verify
    final code = _controllers.map((c) => c.text).join();
    if (code.length == 6 && !_isVerifying) {
      // Small delay to ensure UI updates before verification
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_isVerifying) {
          _verifyOTP(code);
        }
      });
    }
  }

  void _applyPastedCode({required int startIndex, required String digits}) {
    // Take only the remaining digits and distribute starting from startIndex.
    final remaining = (6 - startIndex).clamp(0, 6);
    final chars = digits.substring(0, remaining).split('');

    var writeIndex = startIndex;
    _isProgrammaticOtpUpdate = true;
    for (final ch in chars) {
      if (writeIndex > 5) break;
      _controllers[writeIndex].value = TextEditingValue(
        text: ch,
        selection: const TextSelection.collapsed(offset: 1),
      );
      _lastValues[writeIndex] = ch;
      writeIndex++;
    }
    _isProgrammaticOtpUpdate = false;

    // Focus the next empty field or unfocus if all filled.
    if (mounted && !_isVerifying) {
      if (writeIndex <= 5) {
        _focusNodes[writeIndex].requestFocus();
      } else {
        _focusNodes[5].unfocus();
      }
    }

    // Check if all 6 digits are filled and verify
    final code = _controllers.map((c) => c.text).join();
    if (code.length == 6 && !_isVerifying) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_isVerifying) {
          _verifyOTP(code);
        }
      });
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
        // Verify the write by reading it back once to ensure eventual consistency
        // This is the proper way to handle Firestore's eventual consistency
        if (mounted) {
          final getUserRole = ref.read(auth_core.getUserRoleProvider);
          UserRole? verifiedRole;
          
          // Try to read the role once to verify the write (with one retry)
          // This handles Firestore's eventual consistency properly
          for (int attempt = 0; attempt < 2 && verifiedRole == null; attempt++) {
            if (attempt > 0) {
              await Future.delayed(const Duration(milliseconds: 200));
            }
            
            try {
              final roleResult = await getUserRole.call(userId).timeout(
                const Duration(seconds: 3),
              );
              
              verifiedRole = roleResult.fold(
                (_) => null,
                (r) => r,
              );
              
              // If we got the role, break early
              if (verifiedRole != null) break;
            } catch (_) {
              // Timeout or error - will retry if attempts remain
              continue;
            }
          }
          
          if (mounted) {
            showSuccessSnackbar(context, 'Inscription réussie!');
            // Navigation will be driven by auth state changes (AuthController + navigation provider)
            // The retry logic in main.dart will handle any remaining eventual consistency issues
            // Just pop OTP screen; auth stream will emit Authenticated and RootShell will navigate.
            Navigator.of(context).pop();
          }
        }
      },
    );
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
      value: const SystemUiOverlayStyle(
        statusBarColor: bgDark1, // Same color as background
        statusBarIconBrightness: Brightness.light, // Light icons for dark background
        statusBarBrightness: Brightness.dark, // For iOS
        systemNavigationBarColor: bgDark1, // Same color as background
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: false, // Use our custom navigation instead of route popping
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !_isVerifying) {
            // Handle Android back button
            _handleBack();
          }
        },
        child: Scaffold(
          backgroundColor: bgDark1,
        body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: _handleBack,
                  icon: const Icon(Icons.arrow_back),
                  color: const Color(0xFFBF8719),
                  iconSize: 24,
                ),
              ),
              _buildLogoSection(),
              const SizedBox(height: 32), // 8pt grid: section break
              _buildOTPFields(),
              const SizedBox(height: 40), // 8pt grid: larger gap after OTP
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
    // International standard: OTP/verification screens use 10-14% of screen height
    // Examples: WhatsApp (12%), Telegram (11%), Signal (13%)
    final screenH = MediaQuery.of(context).size.height;
    final logoSize = (screenH * 0.16).clamp(110.0, 160.0);

    return Column(
      children: [
        AppLogo(
          size: logoSize,
          fallback: Icon(
            Icons.location_on,
            color: primaryGold,
            size: logoSize * 0.4,
          ),
        ),
        const SizedBox(height: 24), // 8pt grid: logo → title
        const Text(
          'Vérification',
          style: TextStyle(
            fontSize: 18,
            color: textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8), // 8pt grid: title → subtitle
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
        const SizedBox(height: 16),
        TextButton(
          onPressed: _isVerifying
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  _handleBack();
                },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            minimumSize: const Size(180, 40),
            foregroundColor: primaryGold,
          ),
          child: Text(
            'Numéro incorrect ?',
            style: TextStyle(
              fontSize: 13,
              color: _isVerifying ? textGrey.withValues(alpha: 0.6) : primaryGold,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor:
                  _isVerifying ? textGrey.withValues(alpha: 0.6) : primaryGold,
            ),
          ),
        ),
        if (_otpUnavailableMessage != null && _otpUnavailableMessage!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: errorRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: errorRed.withValues(alpha: 0.3), width: 1),
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
        LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            const maxBox = 54.0;
            const minBox = 36.0; // allow smaller to avoid overflow on small devices
            var gap = 10.0;

            // Start with an ideal size, then shrink gap/box as needed to always fit.
            var boxW = (maxW - gap * 5) / 6;
            if (boxW > maxBox) boxW = maxBox;

            if (boxW < minBox) {
              boxW = minBox;
              gap = ((maxW - boxW * 6) / 5).clamp(4.0, 10.0);
              // If still doesn't fit (very narrow screens), shrink box to fit with min gap.
              const minGap = 4.0;
              if (boxW * 6 + minGap * 5 > maxW) {
                boxW = ((maxW - minGap * 5) / 6).clamp(28.0, minBox);
                gap = minGap;
              }
            }

            const height = 62.0;

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(6, (index) {
                return Padding(
                  padding: EdgeInsets.only(right: index == 5 ? 0 : gap),
                  child: SizedBox(
                    width: boxW,
                    height: height,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      enabled: !_isVerifying && !_otpBlocked,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      textInputAction:
                          index == 5 ? TextInputAction.done : TextInputAction.next,
                      cursorColor: primaryGold,
                      style: const TextStyle(
                        color: textLight,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      autofillHints:
                          index == 0 ? const [AutofillHints.oneTimeCode] : null,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) => _onChanged(index, value),
                      onTap: () {
                        // Select all text when tapping for easy replacement
                        final t = _controllers[index].text;
                        if (t.isNotEmpty) {
                          _controllers[index].selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: t.length,
                          );
                        }
                      },
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: bgDark2,
                        contentPadding: const EdgeInsets.symmetric(vertical: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: borderColor, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: borderColor, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: primaryGold,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
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
