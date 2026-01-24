import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/application/state/auth_state.dart';
import '../../core/application/providers.dart';
import '../../core/infrastructure/auth_repository_provider.dart';
import 'sign_in_with_email_password.dart';
import 'login_controller.dart';

final signInWithEmailPasswordProvider =
    Provider<SignInWithEmailPassword>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInWithEmailPassword(repository);
});

final authControllerProvider =
    StateNotifierProvider<LoginController, AuthState>((ref) {
  return LoginController(
    signInWithEmailPassword: ref.watch(signInWithEmailPasswordProvider),
    signOut: ref.watch(signOutProvider),
    watchAuthState: ref.watch(watchAuthStateProvider),
  );
});

/// Exposes auth state as a convenience for UI widgets.
final authStateProvider =
    Provider<AuthState>((ref) => ref.watch(authControllerProvider));

