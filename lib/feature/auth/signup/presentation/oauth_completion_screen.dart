import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/presentation/responsive_scroll_body.dart';
import '../../../../core/shared/constants/merchant_colors.dart';
import '../../../../types.dart';
import '../../core/application/oauth_identity_helpers.dart';
import '../application/oauth_signup_controller.dart';
import '../application/providers.dart';
import '../application/state/oauth_signup_state.dart';
import 'constants/signup_constants.dart';
import 'utils/phone_formatter.dart';
import 'widgets/country_code_modal.dart';
import 'widgets/phone_number_formatter.dart';

part 'oauth_completion_screen.part.dart';

/// Page-level UI for the "almost there" step of the Google / Apple signup
/// flow. Shown by the shell when [oauthSignupControllerProvider] enters
/// [OAuthSignupNeedsCompletion].
///
/// Replaces the previous `AlertDialog` pattern in
/// `signup_screen.part.dart` (`_promptPhoneForOAuthCompletion`). The
/// dialog had three problems that produced the "first time, nothing
/// happens" symptom users were reporting:
///   1. Annuler / barrier-dismiss returned `null`, which silently called
///      [SignOut] — the user landed back on the signup screen with no
///      feedback.
///   2. Snackbars surfaced under the keyboard on Android.
///   3. There was no UX affordance for typing first/last name when Apple
///      did not return them on a non-first authorization.
///
/// This screen fixes all three: it stays mounted across retries (the
/// OAuth Firebase session is preserved), errors are inline banners (not
/// snackbars), and a `firstName` / `lastName` block is shown when the
/// controller reports `needsName == true`.
class OAuthCompletionScreen extends ConsumerStatefulWidget {
  const OAuthCompletionScreen({
    super.key,
    required this.role,
    required this.onCancelled,
    required this.onCompleted,
  });

  final UserRole role;

  /// Called after [OAuthSignupController.cancelCompletion] resolves so
  /// the shell can swap back to the signup screen.
  final VoidCallback onCancelled;

  /// Called after [OAuthSignupController] reaches
  /// [OAuthSignupCompleted]; the shell will then route to home /
  /// onboarding via the auth state stream.
  final VoidCallback onCompleted;

  @override
  ConsumerState<OAuthCompletionScreen> createState() =>
      _OAuthCompletionScreenState();
}

class _OAuthCompletionScreenState extends ConsumerState<OAuthCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _phoneFocus = FocusNode();

  String _selectedCountryCode = '+33';
  String? _firstNameError;
  String? _lastNameError;
  String? _phoneError;
  bool _didPrefill = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  /// Wrapper around [setState] that no-ops when the widget is not mounted.
  /// Extensions on State cannot call [setState] directly (it is a public API
  /// constrained to subclasses), so the part-file UI extension routes
  /// through this method instead.
  void uiSetState(VoidCallback fn) {
    if (!mounted) return;
    // ignore: invalid_use_of_protected_member
    setState(fn);
  }

  @override
  Widget build(BuildContext context) => _buildScaffold(context);
}
