import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/application/providers.dart';
import '../../core/application/state/auth_state.dart';
import 'sign_in_with_email_password.dart';
import 'sign_in_with_social.dart';
import 'send_password_reset_email.dart';
import 'login_controller.dart';
import 'login_flow_controller.dart';
import 'forgot_password_controller.dart';
import 'state/login_flow_state.dart';
import 'state/forgot_password_state.dart';

final signInWithEmailPasswordProvider =
    Provider<SignInWithEmailPassword>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInWithEmailPassword(repository);
});

final signInWithGoogleProvider = Provider<SignInWithGoogle>((ref) {
  return SignInWithGoogle(ref.watch(authRepositoryProvider));
});

final signInWithAppleProvider = Provider<SignInWithApple>((ref) {
  return SignInWithApple(ref.watch(authRepositoryProvider));
});

/// Login-specific controller that extends the core AuthController
/// Provides sign-in functionality in addition to core auth state management
final loginControllerProvider =
    StateNotifierProvider<LoginController, AuthState>((ref) {
  return LoginController(
    signInWithEmailPassword: ref.watch(signInWithEmailPasswordProvider),
    signOut: ref.watch(signOutProvider),
    watchAuthState: ref.watch(watchAuthStateProvider),
    reloadCurrentUserProfile: ref.watch(reloadCurrentUserProfileProvider),
  );
});

final loginFlowControllerProvider =
    StateNotifierProvider<LoginFlowController, LoginFlowState>((ref) {
  return LoginFlowController(ref);
});

final sendPasswordResetEmailProvider =
    Provider<SendPasswordResetEmail>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SendPasswordResetEmail(repository);
});

final forgotPasswordControllerProvider =
    StateNotifierProvider<ForgotPasswordController, ForgotPasswordState>((ref) {
  return ForgotPasswordController(ref);
});

