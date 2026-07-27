import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../application/providers.dart';
import '../application/create_user_document.dart';
import '../../core/application/auth_error_mapper.dart';
import '../../core/application/providers.dart' as auth_core;
import '../../core/domain/auth_failure.dart';
import '../../core/application/auth_controller.dart';
import '../../core/application/state/auth_state.dart';
import '../../core/application/use_cases/sign_out.dart';
import '../../core/domain/repositories/auth_repository.dart';
import '../../../../core/shared/widgets/snackbar.dart';
import '../../../../types.dart';
import '../domain/signup_roles_map.dart';
import '../../../../core/presentation/responsive_scroll_body.dart';
import '../../../../core/shared/constants/merchant_colors.dart';
import 'constants/signup_constants.dart';
import 'utils/phone_formatter.dart';

part 'otp_screen.part.dart';
part 'otp_screen_flow.part.dart';

class OTPScreen extends ConsumerStatefulWidget {
  const OTPScreen({
    super.key,
    this.onBack,
    this.onSignupComplete,
    required this.userId,
    required this.phone,
    required this.onResend,
    required this.email,
    required this.password,
    required this.role,
    this.otpUnavailableMessage,
    this.verificationId,
  });

  /// Optional external back handler (used when OTP is shown via RootShell state,
  /// where there may be no Navigator stack to pop).
  final VoidCallback? onBack;

  /// Called after Firestore profile creation so the shell can route to
  /// onboarding / home (auth stream may not re-emit for the same uid).
  final VoidCallback? onSignupComplete;
  final String userId;
  final String phone;
  final VoidCallback onResend;
  final String email;
  final String password;
  final UserRole role;
  final String? otpUnavailableMessage;
  final String? verificationId;

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

  /// True once the OTP code was accepted and the account is being finalized
  /// (Firestore profile write + auth reload). The UI swaps to a full-screen
  /// loading view so the user isn't left staring at frozen OTP fields.
  bool _isFinalizing = false;
  bool _otpBlocked = false;
  String? _otpUnavailableMessage;
  Timer? _timer;

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
    if (_isVerifying || _isFinalizing) return;
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

  void _setVerifying(bool value) {
    setState(() => _isVerifying = value);
  }

  void _setFinalizing(bool value) {
    if (!mounted) return;
    setState(() => _isFinalizing = value);
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
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
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
      _applyPastedCode(startIndex: index, digits: digitsOnly.substring(0, digitsOnly.length.clamp(0, 6)));
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
    // Take only the remaining slots and up to digits.length characters.
    final remaining = (6 - startIndex).clamp(0, 6);
    final take = remaining.clamp(0, digits.length);
    final chars = digits.substring(0, take).split('');

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

  @override
  Widget build(BuildContext context) => _buildOtpScreen(context);
}
