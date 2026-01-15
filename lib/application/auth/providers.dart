import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/auth/entities/auth_user.dart';
import '../../domain/core/result.dart';
import '../auth/auth_controller.dart';
import '../auth/state/auth_state.dart';
import '../auth/use_cases/sign_in_with_email_password.dart';
import '../auth/use_cases/sign_out.dart';
import '../auth/use_cases/watch_auth_state.dart';
import '../../infrastructure/auth/auth_repository_provider.dart';

final signInWithEmailPasswordProvider =
    Provider<SignInWithEmailPassword>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInWithEmailPassword(repository);
});

final signOutProvider = Provider<SignOut>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignOut(repository);
});

final watchAuthStateProvider = Provider<WatchAuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return WatchAuthState(repository);
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    signInWithEmailPassword: ref.watch(signInWithEmailPasswordProvider),
    signOut: ref.watch(signOutProvider),
    watchAuthState: ref.watch(watchAuthStateProvider),
  );
});

/// Exposes auth state as a convenience for UI widgets.
final authStateProvider =
    Provider<AuthState>((ref) => ref.watch(authControllerProvider));

/// Exposes raw auth stream results (useful for listeners).
final authResultStreamProvider = StreamProvider<Result<AuthUser?>>((ref) {
  return ref.watch(watchAuthStateProvider)();
});
